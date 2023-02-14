from web3 import Web3
from decouple import config
from web3.middleware import geth_poa_middleware
from web3.contract import ContractEvent
import time
import mysql.connector

bsc_url = config('BSC_TESTNET_URL')

# MySQL DB:
mydb = mysql.connector.connect(
  host="localhost",
  user="root",
  password="Sql@12345",
  database='lad_block'
)
mycursor = mydb.cursor()

# HTTPProvider:
w3 = Web3(Web3.HTTPProvider(bsc_url))
w3.middleware_onion.inject(geth_poa_middleware, layer=0)

res = w3.isConnected()
print(res)
print(w3.eth.chain_id)

# SpacePayment contract address and ABI
CONTRACT_ADDRESS = '0x5DF166d2875c82f6f3B172e8eeBAbB87b627014c'
ABI = '[ { "inputs": [ { "internalType": "address", "name": "tokenAddress", "type": "address" } ], "stateMutability": "nonpayable", "type": "constructor" }, { "anonymous": false, "inputs": [ { "indexed": false, "internalType": "address", "name": "account", "type": "address" }, { "indexed": false, "internalType": "uint256", "name": "amount", "type": "uint256" } ], "name": "Deposit", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "internalType": "uint256", "name": "epochDuration", "type": "uint256" } ], "name": "EpochDurationChanged", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "internalType": "uint256", "name": "id", "type": "uint256" }, { "indexed": false, "internalType": "uint256", "name": "expiryBlock", "type": "uint256" }, { "indexed": false, "internalType": "uint256", "name": "price", "type": "uint256" } ], "name": "ExpiryExtended", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "internalType": "uint256", "name": "hardwareType", "type": "uint256" }, { "indexed": false, "internalType": "string", "name": "name", "type": "string" }, { "indexed": false, "internalType": "uint256", "name": "price", "type": "uint256" } ], "name": "HardwarePriceChanged", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": true, "internalType": "address", "name": "previousOwner", "type": "address" }, { "indexed": true, "internalType": "address", "name": "newOwner", "type": "address" } ], "name": "OwnershipTransferred", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "internalType": "uint256", "name": "id", "type": "uint256" }, { "indexed": false, "internalType": "address", "name": "owner", "type": "address" }, { "indexed": false, "internalType": "uint256", "name": "hardwareType", "type": "uint256" }, { "indexed": false, "internalType": "uint256", "name": "expiryBlock", "type": "uint256" }, { "indexed": false, "internalType": "uint256", "name": "price", "type": "uint256" } ], "name": "SpaceCreated", "type": "event" }, { "inputs": [ { "internalType": "address", "name": "account", "type": "address" } ], "name": "balanceOf", "outputs": [ { "internalType": "uint256", "name": "", "type": "uint256" } ], "stateMutability": "view", "type": "function" }, { "inputs": [ { "internalType": "uint256", "name": "hardwareType", "type": "uint256" }, { "internalType": "uint256", "name": "blocks", "type": "uint256" } ], "name": "buySpace", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "internalType": "uint256", "name": "hardwareType", "type": "uint256" }, { "internalType": "string", "name": "newName", "type": "string" }, { "internalType": "uint256", "name": "newPrice", "type": "uint256" } ], "name": "changeHardware", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "internalType": "uint256", "name": "amount", "type": "uint256" } ], "name": "deposit", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "internalType": "uint256", "name": "spaceId", "type": "uint256" }, { "internalType": "uint256", "name": "blocks", "type": "uint256" } ], "name": "extendSpace", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "internalType": "uint256", "name": "hardwareType", "type": "uint256" } ], "name": "hardwareInfo", "outputs": [ { "components": [ { "internalType": "string", "name": "name", "type": "string" }, { "internalType": "uint256", "name": "pricePerBlock", "type": "uint256" } ], "internalType": "struct SpacePayment.Hardware", "name": "", "type": "tuple" } ], "stateMutability": "view", "type": "function" }, { "inputs": [ { "internalType": "uint256", "name": "", "type": "uint256" } ], "name": "idToHardware", "outputs": [ { "internalType": "string", "name": "name", "type": "string" }, { "internalType": "uint256", "name": "pricePerBlock", "type": "uint256" } ], "stateMutability": "view", "type": "function" }, { "inputs": [ { "internalType": "uint256", "name": "", "type": "uint256" } ], "name": "idToSpace", "outputs": [ { "internalType": "address", "name": "owner", "type": "address" }, { "internalType": "uint256", "name": "hardwareType", "type": "uint256" }, { "internalType": "uint256", "name": "expiryBlock", "type": "uint256" } ], "stateMutability": "view", "type": "function" }, { "inputs": [ { "internalType": "uint256", "name": "spaceId", "type": "uint256" } ], "name": "isExpired", "outputs": [ { "internalType": "bool", "name": "", "type": "bool" } ], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "ladToken", "outputs": [ { "internalType": "contract LagrangeDAOToken", "name": "", "type": "address" } ], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "owner", "outputs": [ { "internalType": "address", "name": "", "type": "address" } ], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "renounceOwnership", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "internalType": "uint256", "name": "spaceId", "type": "uint256" } ], "name": "spaceInfo", "outputs": [ { "components": [ { "internalType": "address", "name": "owner", "type": "address" }, { "internalType": "uint256", "name": "hardwareType", "type": "uint256" }, { "internalType": "uint256", "name": "expiryBlock", "type": "uint256" } ], "internalType": "struct SpacePayment.Space", "name": "", "type": "tuple" } ], "stateMutability": "view", "type": "function" }, { "inputs": [ { "internalType": "address", "name": "newOwner", "type": "address" } ], "name": "transferOwnership", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "internalType": "uint256", "name": "amount", "type": "uint256" } ], "name": "withdraw", "outputs": [], "stateMutability": "nonpayable", "type": "function" } ]'

# validate SpacePayment contract address
is_address_valid = w3.isAddress(CONTRACT_ADDRESS)
#print(is_address_valid)

# Block on which the contract was deployed:
from_block = 27243037
target_block = w3.eth.get_block('latest')
# Block chunk to be scanned:
batchSize = 1000

sql = "INSERT INTO transaction(block_number,event,account_address,recipient_address,amount,tx_hash,contract_id,coin_id) VALUES "

while from_block <  target_block.number:
    toBlock = from_block + batchSize
    print(from_block,toBlock)

    contract = w3.eth.contract(address=Web3.toChecksumAddress(CONTRACT_ADDRESS), abi=ABI)

    depositEvents = contract.events.Deposit.getLogs(fromBlock=from_block, toBlock=toBlock)
    start_block = toBlock

    if depositEvents != ():
        depositEventsSize = len(depositEvents)
        i = 0
        blocknumInit = 0

        while i < depositEventsSize:
            # print(i)
            if blocknumInit != depositEvents[i].blockNumber:
                # TODO: Debug on depositTimeStamp
                # depositTimeStamp = w3.eth.get_block(depositEvents[i].blockNumber).timestamp

                # print(depositTimeStamp)
                # print(depositEvents[i].blockNumber,
                # depositEvents[i].event,
                # depositEvents[i].args.account,
                # depositEvents[i].args.amount,
                # depositEvents[i].transactionHash.hex())

                # val = "(" + str(depositEvents[i].blockNumber) + ", '" + str(depositEvents[i].event) + "', '" + str(depositEvents[i].args.account) + "', '" + str(depositEvents[i].address) + "', " + str(depositEvents[i].args.amount/ 10 ** 18) + ", '" + str(depositEvents[i].transactionHash.hex()) + "', '" + str(depositTimeStamp) + "')"
                val2 = "(" + str(depositEvents[i].blockNumber) + ", '" + str(depositEvents[i].event) + "', '" + str(depositEvents[i].args.account) + "', '" + str(depositEvents[i].address) + "', " + str(depositEvents[i].args.amount/ 10 ** 18) + ", '" + str(depositEvents[i].transactionHash.hex()) + "', " + "1, " + "1" + ")"
                sqlCommand = sql + val2

                try:
                    mycursor.execute(sqlCommand)
                except:
                    print("Please check the SQL command")

                mydb.commit()
                print(mycursor.rowcount, "record inserted.")

            blocknumInit = depositEvents[i].blockNumber
            i = i+1

    from_block = from_block + batchSize + 1
    blockDiff = target_block.number - from_block

    # print("target_block: ",target_block.number)
    # print("batchSize: ",batchSize)
    # print("from_block ",from_block)
    # print("blockDiff: ",blockDiff)

    if(blockDiff < batchSize):
        batchSize = blockDiff