"""Manual transfer script for space payment.

- Will transfer 1 LAD every epoch for 10000 epochs

"""
import time
import sys
import os
import json

from web3 import HTTPProvider, Web3
from web3.middleware import geth_poa_middleware

from dotenv import load_dotenv

load_dotenv()

print('''

888       888          888                                              888                 8888888888 8888888888 888     888 888b     d888 
888   o   888          888                                              888                 888        888        888     888 8888b   d8888 
888  d8b  888          888                                              888                 888        888        888     888 88888b.d88888 
888 d888b 888  .d88b.  888  .d8888b .d88b.  88888b.d88b.   .d88b.       888888 .d88b.       8888888    8888888    Y88b   d88P 888Y88888P888 
888d88888b888 d8P  Y8b 888 d88P"   d88""88b 888 "888 "88b d8P  Y8b      888   d88""88b      888        888         Y88b d88P  888 Y888P 888 
88888P Y88888 88888888 888 888     888  888 888  888  888 88888888      888   888  888      888        888          Y88o88P   888  Y8P  888 
8888P   Y8888 Y8b.     888 Y88b.   Y88..88P 888  888  888 Y8b.          Y88b. Y88..88P      888        888           Y888P    888   "   888 
888P     Y888  "Y8888  888  "Y8888P "Y88P"  888  888  888  "Y8888        "Y888 "Y88P"       888        8888888888     Y8P     888       888 
                                                                                                                                                                                                                                                                                                                                                                                                                         
''')

rpc_endpoint = "https://rpc.ankr.com/filecoin_testnet"
assert rpc_endpoint is not None, "You must set rpc_endpoint in .env file"
web3 = Web3(HTTPProvider(rpc_endpoint))
web3.middleware_onion.inject(geth_poa_middleware, layer=0)
block_number = web3.eth.block_number
print(f"Connected to {rpc_endpoint}, chain id is {web3.eth.chain_id}. the latest block is {block_number:,}\n")

# epoch_time = 15

space_contract_address = "0x82D937426F43e99DA6811F167eCFB0103cd07E6B"
space_abi_file = open('../contracts/abi/SpacePayment.json')
space_abi = json.load(space_abi_file)

token_contract_address = "0xCdB765D539637a4A6B434ea43C27eE0C05804B33"
token_abi_file = open('../contracts/abi/LagrangeDAOToken.json')
token_abi = json.load(token_abi_file)

wallet_address = "0xc17ae0520803E715D020C03D29D452520D6aEbf9"
private_key = "5c412d5f09c85ab2271cb5712dee9f87384321c6a87b750092502ba68cadc1d0"

assert web3.isChecksumAddress(wallet_address), f"Not a valid wallet address: {wallet_address}"
assert web3.isChecksumAddress(space_contract_address), f"Not a valid contract address: {space_contract_address}"
assert web3.isChecksumAddress(token_contract_address), f"Not a valid contract address: {space_contract_address}"

tx_config = {
    'from': wallet_address,
    'maxFeePerGas': web3.toWei('250', 'gwei'),
    'maxPriorityFeePerGas': web3.toWei('5', 'gwei'),
}

# Show users the current status of token and his address
space_contract = web3.eth.contract(address=space_contract_address, abi=space_abi)
token_contract = web3.eth.contract(address=token_contract_address, abi=token_abi)
token_name, token_symbol = token_contract.functions.name().call(), token_contract.functions.symbol().call()
token_decimals = token_contract.functions.decimals().call()
token_balance = token_contract.functions.balanceOf(wallet_address).call()
fil_balance = web3.eth.getBalance(wallet_address)

user_balance = space_contract.functions.balanceOf(wallet_address).call()
lad_allowance = token_contract.functions.allowance(wallet_address, space_contract_address).call()

print(f"Your payment wallet address: {wallet_address}")
print(f"Your Account balance: {fil_balance / (10 ** token_decimals):f} tFIL")
print(f"Your Account balance: {token_balance / (10 ** token_decimals):f} {token_symbol}\n")
# print(f"epoch time: 1 block per {epoch_time} seconds\n")

hardware_type = input(" 0. CPU Only - 2 vCPU - 16 GiB - Free \
    \n 1. CPU Only - 8 vCPU - 32 GiB - 1 LAD per block \
    \n 2. Nvidia T4 - 4 vCPU - 15 GiB - 20 LAD per block \
    \n 3. Nvidia T4 - 8 vCPU - 30 GiB - 30 LAD per block \
    \n 4. Nvidia A10G - 4 vCPU - 15 GiB - 35 LAD per block \
    \n 5. Nvidia A10G - 12 vCPU - 46 GiB - 105 LAD per block \
    \n\nSelect the hardware (#): ")

# hours = input("How many hours: ")
# blocks = float(hours) * 60 * 60 / epoch_time

blocks = input("How many blocks: ")

prices = [0, 1, 20, 30, 35, 105]
price = prices[int(hardware_type)] * int(blocks)
price_in_wei = int(price) * 10 ** token_decimals

# Fat-fingering check
print(f"Confirm purchasing hardware type {hardware_type} for {blocks} blocks ({price} {token_symbol})?")
confirm = input("Ok [y/n]?")
if not confirm.lower().startswith("y"):
    print("Aborted")
    sys.exit(1)

if token_balance < price_in_wei:
    print("\nNot enough LAD tokens")
    sys.exit(1)

if user_balance < price_in_wei and int(hardware_type) != 0: # user needs to deposit LAD into contract
    if lad_allowance < price_in_wei: # user needs to approve spending LAD
        nonce = web3.eth.getTransactionCount(wallet_address)
        tx_config["nonce"] = nonce
        approve_tx = token_contract.functions.approve(space_contract_address,
                                                    price_in_wei).buildTransaction(tx_config)

        # SIGN TX
        signed_tx = web3.eth.account.signTransaction(approve_tx, private_key)
        tx_hash = web3.eth.sendRawTransaction(signed_tx.rawTransaction)
        web3.eth.wait_for_transaction_receipt(tx_hash)
        hash = web3.toHex(tx_hash)

    print(f"\nDepositing {price} {token_symbol} into contract...")
    nonce = web3.eth.getTransactionCount(wallet_address)
    tx_config["nonce"] = nonce
    deposit_tx = space_contract.functions.deposit(price_in_wei).buildTransaction(tx_config)

    # SIGN TX
    signed_tx = web3.eth.account.signTransaction(deposit_tx, private_key)
    tx_hash = web3.eth.sendRawTransaction(signed_tx.rawTransaction)
    web3.eth.wait_for_transaction_receipt(tx_hash)
    hash = web3.toHex(tx_hash)

    print(f"Deposit is completed. Tx Hash: https://hyperspace.filfox.info/en/message/{hash}")

nonce = web3.eth.getTransactionCount(wallet_address)
tx_config["nonce"] = nonce
approve_tx = token_contract.functions.approve(space_contract_address,
                                                    price_in_wei).buildTransaction(tx_config)

# SIGN TX
signed_tx = web3.eth.account.signTransaction(approve_tx, private_key)
tx_hash = web3.eth.sendRawTransaction(signed_tx.rawTransaction)
web3.eth.wait_for_transaction_receipt(tx_hash)
hash = web3.toHex(tx_hash)

print(f"\nDepositing {price} {token_symbol} into contract...")
nonce = web3.eth.getTransactionCount(wallet_address)
tx_config["nonce"] = nonce
deposit_tx = space_contract.functions.deposit(price_in_wei).buildTransaction(tx_config)

# SIGN TX
signed_tx = web3.eth.account.signTransaction(deposit_tx, private_key)
tx_hash = web3.eth.sendRawTransaction(signed_tx.rawTransaction)
web3.eth.wait_for_transaction_receipt(tx_hash)
hash = web3.toHex(tx_hash)

print(f"Deposit is completed. Tx Hash: https://hyperspace.filfox.info/en/message/{hash}")

print(f"\npurchasing space...")
nonce = web3.eth.getTransactionCount(wallet_address)
tx_config["nonce"] = nonce
tx = space_contract.functions.buySpace(int(hardware_type), int(blocks)).buildTransaction(tx_config)

# SIGN TX
signed_tx = web3.eth.account.signTransaction(tx, private_key)
tx_hash = web3.eth.sendRawTransaction(signed_tx.rawTransaction)
web3.eth.wait_for_transaction_receipt(tx_hash)
hash = web3.toHex(tx_hash)

print(f"Purchasing Success. Tx Hash: https://hyperspace.filfox.info/en/message/{hash}")

# extend_space
print(f"Extending space")
nonce = web3.eth.getTransactionCount(wallet_address)
tx_config["nonce"] = nonce
extendSpace_tx = space_contract.functions.extendSpace(1,10).buildTransaction(tx_config)

# SIGN TX
signed_tx = web3.eth.account.signTransaction(extendSpace_tx, private_key)
tx_hash = web3.eth.sendRawTransaction(signed_tx.rawTransaction)
web3.eth.wait_for_transaction_receipt(tx_hash)
hash = web3.toHex(tx_hash)
print(f"transaction hash: {hash}")
