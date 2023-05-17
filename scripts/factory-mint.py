import os
import json
import sys
import warnings
import time

from decouple import config
from web3 import HTTPProvider, Web3
from web3.middleware import geth_poa_middleware

from dotenv import load_dotenv
load_dotenv()

# silence harmless warnings
warnings.filterwarnings("ignore")

rpc_endpoint = config("rpc_endpoint")
assert rpc_endpoint is not None, "You must set rpc_endpoint in .env file"
web3 = Web3(HTTPProvider(rpc_endpoint))
web3.middleware_onion.inject(geth_poa_middleware, layer=0)
block_number = web3.eth.block_number
print(f"Connected to {rpc_endpoint}, chain id is {web3.eth.chain_id}. the latest block is {block_number:,}\n")

factory_contract_address = '0x26FE0adD600965518c06c25CCff182115917C34A'
factory_contract_abi_file = open('../contracts/abi/DataNFTFactory.json')
factory_contract_abi = json.load(factory_contract_abi_file)

wallet_address = config('wallet_address')
private_key = config('private_key')

print(f"Your address: {wallet_address}\n")

# Get the balance
wallet_balance_wei = web3.eth.get_balance(wallet_address)

assert web3.isChecksumAddress(wallet_address), f"Not a valid wallet address: {wallet_address}"
assert web3.isChecksumAddress(factory_contract_address), f"Not a valid contract address: {factory_contract_address}"

# smart contract instance
factory_contract = web3.eth.contract(address=factory_contract_address, abi=factory_contract_abi)

# example: 'https://3b46ed854.acl.multichain.storage/ipfs/QmfWumvNSWTTXS6QTkmsEunDtUqGTwFyGNDp8bMCxxUK6y'
nft_uri = input("Enter IPFS URI: ")

tx_config = {
    'from': wallet_address,
    'gas': 4000000,
    'maxFeePerGas': web3.to_wei('5', 'gwei'),
    'maxPriorityFeePerGas': web3.to_wei('1', 'gwei'),
}
nonce = web3.eth.get_transaction_count(wallet_address)
tx_config["nonce"] = nonce

# Calculate the maximum cost
max_tx_cost_wei = tx_config['gas'] * (tx_config['maxFeePerGas'] + tx_config['maxPriorityFeePerGas'])

# CHeck if wallet has enough balance to complete all transactions:
if wallet_balance_wei < max_tx_cost_wei * 2:
    print(f"wallet does not have enough balance to execute the transaction")
    print(f"wallet balance: {wallet_balance_wei} , transaction cost: {max_tx_cost_wei * 2}")

# Build Tx with chainId, wallet address, nonce
request_dataNFT_tx = factory_contract.functions.requestDataNFT(nft_uri).build_transaction(tx_config)

# SIGN TX
signed_tx = web3.eth.account.sign_transaction(request_dataNFT_tx, private_key)
tx_hash = web3.eth.send_raw_transaction(signed_tx.rawTransaction)
tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
hash = web3.to_hex(tx_hash)
# print("hash: ",hash)

# Get the `Topics` field to retrieve `requestID`
txInputReceipt = web3.eth.get_transaction_receipt(tx_hash)
TxLogs = txInputReceipt.logs
request_id = TxLogs[0].topics[1].hex()
print("request_id: ",request_id)

# Wait for the oracle to complete the request
print("Please wait while the oracle fulfills the request..\n")
time.sleep(60)

# Call the `requestData` mapping to check if the request was fulfilled
try:
    request_data_tx = factory_contract.functions.requestData(request_id).call()
except Exception as e:
    print(f"Error occurred during the request data transaction: {e}")

# Store the result of `requestData` in the respective variables
tx_owner = request_data_tx[0]
tx_uri = request_data_tx[1]
tx_fulfilled = request_data_tx[4]
tx_claimable = request_data_tx[5]

# Sanity checks:
# Check if the correct owner is the one calling the method
assert tx_owner == wallet_address

# Check if tx_claimable was set to true
if tx_claimable:
    print("NFT is claimable")
else:
    print("NFT is not claimable")

# Check if tx_claimable was set to true
if tx_fulfilled:
    print("Chainlink oracle fulfilled the request\n")
else:
    print("Request not fulfilled")

# Update the nonce in tx_config before deploying the new data NFT contract:
nonce2 = web3.eth.get_transaction_count(wallet_address)
tx_config["nonce"] = nonce2

create_dataNFT_tx = factory_contract.functions.claimDataNFT(request_id).build_transaction(tx_config)

print(f"Deploying new NFT contract...\n")
# SIGN TX for createDataNFT
createDataNFT_signed_tx = web3.eth.account.sign_transaction(create_dataNFT_tx, private_key)
createDataNFT_tx_hash = web3.eth.send_raw_transaction(createDataNFT_signed_tx.rawTransaction)
createDataNFT_tx_receipt = web3.eth.wait_for_transaction_receipt(createDataNFT_tx_hash)
createDataNFT_hash = web3.to_hex(createDataNFT_tx_hash)
# print("createDataNFT_hash: ",createDataNFT_hash)

create_dataNFT_Txlogs = createDataNFT_tx_receipt['logs']
deployed_contract_address = create_dataNFT_Txlogs[0]["address"]
print(f"Data NFT contract deployed at: {deployed_contract_address}")
print(f"view it on Etherscan: https://sepolia.etherscan.io/address/{deployed_contract_address}")
