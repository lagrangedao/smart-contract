from web3 import Web3
from decouple import config
from web3.middleware import geth_poa_middleware
from web3.contract import ContractEvent
import time
import mysql.connector
import json
from hexbytes import HexBytes

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
from_block = 108401 #lastScannedBlock[0][0] + 1
target_block = w3.eth.get_block('latest')
# Block chunk to be scanned:
batchSize = 1000

print("from_block: ",from_block)

txSQL = "INSERT INTO transaction(block_number,event,account_address,recipient_address,amount,tx_hash,contract_id,coin_id) VALUES "
logSQL = "INSERT INTO event_logs(address,name,data,log_index,removed) VALUES "

class HexJsonEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, HexBytes):
            return obj.hex()
        return super().default(obj)

while from_block < target_block.number:
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

                txHash = depositEvents[i].transactionHash.hex()
                txInputDecoded = w3.eth.getTransactionReceipt(txHash)
                #print("txInputDecoded: ",txInputDecoded)
                logs = contract.events.Deposit().processReceipt(txInputDecoded)

                result = dict(logs[0].args)
                tx_data = json.dumps(result, cls=HexJsonEncoder)

                # val = "(" + str(depositEvents[i].blockNumber) + ", '" + str(depositEvents[i].event) + "', '" + str(depositEvents[i].args.account) + "', '" + str(depositEvents[i].address) + "', " + str(depositEvents[i].args.amount/ 10 ** 18) + ", '" + str(depositEvents[i].transactionHash.hex()) + "', '" + str(depositTimeStamp) + "')"
                txVal = "(" + str(depositEvents[i].blockNumber) + ", '" + str(depositEvents[i].event) + "', '" + str(depositEvents[i].args.account) + "', '" + str(depositEvents[i].address) + "', " + str(depositEvents[i].args.amount/ 10 ** 18) + ", '" + str(depositEvents[i].transactionHash.hex()) + "', " + "1, " + "1" + ")"
                sqlCommand = txSQL + txVal

                txLogVal = "('" + str(logs[0].address) + "', '" + str(depositEvents[i].event) + "', '" + tx_data + "', '" + str(logs[0].logIndex) + "', '" + "False" + "')"
                logCommand = logSQL + txLogVal

                try:
                    mycursor.execute(sqlCommand)
                    mycursor.execute(logCommand)
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
                # Tx logs:
                txHash = spaceCreatedEvent[i].transactionHash.hex()
                txInputDecoded = w3.eth.getTransactionReceipt(txHash)
                logs = contract.events.SpaceCreated().processReceipt(txInputDecoded)
                result = dict(logs[0].args)
                tx_data = json.dumps(result, cls=HexJsonEncoder)
                # print("logs: ",logs[0].transactionIndex)
                # print("JSON str: ",tx_json)

                txVal = "(" + str(spaceCreatedEvent[i].blockNumber) + ", '" + str(spaceCreatedEvent[i].event) + "', '" + str(spaceCreatedEvent[i].args.owner) + "', '" + str(spaceCreatedEvent[i].address) + "', " + str(spaceCreatedEvent[i].args.price/ 10 ** 18) + ", '" + str(spaceCreatedEvent[i].transactionHash.hex()) + "', " + "1, " + "1" + ")"
                sqlCommand = txSQL + txVal
                
                txLogVal = "('" + str(logs[0].address) + "', '" + str(spaceCreatedEvent[i].event) + "', '" + tx_data + "', '" + str(logs[0].logIndex) + "', '" + "False" + "')"
                logCommand = logSQL + txLogVal
                # print(logCommand)

                try:
                    mycursor.execute(sqlCommand)
                    mycursor.execute(logCommand)
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
            # AttributeDict({'args': AttributeDict({'id': 1, 'expiryBlock': 177177, 'price': 0}), 'event': 'ExpiryExtended', 'logIndex': 0, 'transactionIndex': 0, 'transactionHash': HexBytes('0xa26eacb33ab18ad213a4d423a384138d9f8bca0ee4edc24f947d958820510d5b'), 'address': '0x82D937426F43e99DA6811F167eCFB0103cd07E6B', 'blockHash': HexBytes('0x64c7ef3520d953682444605a305c40b6f8c4bbd58217aed0db42ca5a3ff178c5'), 'blockNumber': 108366})
            # AttributeDict({'chainId': '0xc45', 'nonce': 67, 'hash': HexBytes('0xa26eacb33ab18ad213a4d423a384138d9f8bca0ee4edc24f947d958820510d5b'), 'blockHash': HexBytes('0x64c7ef3520d953682444605a305c40b6f8c4bbd58217aed0db42ca5a3ff178c5'), 'blockNumber': 108366, 'transactionIndex': 0, 'from': '0xA878795d2C93985444f1e2A077FA324d59C759b0', 'to': '0x82D937426F43e99DA6811F167eCFB0103cd07E6B', 'value': 0, 'type': '0x2', 'input': '0x1df8c923000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000003e8', 'gas': 15066110, 'maxFeePerGas': 250000000000, 'maxPriorityFeePerGas': 5000000000, 'accessList': [], 'v': 1, 'r': HexBytes('0x86ad00cd837d10acc58144b17f8c55bef6b3456cb4bd0ae19f0b7df36e6918a0'), 's': HexBytes('0x28d7f8188363294f317a20055122baff076b8379adf108dd261c6f52d87be569')})
            txHash = expiryExtendedEvent[i].transactionHash.hex()
            txInputDecoded = w3.eth.get_transaction(txHash)
            # print(expiryExtendedEvent[i])
            if blocknumInit != expiryExtendedEvent[i].blockNumber:
                # Tx logs:
                # txHash = expiryExtendedEvent[i].transactionHash.hex()
                # txInputDecoded = w3.eth.getTransactionReceipt(txHash)
                logs = contract.events.ExpiryExtended().processReceipt(txInputDecoded)
                result = dict(logs[0].args)
                tx_data = json.dumps(result, cls=HexJsonEncoder)

                txVal = "(" + str(expiryExtendedEvent[i].blockNumber) + ", '" + str(expiryExtendedEvent[i].event) + "', '" + str(txInputDecoded['from']) + "', '" + str(expiryExtendedEvent[i].address) + "', " + str(expiryExtendedEvent[i].args.price/ 10 ** 18) + ", '" + str(expiryExtendedEvent[i].transactionHash.hex()) + "', " + "1, " + "1" + ")"
                sqlCommand = txSQL + txVal

                txLogVal = "('" + str(logs[0].address) + "', '" + str(expiryExtendedEvent[i].event) + "', '" + tx_data + "', '" + str(logs[0].logIndex) + "', '" + "False" + "')"
                logCommand = logSQL + txLogVal

                try:
                    mycursor.execute(sqlCommand)
                    mycursor.execute(logCommand)
                except mydb.Error as e:
                    print(e)

                mydb.commit()
                print(expiryExtendedEvent[i].blockNumber,mycursor.rowcount, "expiryExtendedEvent record inserted.")

            blocknumInit = expiryExtendedEvent[i].blockNumber
            i = i+1

    if hardwarePriceChangedEvent != ():
        # (AttributeDict({'args': AttributeDict({'id': 1, 'owner': '0xA878795d2C93985444f1e2A077FA324d59C759b0', 'hardwareType': 1, 'expiryBlock': 67811, 'price': 0}), 'event': 'SpaceCreated', 'logIndex': 0, 'transactionIndex': 0, 'transactionHash': HexBytes('0x35df469992eafcfac50cb003a047f806c21877d6a3017385ee8a17f395cd7bb8'), 'address': '0x82D937426F43e99DA6811F167eCFB0103cd07E6B', 'blockHash': HexBytes('0x9a01e9b4500af9ae2aa3194b60a9d4b816e6b183141b71ab519daca0ac30be95'), 'blockNumber': 67711}), AttributeDict({'args': AttributeDict({'id': 2, 'owner': '0xA878795d2C93985444f1e2A077FA324d59C759b0', 'hardwareType': 2, 'expiryBlock': 67728, 'price': 10000000000000000000}), 'event': 'SpaceCreated', 'logIndex': 0, 'transactionIndex': 0, 'transactionHash': HexBytes('0xb6a5910a8aba99c47cd2d408e00a8de08d0ee1a5eee1936813c005bc47bc3633'), 'address': '0x82D937426F43e99DA6811F167eCFB0103cd07E6B', 'blockHash': HexBytes('0x9dd3cb3d720479a8dcea08ded060171fd23bafde5bac666aa4e504c4ae8e0de2'), 'blockNumber': 67718}))
        hardwarePriceChangedEventSize = len(hardwarePriceChangedEvent)
        i = 0
        blocknumInit = 0
    

        while i < hardwarePriceChangedEventSize:
            # print(i)
            txHash = hardwarePriceChangedEvent[i].transactionHash.hex()
            txInputDecoded = w3.eth.get_transaction(txHash)

            if blocknumInit != hardwarePriceChangedEvent[i].blockNumber:
                logs = contract.events.HardwarePriceChanged().processReceipt(txInputDecoded)
                result = dict(logs[0].args)
                tx_data = json.dumps(result, cls=HexJsonEncoder)

                txVal = "(" + str(hardwarePriceChangedEvent[i].blockNumber) + ", '" + str(hardwarePriceChangedEvent[i].event) + "', '" + str(txInputDecoded['from']) + "', '" + str(hardwarePriceChangedEvent[i].address) + "', " + str(hardwarePriceChangedEvent[i].args.price/ 10 ** 18) + ", '" + str(hardwarePriceChangedEvent[i].transactionHash.hex()) + "', " + "1, " + "1" + ")"
                sqlCommand = txSQL + txVal

                txLogVal = "('" + str(logs[0].address) + "', '" + str(hardwarePriceChangedEvent[i].event) + "', '" + tx_data + "', '" + str(logs[0].logIndex) + "', '" + "False" + "')"
                logCommand = logSQL + txLogVal

                try:
                    mycursor.execute(sqlCommand)
                    mycursor.execute(logCommand)
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

#txInputDecoded:  AttributeDict({'transactionHash': HexBytes('0xa0ac9595d821206e3775f66611dfcc8fc80a7a91d714274da1e7755b61b9e7e5'), 'transactionIndex': 0, 'blockHash': HexBytes('0xdb92b1931ad295ece36c12b02414088c71b5f62fc1553824188f88793294984f'), 'blockNumber': 113548, 'from': '0x96216849c49358B10257cb55b28eA603c874b05E', 'to': '0x82D937426F43e99DA6811F167eCFB0103cd07E6B', 'root': '0x0000000000000000000000000000000000000000000000000000000000000000', 'status': 1, 'contractAddress': None, 'cumulativeGasUsed': 0, 'gasUsed': 13042927, 'effectiveGasPrice': 6245016272, 'logsBloom': HexBytes('0x3f7fdcbffafdfebfd4973bdfeb531b294cbb6db13774b69d3fcfedd9feff43f32fcbdde6ebfcc58b4fff52e687f2fdffee975af0a67dd5f9f6b9da7b0fbfe736afbbfffddbee1fc3cbdb716a8f9ae963de7f75f1e5ffbe7cd769b53df390a1d7bd97447b7fdf8bf6197786bdacfaed1ee0d7fedef0bfddc90bbb7ad055fff9d9b5476447edf47f137f57ebf2e7d56f777ff1bef56bbb96ffa9775bff6f6f9993f2ba11f5719febb749eb93df6c7fde3be65d6ebfbed7fdd8a8fdd6ff16d0d73f970de552671127f77bec6fd1d8bfdbe74679fbcf9e7adafd7b9d19afbf986f977ef15b6db6d7c844dfbfdff6f9bef38fd9b7557db79f8affeffcfb5efb76f76e'), 
#'logs': [AttributeDict({'address': '0xCdB765D539637a4A6B434ea43C27eE0C05804B33', 'data': '0x0000000000000000000000000000000000000000000000000000000000000000', 'topics': [HexBytes('0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925'), HexBytes('0x00000000000000000000000096216849c49358b10257cb55b28ea603c874b05e'), HexBytes('0x00000000000000000000000082d937426f43e99da6811f167ecfb0103cd07e6b')], 'removed': False, 'logIndex': 0, 'transactionIndex': 0, 'transactionHash': HexBytes('0xa0ac9595d821206e3775f66611dfcc8fc80a7a91d714274da1e7755b61b9e7e5'), 'blockHash': HexBytes('0xdb92b1931ad295ece36c12b02414088c71b5f62fc1553824188f88793294984f'), 'blockNumber': 113548}), AttributeDict({'address': '0xCdB765D539637a4A6B434ea43C27eE0C05804B33', 'data': '0x0000000000000000000000000000000000000000000000000000000000000000', 'topics': [HexBytes('0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'), HexBytes('0x00000000000000000000000096216849c49358b10257cb55b28ea603c874b05e'), HexBytes('0x00000000000000000000000082d937426f43e99da6811f167ecfb0103cd07e6b')], 'removed': False, 'logIndex': 1, 'transactionIndex': 0, 'transactionHash': HexBytes('0xa0ac9595d821206e3775f66611dfcc8fc80a7a91d714274da1e7755b61b9e7e5'), 'blockHash': HexBytes('0xdb92b1931ad295ece36c12b02414088c71b5f62fc1553824188f88793294984f'), 'blockNumber': 113548}), AttributeDict({'address': '0x82D937426F43e99DA6811F167eCFB0103cd07E6B', 'data': '0x00000000000000000000000096216849c49358b10257cb55b28ea603c874b05e0000000000000000000000000000000000000000000000000000000000000000', 'topics': [HexBytes('0xe1fffcc4923d04b559f4d29a8bfc6cda04eb5b0d3c460751c2402c5c5cc9109c')], 'removed': False, 'logIndex': 2, 'transactionIndex': 0, 'transactionHash': HexBytes('0xa0ac9595d821206e3775f66611dfcc8fc80a7a91d714274da1e7755b61b9e7e5'), 'blockHash': HexBytes('0xdb92b1931ad295ece36c12b02414088c71b5f62fc1553824188f88793294984f'), 'blockNumber': 113548})], 'type': '0x2'})
