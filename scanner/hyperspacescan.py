from web3 import Web3
from decouple import config
from web3.middleware import geth_poa_middleware
from web3.contract import ContractEvent
import time
import mysql.connector

hyperspace_url = config('HYPERSPACE_URL')

# MySQL DB:
mydb = mysql.connector.connect(
  host="localhost",
  user="root",
  password="Sql@12345",
  database='lad_block'
)
mycursor = mydb.cursor()

# HTTPProvider:
w3 = Web3(Web3.HTTPProvider(hyperspace_url))
w3.middleware_onion.inject(geth_poa_middleware, layer=0)

res = w3.isConnected()
#print(w3.eth.chain_id)

# SpacePayment contract address and ABI
CONTRACT_ADDRESS = '0x82D937426F43e99DA6811F167eCFB0103cd07E6B'
ABI = '[ { "inputs": [ { "internalType": "address", "name": "tokenAddress", "type": "address" } ], "stateMutability": "nonpayable", "type": "constructor" }, { "anonymous": false, "inputs": [ { "indexed": false, "internalType": "address", "name": "account", "type": "address" }, { "indexed": false, "internalType": "uint256", "name": "amount", "type": "uint256" } ], "name": "Deposit", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "internalType": "uint256", "name": "epochDuration", "type": "uint256" } ], "name": "EpochDurationChanged", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "internalType": "uint256", "name": "id", "type": "uint256" }, { "indexed": false, "internalType": "uint256", "name": "expiryBlock", "type": "uint256" }, { "indexed": false, "internalType": "uint256", "name": "price", "type": "uint256" } ], "name": "ExpiryExtended", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "internalType": "uint256", "name": "hardwareType", "type": "uint256" }, { "indexed": false, "internalType": "string", "name": "name", "type": "string" }, { "indexed": false, "internalType": "uint256", "name": "price", "type": "uint256" } ], "name": "HardwarePriceChanged", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": true, "internalType": "address", "name": "previousOwner", "type": "address" }, { "indexed": true, "internalType": "address", "name": "newOwner", "type": "address" } ], "name": "OwnershipTransferred", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "internalType": "uint256", "name": "id", "type": "uint256" }, { "indexed": false, "internalType": "address", "name": "owner", "type": "address" }, { "indexed": false, "internalType": "uint256", "name": "hardwareType", "type": "uint256" }, { "indexed": false, "internalType": "uint256", "name": "expiryBlock", "type": "uint256" }, { "indexed": false, "internalType": "uint256", "name": "price", "type": "uint256" } ], "name": "SpaceCreated", "type": "event" }, { "inputs": [ { "internalType": "address", "name": "account", "type": "address" } ], "name": "balanceOf", "outputs": [ { "internalType": "uint256", "name": "", "type": "uint256" } ], "stateMutability": "view", "type": "function" }, { "inputs": [ { "internalType": "uint256", "name": "hardwareType", "type": "uint256" }, { "internalType": "uint256", "name": "blocks", "type": "uint256" } ], "name": "buySpace", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "internalType": "uint256", "name": "hardwareType", "type": "uint256" }, { "internalType": "string", "name": "newName", "type": "string" }, { "internalType": "uint256", "name": "newPrice", "type": "uint256" } ], "name": "changeHardware", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "internalType": "uint256", "name": "amount", "type": "uint256" } ], "name": "deposit", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "internalType": "uint256", "name": "spaceId", "type": "uint256" }, { "internalType": "uint256", "name": "blocks", "type": "uint256" } ], "name": "extendSpace", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "internalType": "uint256", "name": "hardwareType", "type": "uint256" } ], "name": "hardwareInfo", "outputs": [ { "components": [ { "internalType": "string", "name": "name", "type": "string" }, { "internalType": "uint256", "name": "pricePerBlock", "type": "uint256" } ], "internalType": "struct SpacePayment.Hardware", "name": "", "type": "tuple" } ], "stateMutability": "view", "type": "function" }, { "inputs": [ { "internalType": "uint256", "name": "", "type": "uint256" } ], "name": "idToHardware", "outputs": [ { "internalType": "string", "name": "name", "type": "string" }, { "internalType": "uint256", "name": "pricePerBlock", "type": "uint256" } ], "stateMutability": "view", "type": "function" }, { "inputs": [ { "internalType": "uint256", "name": "", "type": "uint256" } ], "name": "idToSpace", "outputs": [ { "internalType": "address", "name": "owner", "type": "address" }, { "internalType": "uint256", "name": "hardwareType", "type": "uint256" }, { "internalType": "uint256", "name": "expiryBlock", "type": "uint256" } ], "stateMutability": "view", "type": "function" }, { "inputs": [ { "internalType": "uint256", "name": "spaceId", "type": "uint256" } ], "name": "isExpired", "outputs": [ { "internalType": "bool", "name": "", "type": "bool" } ], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "ladToken", "outputs": [ { "internalType": "contract LagrangeDAOToken", "name": "", "type": "address" } ], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "owner", "outputs": [ { "internalType": "address", "name": "", "type": "address" } ], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "renounceOwnership", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "internalType": "uint256", "name": "spaceId", "type": "uint256" } ], "name": "spaceInfo", "outputs": [ { "components": [ { "internalType": "address", "name": "owner", "type": "address" }, { "internalType": "uint256", "name": "hardwareType", "type": "uint256" }, { "internalType": "uint256", "name": "expiryBlock", "type": "uint256" } ], "internalType": "struct SpacePayment.Space", "name": "", "type": "tuple" } ], "stateMutability": "view", "type": "function" }, { "inputs": [ { "internalType": "address", "name": "newOwner", "type": "address" } ], "name": "transferOwnership", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "internalType": "uint256", "name": "amount", "type": "uint256" } ], "name": "withdraw", "outputs": [], "stateMutability": "nonpayable", "type": "function" } ]'

# validate SpacePayment contract address
is_address_valid = w3.isAddress(CONTRACT_ADDRESS)
#print(is_address_valid)

lastScanBlockCommand = "select last_scan_block_number_payment from network WHERE id = 2"
mycursor.execute(lastScanBlockCommand)
lastScannedBlock = mycursor.fetchall()

# Block on which the contract was deployed:
from_block = lastScannedBlock[0][0] + 1
target_block = w3.eth.get_block('latest')
# Block chunk to be scanned:
batchSize = 1000

print("from_block: ",from_block)

sql = "INSERT INTO transaction(block_number,event,account_address,recipient_address,amount,tx_hash,contract_id,coin_id) VALUES "

while from_block <  target_block.number:
    toBlock = from_block + batchSize
    print(from_block,toBlock)

    contract = w3.eth.contract(address=Web3.toChecksumAddress(CONTRACT_ADDRESS), abi=ABI)

    depositEvents = contract.events.Deposit.getLogs(fromBlock=from_block, toBlock=toBlock)
    spaceCreatedEvent = contract.events.SpaceCreated.getLogs(fromBlock=from_block, toBlock=toBlock)
    expiryExtendedEvent = contract.events.ExpiryExtended.getLogs(fromBlock=from_block, toBlock=toBlock)
    hardwarePriceChangedEvent = contract.events.HardwarePriceChanged.getLogs(fromBlock=from_block, toBlock=toBlock)

    if depositEvents != ():
        depositEventsSize = len(depositEvents)
        i = 0
        blocknumInit = 0

        while i < depositEventsSize:
            # print(i)
            if blocknumInit != depositEvents[i].blockNumber:
                # TODO: Debug on depositTimeStamp
                # print("debugging...")
                # depositTimeStamp = w3.eth.get_block(depositEvents[i].blockNumber).timestamp
                # print(depositTimeStamp)

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
                except mydb.Error as e:
                    print(e)
                    # print("Please check the SQL command")

                mydb.commit()
                print(depositEvents[i].blockNumber,mycursor.rowcount, "depositEvents record inserted.")

            blocknumInit = depositEvents[i].blockNumber
            i = i+1

    if spaceCreatedEvent != ():
        # (AttributeDict({'args': AttributeDict({'id': 1, 'owner': '0xA878795d2C93985444f1e2A077FA324d59C759b0', 'hardwareType': 1, 'expiryBlock': 67811, 'price': 0}), 'event': 'SpaceCreated', 'logIndex': 0, 'transactionIndex': 0, 'transactionHash': HexBytes('0x35df469992eafcfac50cb003a047f806c21877d6a3017385ee8a17f395cd7bb8'), 'address': '0x82D937426F43e99DA6811F167eCFB0103cd07E6B', 'blockHash': HexBytes('0x9a01e9b4500af9ae2aa3194b60a9d4b816e6b183141b71ab519daca0ac30be95'), 'blockNumber': 67711}), AttributeDict({'args': AttributeDict({'id': 2, 'owner': '0xA878795d2C93985444f1e2A077FA324d59C759b0', 'hardwareType': 2, 'expiryBlock': 67728, 'price': 10000000000000000000}), 'event': 'SpaceCreated', 'logIndex': 0, 'transactionIndex': 0, 'transactionHash': HexBytes('0xb6a5910a8aba99c47cd2d408e00a8de08d0ee1a5eee1936813c005bc47bc3633'), 'address': '0x82D937426F43e99DA6811F167eCFB0103cd07E6B', 'blockHash': HexBytes('0x9dd3cb3d720479a8dcea08ded060171fd23bafde5bac666aa4e504c4ae8e0de2'), 'blockNumber': 67718}))
        spaceCreatedEventSize = len(spaceCreatedEvent)
        i = 0
        blocknumInit = 0
    

        while i < spaceCreatedEventSize:
            # print(i)
            if blocknumInit != spaceCreatedEvent[i].blockNumber:
                val2 = "(" + str(spaceCreatedEvent[i].blockNumber) + ", '" + str(spaceCreatedEvent[i].event) + "', '" + str(spaceCreatedEvent[i].args.owner) + "', '" + str(spaceCreatedEvent[i].address) + "', " + str(spaceCreatedEvent[i].args.price/ 10 ** 18) + ", '" + str(spaceCreatedEvent[i].transactionHash.hex()) + "', " + "1, " + "1" + ")"
                sqlCommand = sql + val2

                try:
                    mycursor.execute(sqlCommand)
                except mydb.Error as e:
                    print("Please check the SQL command")

                mydb.commit()
                print(spaceCreatedEvent[i].blockNumber,mycursor.rowcount, "spaceCreatedEvent record inserted.")

            blocknumInit = spaceCreatedEvent[i].blockNumber
            i = i+1

    if expiryExtendedEvent != ():
        expiryExtendedEventSize = len(expiryExtendedEvent)
        i = 0
        blocknumInit = 0
    

        while i < expiryExtendedEventSize:
            # print(i)
            if blocknumInit != expiryExtendedEvent[i].blockNumber:
                val2 = "(" + str(expiryExtendedEvent[i].blockNumber) + ", '" + str(expiryExtendedEvent[i].event) + "', '" + str(expiryExtendedEvent[i].args.owner) + "', '" + str(expiryExtendedEvent[i].address) + "', " + str(expiryExtendedEvent[i].args.price/ 10 ** 18) + ", '" + str(expiryExtendedEvent[i].transactionHash.hex()) + "', " + "1, " + "1" + ")"
                sqlCommand = sql + val2

                try:
                    mycursor.execute(sqlCommand)
                except mydb.Error as e:
                    print("Please check the SQL command")

                mydb.commit()
                print(expiryExtendedEvent[i].blockNumber,mycursor.rowcount, "expiryExtendedEvent record inserted.")

            blocknumInit = expiryExtendedEvent[i].blockNumber
            i = i+1

    from_block = from_block + batchSize + 1
    blockDiff = target_block.number - from_block

    # print("target_block: ",target_block.number)
    # print("batchSize: ",batchSize)
    # print("from_block ",from_block)
    # print("blockDiff: ",blockDiff)

    if(blockDiff < batchSize):
        batchSize = blockDiff

# Update last_scan_block
updateLastBlock = "UPDATE network SET last_scan_block_number_payment = (%s) WHERE id=1"
toBlkList = []
toBlkList.append(target_block.number)
mycursor.execute(updateLastBlock,toBlkList)
# print(toBlkList)
mydb.commit()