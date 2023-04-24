"""

- Mint NFT on FEVM

"""
import os
import json
import sys

from web3 import HTTPProvider, Web3
from web3.middleware import geth_poa_middleware

from dotenv import load_dotenv
load_dotenv()

print('''


██╗░░░░░░█████╗░░██████╗░██████╗░░█████╗░███╗░░██╗░██████╗░███████╗░░██████╗░░█████╗░░█████╗░
██║░░░░░██╔══██╗██╔════╝░██╔══██╗██╔══██╗████╗░██║██╔════╝░██╔════╝░░██╔══██╗██╔══██╗██╔══██╗
██║░░░░░███████║██║░░██╗░██████╔╝███████║██╔██╗██║██║░░██╗░█████╗░░░░██║░░██║███████║██║░░██║
██║░░░░░██╔══██║██║░░╚██╗██╔══██╗██╔══██║██║╚████║██║░░╚██╗██╔══╝░░░░██║░░██║██╔══██║██║░░██║
███████╗██║░░██║╚██████╔╝██║░░██║██║░░██║██║░╚███║╚██████╔╝███████╗░░██████╔╝██║░░██║╚█████╔╝
╚══════╝╚═╝░░╚═╝░╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝░╚═════╝░╚══════╝░░╚═════╝░╚═╝░░╚═╝░╚════╝░
                                                                                                                                                                                                                                                                                                                                                                                                                         
''')

rpc_endpoint = os.getenv("rpc_endpoint")
assert rpc_endpoint is not None, "You must set rpc_endpoint in .env file"
web3 = Web3(HTTPProvider(rpc_endpoint))
web3.middleware_onion.inject(geth_poa_middleware, layer=0)
block_number = web3.eth.block_number
print(f"Connected to {rpc_endpoint}, chain id is {web3.eth.chain_id}. the latest block is {block_number:,}\n")

dnft_address = "0x923AfAdE5d2c600b8650334af60D6403642c1bce"
dnft_abi_file = open('../contracts/abi/DataNFT-ChainlinkOracle.json')
dnft_abi = json.load(dnft_abi_file)

wallet_address = os.getenv('wallet_address')
private_key = os.getenv('private_key')

print(f"Your address: {wallet_address}\n")

assert web3.is_checksum_address(wallet_address), f"Not a valid wallet address: {wallet_address}"
assert web3.is_checksum_address(dnft_address), f"Not a valid contract address: {dnft_address}"

dnft_contract = web3.eth.contract(address=dnft_address, abi=dnft_abi)

tx_config = {
    'from': wallet_address,
    'maxFeePerGas': web3.to_wei('250', 'gwei'),
    'maxPriorityFeePerGas': web3.to_wei('5', 'gwei'),
}

## SHOULD BE METADATA URL
ipfs_url = input("NFT Metadata (IPFS URL): ")

# # Fat-fingering check
print(f"\nConfirm minting NFT of {ipfs_url}?")
confirm = input("Ok [y/n]?")
if not confirm.lower().startswith("y"):
    print("Aborted")
    sys.exit(1)

print(f"\nMinting...")
nonce = web3.eth.get_transaction_count(wallet_address)
tx_config["nonce"] = nonce
mint_tx = dnft_contract.functions.mint(ipfs_url).build_transaction(tx_config)

# SIGN TX
signed_tx = web3.eth.account.sign_transaction(mint_tx, private_key)
tx_hash = web3.eth.send_raw_transaction(signed_tx.rawTransaction)
receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
hash = web3.to_hex(tx_hash)

print(f"Mint is completed. Transaction Hash: {hash}")
print(f"View on Block Explorer: https://mumbai.polygonscan.com/tx/{hash}")