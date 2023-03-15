"""

- Mint NFT on FEVM

"""
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

rpc_endpoint = os.getenv("rpc_endpoint")
assert rpc_endpoint is not None, "You must set rpc_endpoint in .env file"
web3 = Web3(HTTPProvider(rpc_endpoint))
web3.middleware_onion.inject(geth_poa_middleware, layer=0)
block_number = web3.eth.block_number
print(f"Connected to {rpc_endpoint}, chain id is {web3.eth.chain_id}. the latest block is {block_number:,}\n")

dnft_address = "0x9DAD51914291919F8D4DD77442E9FDd742c22eA0"
dnft_abi_file = open('../contracts/abi/DataNFT.json')
dnft_abi = json.load(dnft_abi_file)

wallet_address = os.getenv('wallet_address')
private_key = os.getenv('private_key')

print(f"Your address: {wallet_address}\n")

assert web3.isChecksumAddress(wallet_address), f"Not a valid wallet address: {wallet_address}"
assert web3.isChecksumAddress(dnft_address), f"Not a valid contract address: {space_contract_address}"

dnft_contract = web3.eth.contract(address=dnft_address, abi=dnft_abi)

tx_config = {
    'from': wallet_address,
    'maxFeePerGas': web3.toWei('250', 'gwei'),
    'maxPriorityFeePerGas': web3.toWei('5', 'gwei'),
}

## SHOULD BE METADATA URL
ipfs_url = input("NFT Metadata (IPFS URL): ")
recipient = input("Send to (address): ")
quantity = input("Quantity (int): ")

# # Fat-fingering check
print(f"\nConfirm minting {quantity} NFT(s) of {ipfs_url} to {recipient}?")
confirm = input("Ok [y/n]?")
if not confirm.lower().startswith("y"):
    print("Aborted")
    sys.exit(1)

print(f"\nMinting...")
nonce = web3.eth.getTransactionCount(wallet_address)
tx_config["nonce"] = nonce
mint_tx = dnft_contract.functions.mint(recipient, int(quantity), ipfs_url, "").buildTransaction(tx_config)

# SIGN TX
signed_tx = web3.eth.account.signTransaction(mint_tx, private_key)
tx_hash = web3.eth.sendRawTransaction(signed_tx.rawTransaction)
web3.eth.wait_for_transaction_receipt(tx_hash)
hash = web3.toHex(tx_hash)

print(f"Mint is completed. Tx Hash: https://hyperspace.filfox.info/en/message/{hash}")