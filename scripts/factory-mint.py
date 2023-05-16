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

assert web3.is_checksum_address(wallet_address), f"Not a valid wallet address: {wallet_address}"
assert web3.is_checksum_address(factory_contract_address), f"Not a valid contract address: {factory_contract_address}"

# smart contract instance
factory_contract = web3.eth.contract(address=factory_contract_address, abi=factory_contract_abi)

# call requestDataNFT function
nft_uri = 'https://3b46ed854.acl.multichain.storage/ipfs/QmfWumvNSWTTXS6QTkmsEunDtUqGTwFyGNDp8bMCxxUK6y'
# transaction = factory_contract.functions.requestDataNFT(nft_uri).transact()

tx_config = {
    'from': wallet_address,
    'gas': 4000000,
    'maxFeePerGas': web3.to_wei('5', 'gwei'),
    'maxPriorityFeePerGas': web3.to_wei('1', 'gwei'),
}
nonce = web3.eth.get_transaction_count(wallet_address)
tx_config["nonce"] = nonce

# Build Tx with chainId, wallet address, nonce
request_dataNFT_tx = factory_contract.functions.requestDataNFT(nft_uri).build_transaction(tx_config)

# SIGN TX
signed_tx = web3.eth.account.sign_transaction(request_dataNFT_tx, private_key)
tx_hash = web3.eth.send_raw_transaction(signed_tx.rawTransaction)
tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
hash = web3.to_hex(tx_hash)
print("hash: ",hash)

# Get the `Topics` field to retrieve `requestID`
txInputReceipt = web3.eth.get_transaction_receipt(tx_hash)
TxLogs = txInputReceipt.logs
request_id = TxLogs[0].topics[1].hex()
print("request_id: ",request_id)

# Wait for the oracle to complete the request
time.sleep(60)

# Call the `requestData` mapping to check if the request was fulfilled
# request_data_tx = factory_contract.functions.requestData(request_id).call()
# print("request_data_tx: ",request_data_tx)

# # Store the result of `requestData` in the respective variables
# tx_owner = request_data_tx[0]
# tx_uri = request_data_tx[1]
# tx_deployable = request_data_tx[2]
# tx_fulfilled = request_data_tx[3]

# # Check if the correct owner is the one calling the method
# assert tx_owner == wallet_address
# # Check if `deployabe` is True
# assert tx_deployable == True
# # Check if `fulfilled` is True
# assert tx_fulfilled == True

# print("------ Checks completed -------")

nonce2 = web3.eth.get_transaction_count(wallet_address)
tx_config["nonce"] = nonce2

# Call the createDataNFT function
# nft_name = input(f"enter NFT name: ")
# nft_symbol = input(f"enter NFT symbol: ")

# Build Tx with chainId, wallet address, nonce for creation of Data NFT from Factory
# create_dataNFT_tx = factory_contract.functions.claimDataNFT(request_id).build_transaction(tx_config)

# create_dataNFT_tx = factory_contract.functions.claimDataNFT(request_id).estimateGas(tx_config)
create_dataNFT_tx = factory_contract.functions.claimDataNFT(request_id).build_transaction(tx_config)

print(f"Deploying new NFT contract...")
# SIGN TX for createDataNFT
createDataNFT_signed_tx = web3.eth.account.sign_transaction(create_dataNFT_tx, private_key)
createDataNFT_tx_hash = web3.eth.send_raw_transaction(createDataNFT_signed_tx.rawTransaction)
createDataNFT_tx_receipt = web3.eth.wait_for_transaction_receipt(createDataNFT_tx_hash)
createDataNFT_hash = web3.to_hex(createDataNFT_tx_hash)
print("createDataNFT_hash: ",createDataNFT_hash)

create_dataNFT_Txlogs = createDataNFT_tx_receipt['logs']
print("create_dataNFT_Txlogs: ",create_dataNFT_Txlogs)

