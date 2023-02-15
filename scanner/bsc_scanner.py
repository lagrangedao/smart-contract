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

# Block on which the contract was deployed:
from_block = 27243037
target_block = w3.eth.get_block('latest')
# Block chunk to be scanned:
batchSize = 1000

sql = "INSERT INTO transaction(block_number,event,account_address,recipient_address,amount,tx_hash,created_at,contract_id,coin_id) VALUES "

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
                
                depositTimeStamp = w3.eth.get_block(depositEvents[i].blockNumber).timestamp
                # print(depositEvents[i].blockNumber,
                # depositEvents[i].event,
                # depositEvents[i].args.account,
                # depositEvents[i].args.amount,
                # depositEvents[i].transactionHash.hex())

                val = "(" + str(depositEvents[i].blockNumber) + ", '" + str(depositEvents[i].event) + "', '" + str(depositEvents[i].args.account) + "', '" + str(depositEvents[i].address) + "', " + str(depositEvents[i].args.amount/ 10 ** 18) + ", '" + str(depositEvents[i].transactionHash.hex()) + "', '" + str(depositTimeStamp) + "', " + "1, " + "1" + ")"
                # val2 = "(" + str(depositEvents[i].blockNumber) + ", '" + str(depositEvents[i].event) + "', '" + str(depositEvents[i].args.account) + "', '" + str(depositEvents[i].address) + "', " + str(depositEvents[i].args.amount/ 10 ** 18) + ", '" + str(depositEvents[i].transactionHash.hex()) + "', " + "1, " + "1" + ")"
                sqlCommand = sql + val

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