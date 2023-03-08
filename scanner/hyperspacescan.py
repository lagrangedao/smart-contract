from web3 import Web3
from decouple import config
from web3.middleware import geth_poa_middleware
from web3.contract import ContractEvent
import time
import mysql.connector
import json
from hexbytes import HexBytes
import warnings

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

lastScanBlockCommand = "select last_scan_block_number_payment from network WHERE id = 1"
mycursor.execute(lastScanBlockCommand)
lastScannedBlock = mycursor.fetchall()

# Block on which the contract was deployed:
from_block = 121744	 #lastScannedBlock[0][0] + 1
target_block = w3.eth.get_block('latest')
# Block chunk to be scanned:
batchSize = 1000

print("from_block: ",from_block)

txSQL = "INSERT INTO transaction(block_number,event,account_address,recipient_address,amount,tx_hash,created_at,contract_id,coin_id) VALUES "
logSQL = "INSERT INTO event_logs(address,name,data,topics,log_index,removed) VALUES (%s, %s, %s, %s, %s, %s)"

class HexJsonEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, HexBytes):
            return obj.hex()
        return super().default(obj)

def sigToEventName(eventSig):
    if eventSig == '0x8c5be1e5':
        return "Approval"
    elif eventSig == '0xddf252ad':
        return "Transfer"
    elif eventSig == '0xe1fffcc4':
        return "Deposit"

while from_block < target_block.number:
    # silence harmless warnings
    warnings.filterwarnings("ignore")

    toBlock = from_block + batchSize
    print(from_block,toBlock)

    contract = w3.eth.contract(address=Web3.toChecksumAddress(CONTRACT_ADDRESS), abi=ABI)

    depositEvents = contract.events.Deposit.getLogs(fromBlock=from_block, toBlock=toBlock)
    spaceCreatedEvent = contract.events.SpaceCreated.getLogs(fromBlock=from_block, toBlock=toBlock)
    expiryExtendedEvent = contract.events.ExpiryExtended.getLogs(fromBlock=from_block, toBlock=toBlock)
    hardwarePriceChangedEvent = contract.events.HardwarePriceChanged.getLogs(fromBlock=from_block, toBlock=toBlock)

    # func = sigToEventName('0x8c5be1e5')
    # print("func: ",func)

    if depositEvents != ():
        depositEventsSize = len(depositEvents)
        i = 0
        blocknumInit = 0

        while i < depositEventsSize:
            # print(i)
            if blocknumInit != depositEvents[i].blockNumber:
                depositTimeStamp = w3.eth.get_block(depositEvents[i].blockNumber).timestamp
                #print(depositTimeStamp)

                # Insert into transaction table
                txVal = "(" + str(depositEvents[i].blockNumber) + ", '" + str(depositEvents[i].event) + "', '" + str(depositEvents[i].args.account) + "', '" + str(depositEvents[i].address) + "', " + str(depositEvents[i].args.amount/ 10 ** 18) + ", '" + str(depositEvents[i].transactionHash.hex()) + "', '" + str(depositTimeStamp) + "', " + "1, " + "1" + ")"
                sqlCommand = txSQL + txVal

                try:
                    mycursor.execute(sqlCommand)
                    mydb.commit()
                except mydb.Error as e:
                    print(e)

                # insert record in log table:
                txHash = depositEvents[i].transactionHash.hex()
                txInputReceipt = w3.eth.get_transaction_receipt(txHash)
                depositTxLogs = txInputReceipt.logs
                # print("depositTxLogs: ",depositTxLogs)
                #logs = contract.events.Deposit().processReceipt(txInputReceipt)
                # print("txInputReceipt size: ",len(txInputReceipt))
                # print("txInputReceipt: ",txInputReceipt)
                # print("logs: ",logs)
                # print("---------")
                # print("logs arr size: ",len(txInputReceipt.logs))
                # print("logs array: ",txInputReceipt.logs)
                # print("---------")
                # print("topics: ",txInputReceipt.logs[i].topics)
                # print("removed: ",txInputReceipt.logs[i].removed)
                
                # result = dict(logs[0].args)
                # print("result: ",result)
                # tx_data = json.dumps(result, cls=HexJsonEncoder)
                # print("tx_data: ",tx_data)

                logsArrLen = len(txInputReceipt.logs)
                t=0
                while t < logsArrLen:
                    topics1 = depositTxLogs[t].topics[0].hex()
                    eventName = sigToEventName(topics1[0:10])

                    depositEventList = []
                    # event_logs:
                    depositEventList.append(str(depositTxLogs[t].address))
                    depositEventList.append(eventName)
                    depositEventList.append(str(depositTxLogs[t].data))
                    depositEventList.append(str(depositTxLogs[t].topics))
                    depositEventList.append(str(depositTxLogs[t].logIndex))
                    depositEventList.append(str(depositTxLogs[t].removed))
                    
                    t = t+1
                    try:
                        mycursor.execute(logSQL,depositEventList)
                        mydb.commit()
                    except mydb.Error as e:
                        print(e)

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
                # spaceCreatedTimeStamp = 00000000
                spaceCreatedTimeStamp = w3.eth.get_block(spaceCreatedEvent[i].blockNumber).timestamp

                # Tx logs:
                txHash = spaceCreatedEvent[i].transactionHash.hex()
                txInputDecoded = w3.eth.get_transaction_receipt(txHash)
                spaceCreatedTxLogs = txInputDecoded.logs[0]
                # result = dict(logs[0].args)
                # tx_data = json.dumps(result, cls=HexJsonEncoder)
                # print("logs: ",logs[0].transactionIndex)
                # print("JSON str: ",tx_json)

                # TODO: parameterize Txinput SQL:
                txVal = "(" + str(spaceCreatedEvent[i].blockNumber) + ", '" + str(spaceCreatedEvent[i].event) + "', '" + str(spaceCreatedEvent[i].args.owner) + "', '" + str(spaceCreatedEvent[i].address) + "', " + str(spaceCreatedEvent[i].args.price/ 10 ** 18) + ", '" + str(spaceCreatedEvent[i].transactionHash.hex()) + "', '" + str(spaceCreatedTimeStamp) + "', " + "1, " + "1" + ")"
                sqlCommand = txSQL + txVal
                
                # event_logs:
                spaceCreatedEventList = []
                spaceCreatedEventList.append(str(spaceCreatedTxLogs.address))
                spaceCreatedEventList.append(str(spaceCreatedEvent[i].event))
                spaceCreatedEventList.append(spaceCreatedTxLogs.data)
                spaceCreatedEventList.append(str(spaceCreatedTxLogs.topics))
                spaceCreatedEventList.append(str(spaceCreatedTxLogs.logIndex))
                spaceCreatedEventList.append(str(spaceCreatedTxLogs.removed))

                try:
                    mycursor.execute(sqlCommand)
                    # mycursor.execute(logCommand)
                    mycursor.execute(logSQL,spaceCreatedEventList)
                except mydb.Error as e:
                    print(e)

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
            # print(expiryExtendedEvent[i])
            if blocknumInit != expiryExtendedEvent[i].blockNumber:
               
                # expiryExtendedTimeStamp = 00000000
                expiryExtendedTimeStamp = w3.eth.get_block(expiryExtendedEvent[i].blockNumber).timestamp
               
                # Tx logs:
                txHash = expiryExtendedEvent[i].transactionHash.hex()
                txInputDecoded = w3.eth.getTransactionReceipt(txHash)
                expiryExtendedTxLogs = txInputDecoded.logs[0]
                # logs = contract.events.ExpiryExtended().processReceipt(txInputDecoded)
                # result = dict(logs[0].args)
                # tx_data = json.dumps(result, cls=HexJsonEncoder)

                txVal = "(" + str(expiryExtendedEvent[i].blockNumber) + ", '" + str(expiryExtendedEvent[i].event) + "', '" + str(txInputDecoded['from']) + "', '" + str(expiryExtendedEvent[i].address) + "', " + str(expiryExtendedEvent[i].args.price/ 10 ** 18) + ", '" + str(expiryExtendedEvent[i].transactionHash.hex()) + "', '" + str(expiryExtendedTimeStamp) + "', " + "1, " + "1" + ")"
                sqlCommand = txSQL + txVal

                # txLogVal = "('" + str(logs[0].address) + "', '" + str(expiryExtendedEvent[i].event) + "', '" + tx_data + "', '" + str(logs[0].logIndex) + "', '" + txInputDecoded.logs[i].removed + "')"
                # logCommand = logSQL + txLogVal

                # event_logs:
                expiryExtendedEventList = []
                expiryExtendedEventList.append(str(expiryExtendedTxLogs.address))
                expiryExtendedEventList.append(str(expiryExtendedEvent[i].event))
                expiryExtendedEventList.append(expiryExtendedTxLogs.data)
                expiryExtendedEventList.append(str(expiryExtendedTxLogs.topics))
                expiryExtendedEventList.append(str(expiryExtendedTxLogs.logIndex))
                expiryExtendedEventList.append(str(expiryExtendedTxLogs.removed))

                try:
                    mycursor.execute(sqlCommand)
                    mycursor.execute(logSQL,expiryExtendedEventList)
                except mydb.Error as e:
                    print(e)

                mydb.commit()
                print(expiryExtendedEvent[i].blockNumber,mycursor.rowcount, "expiryExtendedEvent record inserted.")

            blocknumInit = expiryExtendedEvent[i].blockNumber
            i = i+1

    if hardwarePriceChangedEvent != ():
        hardwarePriceChangedEventSize = len(hardwarePriceChangedEvent)
        i = 0
        blocknumInit = 0
    

        while i < hardwarePriceChangedEventSize:
            # print(i)

            if blocknumInit != hardwarePriceChangedEvent[i].blockNumber:
                # hardwarePriceChangedTimeStamp = 00000000
                hardwarePriceChangedTimeStamp = w3.eth.get_block(hardwarePriceChangedEvent[i].blockNumber).timestamp

                #print("txInputDecoded: ",txInputDecoded)
                # logs = contract.events.HardwarePriceChanged().processReceipt(txInputDecoded)
                # print("logs: ",logs)
                # result = dict(logs[0].args)
                # tx_data = json.dumps(result, cls=HexJsonEncoder)
                # print("logs arr size: ",len(txInputDecoded.logs))

                # Tx logs:
                txHash = hardwarePriceChangedEvent[i].transactionHash.hex()
                txInputDecoded = w3.eth.getTransactionReceipt(txHash)
                hardwarePriceChangedTxLogs = txInputDecoded.logs[0]

                txVal = "(" + str(hardwarePriceChangedEvent[i].blockNumber) + ", '" + str(hardwarePriceChangedEvent[i].event) + "', '" + str(txInputDecoded['from']) + "', '" + str(hardwarePriceChangedEvent[i].address) + "', " + str(hardwarePriceChangedEvent[i].args.price/ 10 ** 18) + ", '" + str(hardwarePriceChangedEvent[i].transactionHash.hex()) + "', '" + str(hardwarePriceChangedTimeStamp) + "', " + "1, " + "1" + ")"
                sqlCommand = txSQL + txVal

                # txLogVal = "('" + str(logs[0].address) + "', '" + str(hardwarePriceChangedEvent[i].event) + "', '" + tx_data + "', '" + str(logs[0].logIndex) + "', '" + "False" + "')"
                # logCommand = logSQL + txLogVal

                # event_logs:
                hardwarePriceChangedList = []
                hardwarePriceChangedList.append(str(hardwarePriceChangedTxLogs.address))
                hardwarePriceChangedList.append(str(hardwarePriceChangedEvent[i].event))
                hardwarePriceChangedList.append(hardwarePriceChangedTxLogs.data)
                hardwarePriceChangedList.append(str(hardwarePriceChangedTxLogs.topics))
                hardwarePriceChangedList.append(str(hardwarePriceChangedTxLogs.logIndex))
                hardwarePriceChangedList.append(str(hardwarePriceChangedTxLogs.removed))

                try:
                    mycursor.execute(sqlCommand)
                    mycursor.execute(logSQL,hardwarePriceChangedList)
                except mydb.Error as e:
                    print(e)

                mydb.commit()
                print(hardwarePriceChangedEvent[i].blockNumber,mycursor.rowcount, "hardwarePriceChangedEvent record inserted.")

            blocknumInit = hardwarePriceChangedEvent[i].blockNumber
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