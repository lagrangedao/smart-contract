import os
import json
import sys

from web3 import HTTPProvider, Web3
from web3.middleware import geth_poa_middleware

from dotenv import load_dotenv
load_dotenv()

rpc_endpoint = os.getenv("rpc_endpoint")
assert rpc_endpoint is not None, "You must set rpc_endpoint in .env file"
web3 = Web3(HTTPProvider(rpc_endpoint))
web3.middleware_onion.inject(geth_poa_middleware, layer=0)
block_number = web3.eth.block_number
print(f"Connected to {rpc_endpoint}, chain id is {web3.eth.chain_id}. the latest block is {block_number:,}\n")

factory_contract_address = '0xCE35818cA65cfFEbbCF3a3444d57a93ba110Bd04'
factory_contract_abi_file = open('../contracts/abi/DataNFTFactory.json')
factory_contract_abi = json.load(factory_contract_abi_file)

wallet_address = os.getenv('wallet_address')
private_key = os.getenv('private_key')

print(f"Your address: {wallet_address}\n")

assert web3.isChecksumAddress(wallet_address), f"Not a valid wallet address: {wallet_address}"
assert web3.isChecksumAddress(factory_contract_address), f"Not a valid contract address: {factory_contract_address}"

# smart contract instance
factory_contract = web3.eth.contract(address=factory_contract_address, abi=factory_contract_abi)

# call requestDataNFT function
nft_uri = 'https://2d9999d121.calibration-swan-acl.filswan.com/ipfs/QmZEPZos8pExSSqfZwi4RKrLHUGBgQ5KsHMP3poyPMBomA'
# transaction = factory_contract.functions.requestDataNFT(nft_uri).transact()
# tx_receipt = web3.eth.waitForTransactionReceipt(transaction)
# request_id = tx_receipt['logs'][0]['data'].hex()[2:]  # remove '0x' prefix from the hex string
# print(f'Request ID: {request_id}')

tx_config = {
    'chainId': web3.eth.chain_id,
    'from': wallet_address,
    # 'gas': 410224,
    # 'maxFeePerGas': web3.toWei('100', 'gwei'),
    # 'maxPriorityFeePerGas': web3.toWei('25', 'gwei'),
}

nonce = web3.eth.get_transaction_count(wallet_address)
tx_config["nonce"] = nonce

request_dataNFT_tx = factory_contract.functions.requestDataNFT(nft_uri).build_transaction(tx_config)

# SIGN TX
signed_tx = web3.eth.account.sign_transaction(request_dataNFT_tx, private_key)
tx_hash = web3.eth.send_raw_transaction(signed_tx.rawTransaction)
receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
hash = web3.toHex(tx_hash)

print("hash: ",hash)

request_id = receipt['logs'][0]['data']
print("request_id: ",request_id)