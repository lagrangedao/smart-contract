from web3 import Web3
from decouple import config
from web3.middleware import geth_poa_middleware
from web3.contract import ContractEvent
import time
import mysql.connector
import json
from hexbytes import HexBytes
import warnings

polygon_url = "https://polygon-mumbai.g.alchemy.com/v2/JpRokS66sMaDD680W2NWwqhLuqDC1f7l"

# MySQL DB:
mydb = mysql.connector.connect(
  host="localhost",
  user=config('DB_USER'),
  password=config('DB_PASSWORD'),
  database='nft_data'
)
mycursor = mydb.cursor()

# HTTPProvider:
w3 = Web3(Web3.HTTPProvider(polygon_url))
w3.middleware_onion.inject(geth_poa_middleware, layer=0)

# res = w3.isConnected()
# print("res: ",res)

# Chainlink Functions Data NFT (mumbai):
CF_CONTRACT_ADDRESS = '0xD81288579c13e26F621840B66aE16af1460ebB5a'
cf_AddrDict=[]
cf_AddrDict.append(CF_CONTRACT_ADDRESS)

# Chainlink Single-Oracle Data NFT (mumbai):
SO_CONTRACT_ADDRESS = '0x923AfAdE5d2c600b8650334af60D6403642c1bce'
so_AddrDict=[]
so_AddrDict.append(SO_CONTRACT_ADDRESS)

cf_abi_file = open('../contracts/abi/LagrangeChainlinkData.json')
so_abi_file = open('../contracts/abi/LagrangeChainlinkDataConsumer.json')
CF_ABI = json.load(cf_abi_file)
SO_ABI = json.load(so_abi_file)

# validate NFT contract address
# is_address_valid = w3.isAddress(CONTRACT_ADDRESS)
# print("isAddrValid: ",is_address_valid)

# Block on which the contract was deployed:
from_block = 34492518
target_block = w3.eth.get_block('latest') #34294743
# Block chunk to be scanned:
batchSize = 1000

updateOwnerCommand='UPDATE nft_ownership SET transfer_event_block = (%s), owner_address = (%s) WHERE nft_address = (%s) AND nft_ID=(%s)'

while from_block < target_block.number:
    # silence harmless warnings
    warnings.filterwarnings("ignore")

    toBlock = from_block + batchSize
    print(from_block,toBlock)

    cf_contract = w3.eth.contract(address=Web3.toChecksumAddress(CF_CONTRACT_ADDRESS), abi=CF_ABI)
    so_contract = w3.eth.contract(address=Web3.toChecksumAddress(SO_CONTRACT_ADDRESS), abi=SO_ABI)

    cfTransferEvents = cf_contract.events.Transfer.getLogs(fromBlock=from_block, toBlock=toBlock)
    soTransferEvents = so_contract.events.Transfer.getLogs(fromBlock=from_block, toBlock=toBlock)
    # print("cfTransferEvents: ",cfTransferEvents)
    # print("--------------------")
    # print("soTransferEvents: ",soTransferEvents)

    # eventOwnership = ContractEvent('OwnershipTransferred', abi=ABI)
    # eventLog=event.processLog(log)
    # print("event: ",eventLog)

    if cfTransferEvents !=():
        cfEventSize=len(cfTransferEvents)
        # print("cfEventSize: ", cfEventSize)
        i=0

        while i<cfEventSize:
            if cfTransferEvents[i].args["from"] != '0x0000000000000000000000000000000000000000':
                # prevOwner = cfTransferEvents[i].args["from"]

                tokenID = cfTransferEvents[i].args.tokenId

                cfUpdateParams=[]
                cfUpdateParams.append(cfTransferEvents[i].blockNumber)
                cfUpdateParams.append(cfTransferEvents[i].args.to)
                cfUpdateParams.append(CF_CONTRACT_ADDRESS)
                cfUpdateParams.append(tokenID)

                # print("cfUpdateParams: ",cfUpdateParams)
                
                mycursor.execute(updateOwnerCommand,cfUpdateParams)
                mydb.commit()
                print("Updated owner for NFT Address:",CF_CONTRACT_ADDRESS)

                # Get the previous owner's address
                # ownerAddressCommand="select owner_address from nft_ownership WHERE nft_address = (%s) "
                # mycursor.execute(ownerAddressCommand,cf_AddrDict)
                # ownerAddr = mycursor.fetchall()
                # print("NFT owner: ",ownerAddr[0][0])

                # print(cfTransferEvents[i].blockNumber)
                # print(cfTransferEvents[i].event)
                # print(cfTransferEvents[i].args["from"])
                # print(cfTransferEvents[i].args.to)
                # print(cfTransferEvents[i].args.tokenId)
                # print(cfTransferEvents[i].address)
            i=i+1

    if soTransferEvents != ():
        soEventSize=len(soTransferEvents)
        # print("soEventSize: ",soEventSize)
        i=0

        while i<soEventSize:
            if soTransferEvents[i].args["from"] != '0x0000000000000000000000000000000000000000':
                # prevOwner = cfTransferEvents[i].args["from"]

                tokenID = soTransferEvents[i].args.tokenId

                soUpdateParams=[]
                soUpdateParams.append(soTransferEvents[i].blockNumber)
                soUpdateParams.append(soTransferEvents[i].args.to)
                soUpdateParams.append(SO_CONTRACT_ADDRESS)
                soUpdateParams.append(tokenID)

                # print("soUpdateParams: ",soUpdateParams)
                
                mycursor.execute(updateOwnerCommand,soUpdateParams)
                mydb.commit()
                print("Updated owner for NFT Address:",SO_CONTRACT_ADDRESS)

            i=i+1

    from_block = from_block + batchSize + 1
    blockDiff = target_block.number - from_block

    # print("target_block: ",target_block.number)
    # print("batchSize: ",batchSize)
    # print("from_block ",from_block)
    # print("blockDiff: ",blockDiff)

    if(blockDiff < batchSize):
        batchSize = blockDiff
