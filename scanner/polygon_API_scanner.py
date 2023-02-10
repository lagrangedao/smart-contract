from web3 import Web3
from decouple import config
from web3.middleware import geth_poa_middleware
import requests

polygon_url = config('POLYGON_URL')
API_KEY = config('API_KEY')

# HTTPProvider:
w3 = Web3(Web3.HTTPProvider(polygon_url))
w3.middleware_onion.inject(geth_poa_middleware, layer=0)

# res = requests.get('https://api.polygonscan.com/api?module=account&action=txlist&address=0xA1f32c758c4324cC3070A3AA107C4dC7DdFe1a6f&startblock=38542683&endblock=latest&sort=asc&API_KEY=Z4PKKUT2I43FNR8JQMCQS8QXV6D2G6ZBQB')

# Config: 
startblock = "32818038"
endblock = "latest"

# SwanPayment contract (Polygon mainnet)
CONTRACT_ADDRESS = '0xA1f32c758c4324cC3070A3AA107C4dC7DdFe1a6f'
ABI = '[ { "anonymous": false, "inputs": [ { "indexed": false, "internalType": "string", "name": "id", "type": "string" }, { "indexed": false, "internalType": "address", "name": "token", "type": "address" }, { "indexed": false, "internalType": "uint256", "name": "amount", "type": "uint256" }, { "indexed": false, "internalType": "address", "name": "owner", "type": "address" } ], "name": "ExpirePayment", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "internalType": "uint8", "name": "version", "type": "uint8" } ], "name": "Initialized", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "internalType": "string", "name": "id", "type": "string" }, { "indexed": false, "internalType": "address", "name": "token", "type": "address" }, { "indexed": false, "internalType": "uint256", "name": "lockedFee", "type": "uint256" }, { "indexed": false, "internalType": "uint256", "name": "minPayment", "type": "uint256" }, { "indexed": false, "internalType": "address", "name": "recipient", "type": "address" }, { "indexed": false, "internalType": "uint256", "name": "deadline", "type": "uint256" }, { "indexed": false, "internalType": "uint256", "name": "size", "type": "uint256" }, { "indexed": false, "internalType": "uint8", "name": "copyLimit", "type": "uint8" } ], "name": "LockPayment", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "internalType": "string", "name": "cid", "type": "string" }, { "indexed": false, "internalType": "address", "name": "owner", "type": "address" }, { "indexed": false, "internalType": "uint256", "name": "amount", "type": "uint256" } ], "name": "Refund", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "internalType": "string", "name": "dealId", "type": "string" }, { "indexed": false, "internalType": "string", "name": "network", "type": "string" }, { "indexed": false, "internalType": "address", "name": "recipient", "type": "address" } ], "name": "UnlockCarPayment", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "internalType": "string", "name": "id", "type": "string" }, { "indexed": false, "internalType": "address", "name": "token", "type": "address" }, { "indexed": false, "internalType": "uint256", "name": "cost", "type": "uint256" }, { "indexed": false, "internalType": "uint256", "name": "restToken", "type": "uint256" }, { "indexed": false, "internalType": "address", "name": "recipient", "type": "address" }, { "indexed": false, "internalType": "address", "name": "owner", "type": "address" } ], "name": "UnlockPayment", "type": "event" }, { "inputs": [], "name": "NATIVE_TOKEN", "outputs": [ { "internalType": "address", "name": "", "type": "address" } ], "stateMutability": "view", "type": "function" }, { "inputs": [ { "internalType": "string", "name": "cId", "type": "string" } ], "name": "getLockedPaymentInfo", "outputs": [ { "components": [ { "internalType": "string", "name": "id", "type": "string" }, { "internalType": "address", "name": "token", "type": "address" }, { "internalType": "uint256", "name": "minPayment", "type": "uint256" }, { "internalType": "uint256", "name": "lockedFee", "type": "uint256" }, { "internalType": "address", "name": "owner", "type": "address" }, { "internalType": "address", "name": "recipient", "type": "address" }, { "internalType": "uint256", "name": "deadline", "type": "uint256" }, { "internalType": "bool", "name": "_isExisted", "type": "bool" }, { "internalType": "uint256", "name": "size", "type": "uint256" }, { "internalType": "uint8", "name": "copyLimit", "type": "uint8" }, { "internalType": "uint256", "name": "blockNumber", "type": "uint256" } ], "internalType": "struct IPaymentMinimal.TxInfo", "name": "tx", "type": "tuple" } ], "stateMutability": "view", "type": "function" }, { "inputs": [ { "internalType": "address", "name": "owner", "type": "address" }, { "internalType": "address", "name": "ERC20_TOKEN", "type": "address" }, { "internalType": "address", "name": "oracle", "type": "address" }, { "internalType": "address", "name": "priceFeed", "type": "address" }, { "internalType": "address", "name": "chainlinkOracle", "type": "address" } ], "name": "initialize", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "components": [ { "internalType": "string", "name": "id", "type": "string" }, { "internalType": "uint256", "name": "minPayment", "type": "uint256" }, { "internalType": "uint256", "name": "amount", "type": "uint256" }, { "internalType": "uint256", "name": "lockTime", "type": "uint256" }, { "internalType": "address", "name": "recipient", "type": "address" }, { "internalType": "uint256", "name": "size", "type": "uint256" }, { "internalType": "uint8", "name": "copyLimit", "type": "uint8" } ], "internalType": "struct IPaymentMinimal.lockPaymentParam", "name": "param", "type": "tuple" } ], "name": "lockTokenPayment", "outputs": [ { "internalType": "bool", "name": "", "type": "bool" } ], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "internalType": "string[]", "name": "cidList", "type": "string[]" } ], "name": "refund", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "internalType": "address", "name": "chainlinkOracle", "type": "address" } ], "name": "setChainlinkOracle", "outputs": [ { "internalType": "bool", "name": "", "type": "bool" } ], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "internalType": "address", "name": "oracle", "type": "address" } ], "name": "setOracle", "outputs": [ { "internalType": "bool", "name": "", "type": "bool" } ], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "internalType": "address", "name": "priceFeed", "type": "address" } ], "name": "setPriceFeed", "outputs": [ { "internalType": "bool", "name": "", "type": "bool" } ], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "internalType": "string", "name": "dealId", "type": "string" }, { "internalType": "string", "name": "network", "type": "string" }, { "internalType": "address", "name": "recipient", "type": "address" } ], "name": "unlockCarPayment", "outputs": [ { "internalType": "bool", "name": "", "type": "bool" } ], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "components": [ { "internalType": "string", "name": "id", "type": "string" }, { "internalType": "string", "name": "orderId", "type": "string" }, { "internalType": "string", "name": "dealId", "type": "string" }, { "internalType": "uint256", "name": "amount", "type": "uint256" }, { "internalType": "address", "name": "recipient", "type": "address" } ], "internalType": "struct IPaymentMinimal.unlockPaymentParam", "name": "param", "type": "tuple" } ], "name": "unlockTokenPayment", "outputs": [ { "internalType": "bool", "name": "", "type": "bool" } ], "stateMutability": "nonpayable", "type": "function" } ]'

# SwanPayment contract object
contract = w3.eth.contract(address=Web3.toChecksumAddress(CONTRACT_ADDRESS), abi=ABI)

# Methods:
methodDict = {
    "0xf4d98717": "lockTokenPayment",
    "0x7d29985b": "refund",
    "0xee4128f6": "unlockCarPayment",
    "0x724e78da": "setPriceFeed",
    "0x7a9b0412": "setChainlinkOracle"
}

# lockTokenPayment = '0xf4d98717' # lockTokenPayment(tuple param)
# refund = '0x7d29985b' # refund(string[] bidTokens)
# unlockCarPayment = '0xee4128f6' # unlockCarPayment(string dealId,string network,address recipient)
# setPriceFeed(address priceFeed_)
# setChainlinkOracle(address oracle)

resDict = {
    "0": "failed",
    "1": "success"
}

transactionResults = requests.get( "https://api.polygonscan.com/api" 
    + "?module=account"
    + "&action=txlist"
    + "&address=" + CONTRACT_ADDRESS
    + "&startblock=" + startblock
    + "&endblock=" + endblock
    + "&sort=asc"
    + "&API_KEY=" + API_KEY )

resJSON = transactionResults.json()["result"]

for i in resJSON:
    if(i["methodId"] == "0xf4d98717"):
        # receipt = w3.eth.get_transaction_receipt(i["hash"])
        # decodedEvents = contract.events.LockPayment.processReceipt(receipt)
        # decodeParams = contract.decode_function_input(i["input"])
        # print(decodedEvents)
        print(i["blockNumber"],resDict[i["txreceipt_status"]], i["timeStamp"], methodDict[i["methodId"]])
    #print(i)
    #print(i["blockNumber"],resDict[i["txreceipt_status"]], i["timeStamp"], methodDict[i["methodId"]])

# lockpayment: {'blockNumber': '38542683', 'timeStamp': '1674723650', 'hash': '0xbb4e80a1f9272fd57c844b6c3c609658a1ba0124f7c9c3a3cd9920fa1c3111c5', 'nonce': '2', 'blockHash': '0x496e17a949d4f52b872c4addaa373e7643c7db7b09256b2e89abe00bda13de10', 'transactionIndex': '66', 'from': '0x564d74c420c66dd2e29e795ebe381f9462addb46', 'to': '0xa1f32c758c4324cc3070a3aa107c4dc7ddfe1a6f', 'value': '0', 'gas': '8000000', 'gasPrice': '62666870994', 'isError': '0', 'txreceipt_status': '1', 'input': '0xf4d98717000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000007e9000000000000000000000000007042d0a8f7ed7d6051fd7032515338f59ff872b2000000000000000000000000000000000000000000000000000000000000a0f50000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000005231303437653036642d656532382d346338312d386239652d373565363065336232626231516d644a5172376b4a3864596f6b6775344e4e7952466f59476133646d576a4b65794235656377564c58413251310000000000000000000000000000', 'CONTRACT_ADDRESS': '', 'cumulativeGasUsed': '12999772', 'gasUsed': '300957', 'confirmations': '57733', 'methodId': '0xf4d98717', 'functionName': 'lockTokenPayment(tuple param)'}
# refund: {'blockNumber': '38005920', 'timeStamp': '1673571158', 'hash': '0x304ebdf4b21730f8d51560478023d3780d328fbb49c63ff2627c2ad2bd5e68b4', 'nonce': '6039', 'blockHash': '0x316c2667ea912f7a79318b1c64a55ee8f869ec6b79b7e333f25a2539b87e95cf', 'transactionIndex': '44', 'from': '0xd44cde0f3beef47af166fc763b52977a43bf8fe7', 'to': '0xa1f32c758c4324cc3070a3aa107c4dc7ddfe1a6f', 'value': '0', 'gas': '8000000', 'gasPrice': '35890376020', 'isError': '0', 'txreceipt_status': '1', 'input': '0x7d29985b00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000005264313765666630622d316138652d343566612d626331322d666464613131353066313864516d5241786462624d50665462367a5874617552546b6d504b734c3267454d4d475841474244695967626769324e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005264303433306638312d663934392d343064342d616565392d353239633765626230373061516d5241786462624d50665462367a5874617552546b6d504b734c3267454d4d475841474244695967626769324e0000000000000000000000000000', 'CONTRACT_ADDRESS': '', 'cumulativeGasUsed': '7791151', 'gasUsed': '44998', 'confirmations': '594496', 'methodId': '0x7d29985b', 'functionName': 'refund(string[] bidTokens)'}