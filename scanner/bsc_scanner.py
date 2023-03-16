from web3 import Web3
from decouple import config
from web3.middleware import geth_poa_middleware
from web3.contract import ContractEvent
import time
import mysql.connector
import json
from hexbytes import HexBytes
import warnings

bsc_url = config('BSC_TESTNET_URL')

# MySQL DB:
mydb = mysql.connector.connect(
  host="localhost",
  user=config('DB_USER'),
  password=config('DB_PASSWORD'),
  database='lad_block'
)
mycursor = mydb.cursor()

# HTTPProvider:
w3 = Web3(Web3.HTTPProvider(bsc_url))
w3.middleware_onion.inject(geth_poa_middleware, layer=0)

res = w3.isConnected()

# SpacePayment contract address and ABI
CONTRACT_ADDRESS = '0x5DF166d2875c82f6f3B172e8eeBAbB87b627014c'
space_abi_file = open('../contracts/abi/SpacePayment.json')
ABI = json.load(space_abi_file)

# validate SpacePayment contract address
is_address_valid = w3.isAddress(CONTRACT_ADDRESS)
#print(is_address_valid)

# Need to configure:
contract_id_val = 2
coin_id_val = 1
network_id = 2

lastScanBlockCommand = "select last_scan_block_number_payment from network WHERE id = (%s)"
networkIDList = []
networkIDList.append(network_id)
mycursor.execute(lastScanBlockCommand,networkIDList)
lastScannedBlock = mycursor.fetchall()

# Block on which the contract was deployed:
from_block = 27267003 # lastScannedBlock[0][0] + 1
target_block = w3.eth.get_block('latest')
# Block chunk to be scanned:
batchSize = 1000

# print("from_block: ",from_block)

txSQL = "INSERT INTO transaction(block_number,event,account_address,recipient_address,amount,tx_hash,created_at,contract_id,coin_id) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s) "
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
                try:
                    depositTimeStamp = w3.eth.get_block(depositEvents[i].blockNumber).timestamp
                except:
                    # Assign a zero value if the timestamp method fails on Hyperspace
                    depositTimeStamp = 00000000
                #print(depositTimeStamp)

                # Transaction logs
                depositTxList = []
                depositTxList.append(str(depositEvents[i].blockNumber))
                depositTxList.append(str(depositEvents[i].event))
                depositTxList.append(str(depositEvents[i].args.account))
                depositTxList.append(str(depositEvents[i].address))
                depositTxList.append(str(depositEvents[i].args.amount/ 10 ** 18))
                depositTxList.append(str(depositEvents[i].transactionHash.hex()))
                depositTxList.append(str(depositTimeStamp))
                depositTxList.append(contract_id_val)
                depositTxList.append(coin_id_val)

                try:
                    mycursor.execute(txSQL,depositTxList)
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
        spaceCreatedEventSize = len(spaceCreatedEvent)
        i = 0
        blocknumInit = 0

        while i < spaceCreatedEventSize:
            # print(i)
            
            if blocknumInit != spaceCreatedEvent[i].blockNumber:
                try:
                    spaceCreatedTimeStamp = w3.eth.get_block(spaceCreatedEvent[i].blockNumber).timestamp
                except:
                    # Assign a zero value if the timestamp method fails on Hyperspace
                    spaceCreatedTimeStamp = 00000000

                # Tx logs:
                txHash = spaceCreatedEvent[i].transactionHash.hex()
                txInputDecoded = w3.eth.get_transaction_receipt(txHash)
                spaceCreatedTxLogs = txInputDecoded.logs[0]
                # result = dict(logs[0].args)
                # tx_data = json.dumps(result, cls=HexJsonEncoder)
                # print("logs: ",logs[0].transactionIndex)
                # print("JSON str: ",tx_json)

                # Transaction logs
                spaceCreatedTxList = []
                spaceCreatedTxList.append(str(spaceCreatedEvent[i].blockNumber))
                spaceCreatedTxList.append(str(spaceCreatedEvent[i].event))
                spaceCreatedTxList.append(str(spaceCreatedEvent[i].args.owner))
                spaceCreatedTxList.append(str(spaceCreatedEvent[i].address))
                spaceCreatedTxList.append(str(spaceCreatedEvent[i].args.price/ 10 ** 18))
                spaceCreatedTxList.append(str(spaceCreatedEvent[i].transactionHash.hex()))
                spaceCreatedTxList.append(str(spaceCreatedTimeStamp))
                spaceCreatedTxList.append(contract_id_val)
                spaceCreatedTxList.append(coin_id_val)
                
                # event_logs:
                spaceCreatedEventList = []
                spaceCreatedEventList.append(str(spaceCreatedTxLogs.address))
                spaceCreatedEventList.append(str(spaceCreatedEvent[i].event))
                spaceCreatedEventList.append(spaceCreatedTxLogs.data)
                spaceCreatedEventList.append(str(spaceCreatedTxLogs.topics))
                spaceCreatedEventList.append(str(spaceCreatedTxLogs.logIndex))
                spaceCreatedEventList.append(str(spaceCreatedTxLogs.removed))

                try:
                    mycursor.execute(txSQL,spaceCreatedTxList)
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
                # print("expiry_exted block: ",expiryExtendedEvent[i].blockNumber)
                # print("Expiry extended event: ", expiryExtendedEvent[i])
                try:
                    expiryExtendedTimeStamp = w3.eth.get_block(expiryExtendedEvent[i].blockNumber).timestamp
                    # print(expiryExtendedTimeStamp)
                except:
                    expiryExtendedTimeStamp = 00000000
               
                # Tx logs:
                txHash = expiryExtendedEvent[i].transactionHash.hex()
                txInputDecoded = w3.eth.getTransactionReceipt(txHash)
                expiryExtendedTxLogs = txInputDecoded.logs[0]
                # print("txInputDecoded: ",txInputDecoded)
                # print("expiryExtendedTxLogs: ",expiryExtendedTxLogs)

                # logs = contract.events.ExpiryExtended().processReceipt(txInputDecoded)
                # result = dict(logs[0].args)
                # tx_data = json.dumps(result, cls=HexJsonEncoder)

                # Transaction logs
                expiryExtendedTxList = []
                expiryExtendedTxList.append(str(expiryExtendedEvent[i].blockNumber))
                expiryExtendedTxList.append(str(expiryExtendedEvent[i].event))
                expiryExtendedTxList.append(str(txInputDecoded['from']))
                expiryExtendedTxList.append(str(expiryExtendedEvent[i].address))
                expiryExtendedTxList.append(str(expiryExtendedEvent[i].args.price/ 10 ** 18))
                expiryExtendedTxList.append(str(expiryExtendedEvent[i].transactionHash.hex()))
                expiryExtendedTxList.append(str(expiryExtendedTimeStamp))
                expiryExtendedTxList.append(contract_id_val)
                expiryExtendedTxList.append(coin_id_val)

                # event_logs:
                expiryExtendedEventList = []
                expiryExtendedEventList.append(str(expiryExtendedTxLogs.address))
                expiryExtendedEventList.append(str(expiryExtendedEvent[i].event))
                expiryExtendedEventList.append(expiryExtendedTxLogs.data)
                expiryExtendedEventList.append(str(expiryExtendedTxLogs.topics))
                expiryExtendedEventList.append(str(expiryExtendedTxLogs.logIndex))
                expiryExtendedEventList.append(str(expiryExtendedTxLogs.removed))

                try:
                    mycursor.execute(txSQL,expiryExtendedTxList)
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
                try:
                    hardwarePriceChangedTimeStamp = w3.eth.get_block(hardwarePriceChangedEvent[i].blockNumber).timestamp
                except:
                    hardwarePriceChangedTimeStamp = 00000000

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

                # Transaction logs
                hardwarePriceChangedTxList = []
                hardwarePriceChangedTxList.append(str(hardwarePriceChangedEvent[i].blockNumber))
                hardwarePriceChangedTxList.append(str(hardwarePriceChangedEvent[i].event))
                hardwarePriceChangedTxList.append(str(txInputDecoded['from']))
                hardwarePriceChangedTxList.append(str(hardwarePriceChangedEvent[i].address))
                hardwarePriceChangedTxList.append(str(hardwarePriceChangedEvent[i].args.price/ 10 ** 18))
                hardwarePriceChangedTxList.append(str(hardwarePriceChangedEvent[i].transactionHash.hex()))
                hardwarePriceChangedTxList.append(str(hardwarePriceChangedTimeStamp))
                hardwarePriceChangedTxList.append(contract_id_val)
                hardwarePriceChangedTxList.append(coin_id_val)

                # event_logs:
                hardwarePriceChangedList = []
                hardwarePriceChangedList.append(str(hardwarePriceChangedTxLogs.address))
                hardwarePriceChangedList.append(str(hardwarePriceChangedEvent[i].event))
                hardwarePriceChangedList.append(hardwarePriceChangedTxLogs.data)
                hardwarePriceChangedList.append(str(hardwarePriceChangedTxLogs.topics))
                hardwarePriceChangedList.append(str(hardwarePriceChangedTxLogs.logIndex))
                hardwarePriceChangedList.append(str(hardwarePriceChangedTxLogs.removed))

                try:
                    mycursor.execute(txSQL,hardwarePriceChangedTxList)
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
updateLastBlock = "UPDATE network SET last_scan_block_number_payment = (%s) WHERE id=(%s)"
toBlkList = []
toBlkList.append(target_block.number)
toBlkList.append(network_id)
mycursor.execute(updateLastBlock,toBlkList)
# print(toBlkList)
mydb.commit()
