from web3 import Web3
from decouple import config
from web3.middleware import geth_poa_middleware
#from web3.contract import ContractEvent
import time
import mysql.connector
import json
from hexbytes import HexBytes
import warnings

polygon_url = config('POLYGON_URL')

# MySQL DB:
# mydb = mysql.connector.connect(
#   host="localhost",
#   user=config('DB_USER'),
#   password=config('DB_PASSWORD'),
#   database='lad_block'
# )
# mycursor = mydb.cursor()

# HTTPProvider:
w3 = Web3(Web3.HTTPProvider(polygon_url))
w3.middleware_onion.inject(geth_poa_middleware, layer=0)

res = w3.is_connected()
print("res: ",res)

# Hyperspace SpacePayment contract address and ABI
CONTRACT_ADDRESS = '0x2315804B67010B6AB003Bef541b22D19cC074f41'
nft_abi_file = open('../contracts/abi/LagrangeChainlinkData.json')
ABI = json.load(nft_abi_file)

# validate SpacePayment contract address
# is_address_valid = w3.isAddress(CONTRACT_ADDRESS)
# print("isAddrValid: ",is_address_valid)

# Block on which the contract was deployed:
from_block = 34290743
target_block = w3.eth.get_block('latest')
# Block chunk to be scanned:
batchSize = 1000

while from_block < target_block.number:
    # silence harmless warnings
    warnings.filterwarnings("ignore")

    toBlock = from_block + batchSize
    print(from_block,toBlock)

    contract = w3.eth.contract(address=Web3.utils.toChecksumAddress(CONTRACT_ADDRESS), abi=ABI)

    transferEvents = contract.events.safeTransferFrom.getLogs(fromBlock=from_block, toBlock=toBlock)
    print("transferEvents: ",transferEvents)