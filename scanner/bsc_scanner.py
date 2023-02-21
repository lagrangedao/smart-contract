from web3 import Web3
from decouple import config
from web3.middleware import geth_poa_middleware
from web3.contract import ContractEvent
import time
import mysql.connector
import json

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

# SpacePayment contract address and ABI
CONTRACT_ADDRESS = '0x5DF166d2875c82f6f3B172e8eeBAbB87b627014c'
space_abi_file = open('../contracts/abi/SpacePayment.json')
ABI = json.load(space_abi_file)

# validate SpacePayment contract address
is_address_valid = w3.isAddress(CONTRACT_ADDRESS)
#print(is_address_valid)

lastScanBlockCommand = "select last_scan_block_number_payment from network WHERE id = 2"
mycursor.execute(lastScanBlockCommand)
lastScannedBlock = mycursor.fetchall()
# print(lastScannedBlock[0][0])

# Block on which the contract was deployed:
from_block = lastScannedBlock[0][0] + 1 #27243037
print(from_block)
target_block = w3.eth.get_block('latest')
print(target_block.number)

# Block chunk to be scanned:
batchSize = 1000

sqlQuery = "INSERT INTO transaction(block_number,event,account_address,recipient_address,amount,tx_hash,created_at,contract_id,coin_id) VALUES "

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
        # print("depositEventsSize ",depositEventsSize)

        i = 0
        blocknumInit = 0

        while i < depositEventsSize:
            # print(i)
            if blocknumInit != depositEvents[i].blockNumber:
                
                depositTimeStamp = w3.eth.get_block(depositEvents[i].blockNumber).timestamp
            
                # print(depositEvents[i].blockNumber,
                # depositEvents[i].event,
                # depositEvents[i].args.account,
                # depositEvents[i].args.amount,
                # depositEvents[i].transactionHash.hex())

                depositVal = "(" + str(depositEvents[i].blockNumber) + ", '" + str(depositEvents[i].event) + "', '" + str(depositEvents[i].args.account) + "', '" + str(depositEvents[i].address) + "', " + str(depositEvents[i].args.amount/ 10 ** 18) + ", '" + str(depositEvents[i].transactionHash.hex()) + "', '" + str(depositTimeStamp) + "', " + "2, " + "1" + ")"
                # val2 = "(" + str(depositEvents[i].blockNumber) + ", '" + str(depositEvents[i].event) + "', '" + str(depositEvents[i].args.account) + "', '" + str(depositEvents[i].address) + "', " + str(depositEvents[i].args.amount/ 10 ** 18) + ", '" + str(depositEvents[i].transactionHash.hex()) + "', " + "1, " + "1" + ")"
                sqlCommandDeposit = sqlQuery + depositVal

                try:
                    mycursor.execute(sqlCommandDeposit)
                    mydb.commit()
                    print(depositEvents[i].blockNumber,mycursor.rowcount, "deposit record inserted.")
                except:
                    print("Please check the deposit SQL command")

                # mydb.commit()
                # print(depositEvents[i].blockNumber,mycursor.rowcount, "deposit record inserted.")

            blocknumInit = depositEvents[i].blockNumber
            i = i+1

    if spaceCreatedEvent != ():
        # spaceCreatedEventSize = len(spaceCreatedEvent)
        spaceCreatedEventTimeStamp = w3.eth.get_block(spaceCreatedEvent[0].blockNumber).timestamp

        spaceCreatedEventVal = "(" + str(spaceCreatedEvent[0].blockNumber) + ", '" + str(spaceCreatedEvent[0].event) + "', '" + str(spaceCreatedEvent[0].args.owner) + "', '" + str(spaceCreatedEvent[0].address) + "', " + str(spaceCreatedEvent[0].args.price) + ", '" + str(spaceCreatedEvent[0].transactionHash.hex()) + "', '" + str(spaceCreatedEventTimeStamp) + "', " + "2, " + "1" + ")"
        sqlCommandSpaceCreated = sqlQuery + spaceCreatedEventVal

        try:
            mycursor.execute(sqlCommandSpaceCreated)
            mydb.commit()
            print(spaceCreatedEvent[0].blockNumber,mycursor.rowcount, "spaceCreated record inserted.")
        except:
            print("Please check the spaceCreated SQL command")
    
    if expiryExtendedEvent != ():
        # expiryExtendedEventSize = len(expiryExtendedEvent)
        expiryExtendedEventTimeStamp = w3.eth.get_block(expiryExtendedEvent[0].blockNumber).timestamp

        expiryExtendedEventVal = "(" + str(expiryExtendedEvent[0].blockNumber) + ", '" + str(expiryExtendedEvent[0].event) + "', '" + "NA" + "', '" + str(expiryExtendedEvent[0].address) + "', " + str(expiryExtendedEvent[0].args.price) + ", '" + str(expiryExtendedEvent[0].transactionHash.hex()) + "', '" + str(expiryExtendedEventTimeStamp) + "', " + "2, " + "1" + ")"
        sqlCommandExpiryExtendedEventVal = sqlQuery + expiryExtendedEventVal

        try:
            mycursor.execute(sqlCommandExpiryExtendedEventVal)
            mydb.commit()
            print(expiryExtendedEvent[0].blockNumber,mycursor.rowcount, "expiryExtended record inserted.")
        except:
            print("Please check the expiryExtended SQL command")


    if hardwarePriceChangedEvent != ():
        # hardwarePriceChangedEventSize = len(hardwarePriceChangedEvent)
        hardwarePriceChangedEventTimeStamp = w3.eth.get_block(hardwarePriceChangedEvent[0].blockNumber).timestamp

        hardwarePriceChangedEventVal = "(" + str(hardwarePriceChangedEvent[0].blockNumber) + ", '" + str(hardwarePriceChangedEvent[0].event) + "', '" + "Contract owner" + "', '" + str(hardwarePriceChangedEvent[0].address) + "', " + str(hardwarePriceChangedEvent[0].args.price/ 10 ** 18) + ", '" + str(hardwarePriceChangedEvent[0].transactionHash.hex()) + "', '" + str(hardwarePriceChangedEventTimeStamp) + "', " + "2, " + "1" + ")"
        sqlCommandhardwarePriceChangedEvent = sqlQuery + hardwarePriceChangedEventVal

        try:
            mycursor.execute(sqlCommandhardwarePriceChangedEvent)
            mydb.commit()
            print(hardwarePriceChangedEvent[0].blockNumber,mycursor.rowcount, "hardwarePriceChanged record inserted.")
        except:
            print("Please check the hardwarePriceChanged SQL command")

    from_block = from_block + batchSize + 1
    blockDiff = target_block.number - from_block

    # print("target_block: ",target_block.number)
    # print("batchSize: ",batchSize)
    # print("from_block ",from_block)
    # print("blockDiff: ",blockDiff)

    if(blockDiff < batchSize):
        batchSize = blockDiff

# Update last_scan_block
updateLastBlock = "UPDATE network SET last_scan_block_number_payment = (%s) WHERE id=2"
toBlkList = []
toBlkList.append(target_block.number)
mycursor.execute(updateLastBlock,toBlkList)
# print(toBlkList)
mydb.commit()

# if(lastBlockAfterScan != 0):
#     toBlkList.append(lastBlockAfterScan)
#     mycursor.execute(updateLastBlock,toBlkList)
#     print(toBlkList)
#     mydb.commit()
# else:
#     print("Please wait for some blocks to be mined")
