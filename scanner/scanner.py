from web3 import Web3
from decouple import config
from web3.middleware import geth_poa_middleware
from web3.contract import ContractEvent


polygon_url = config('POLYGON_URL')

# print(polygon_url)

# HTTPProvider:
w3 = Web3(Web3.HTTPProvider(polygon_url))
w3.middleware_onion.inject(geth_poa_middleware, layer=0)

res = w3.isConnected()

# FilSwan contract (Polygon mainnet)
CONTRACT_ADDRESS = '0xA1f32c758c4324cC3070A3AA107C4dC7DdFe1a6f'
ABI = '[ { "anonymous": false, "inputs": [ { "indexed": false, "internalType": "string", "name": "id", "type": "string" }, { "indexed": false, "internalType": "address", "name": "token", "type": "address" }, { "indexed": false, "internalType": "uint256", "name": "amount", "type": "uint256" }, { "indexed": false, "internalType": "address", "name": "owner", "type": "address" } ], "name": "ExpirePayment", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "internalType": "uint8", "name": "version", "type": "uint8" } ], "name": "Initialized", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "internalType": "string", "name": "id", "type": "string" }, { "indexed": false, "internalType": "address", "name": "token", "type": "address" }, { "indexed": false, "internalType": "uint256", "name": "lockedFee", "type": "uint256" }, { "indexed": false, "internalType": "uint256", "name": "minPayment", "type": "uint256" }, { "indexed": false, "internalType": "address", "name": "recipient", "type": "address" }, { "indexed": false, "internalType": "uint256", "name": "deadline", "type": "uint256" }, { "indexed": false, "internalType": "uint256", "name": "size", "type": "uint256" }, { "indexed": false, "internalType": "uint8", "name": "copyLimit", "type": "uint8" } ], "name": "LockPayment", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "internalType": "string", "name": "cid", "type": "string" }, { "indexed": false, "internalType": "address", "name": "owner", "type": "address" }, { "indexed": false, "internalType": "uint256", "name": "amount", "type": "uint256" } ], "name": "Refund", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "internalType": "string", "name": "dealId", "type": "string" }, { "indexed": false, "internalType": "string", "name": "network", "type": "string" }, { "indexed": false, "internalType": "address", "name": "recipient", "type": "address" } ], "name": "UnlockCarPayment", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "internalType": "string", "name": "id", "type": "string" }, { "indexed": false, "internalType": "address", "name": "token", "type": "address" }, { "indexed": false, "internalType": "uint256", "name": "cost", "type": "uint256" }, { "indexed": false, "internalType": "uint256", "name": "restToken", "type": "uint256" }, { "indexed": false, "internalType": "address", "name": "recipient", "type": "address" }, { "indexed": false, "internalType": "address", "name": "owner", "type": "address" } ], "name": "UnlockPayment", "type": "event" }, { "inputs": [], "name": "NATIVE_TOKEN", "outputs": [ { "internalType": "address", "name": "", "type": "address" } ], "stateMutability": "view", "type": "function" }, { "inputs": [ { "internalType": "string", "name": "cId", "type": "string" } ], "name": "getLockedPaymentInfo", "outputs": [ { "components": [ { "internalType": "string", "name": "id", "type": "string" }, { "internalType": "address", "name": "token", "type": "address" }, { "internalType": "uint256", "name": "minPayment", "type": "uint256" }, { "internalType": "uint256", "name": "lockedFee", "type": "uint256" }, { "internalType": "address", "name": "owner", "type": "address" }, { "internalType": "address", "name": "recipient", "type": "address" }, { "internalType": "uint256", "name": "deadline", "type": "uint256" }, { "internalType": "bool", "name": "_isExisted", "type": "bool" }, { "internalType": "uint256", "name": "size", "type": "uint256" }, { "internalType": "uint8", "name": "copyLimit", "type": "uint8" }, { "internalType": "uint256", "name": "blockNumber", "type": "uint256" } ], "internalType": "struct IPaymentMinimal.TxInfo", "name": "tx", "type": "tuple" } ], "stateMutability": "view", "type": "function" }, { "inputs": [ { "internalType": "address", "name": "owner", "type": "address" }, { "internalType": "address", "name": "ERC20_TOKEN", "type": "address" }, { "internalType": "address", "name": "oracle", "type": "address" }, { "internalType": "address", "name": "priceFeed", "type": "address" }, { "internalType": "address", "name": "chainlinkOracle", "type": "address" } ], "name": "initialize", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "components": [ { "internalType": "string", "name": "id", "type": "string" }, { "internalType": "uint256", "name": "minPayment", "type": "uint256" }, { "internalType": "uint256", "name": "amount", "type": "uint256" }, { "internalType": "uint256", "name": "lockTime", "type": "uint256" }, { "internalType": "address", "name": "recipient", "type": "address" }, { "internalType": "uint256", "name": "size", "type": "uint256" }, { "internalType": "uint8", "name": "copyLimit", "type": "uint8" } ], "internalType": "struct IPaymentMinimal.lockPaymentParam", "name": "param", "type": "tuple" } ], "name": "lockTokenPayment", "outputs": [ { "internalType": "bool", "name": "", "type": "bool" } ], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "internalType": "string[]", "name": "cidList", "type": "string[]" } ], "name": "refund", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "internalType": "address", "name": "chainlinkOracle", "type": "address" } ], "name": "setChainlinkOracle", "outputs": [ { "internalType": "bool", "name": "", "type": "bool" } ], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "internalType": "address", "name": "oracle", "type": "address" } ], "name": "setOracle", "outputs": [ { "internalType": "bool", "name": "", "type": "bool" } ], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "internalType": "address", "name": "priceFeed", "type": "address" } ], "name": "setPriceFeed", "outputs": [ { "internalType": "bool", "name": "", "type": "bool" } ], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "internalType": "string", "name": "dealId", "type": "string" }, { "internalType": "string", "name": "network", "type": "string" }, { "internalType": "address", "name": "recipient", "type": "address" } ], "name": "unlockCarPayment", "outputs": [ { "internalType": "bool", "name": "", "type": "bool" } ], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [ { "components": [ { "internalType": "string", "name": "id", "type": "string" }, { "internalType": "string", "name": "orderId", "type": "string" }, { "internalType": "string", "name": "dealId", "type": "string" }, { "internalType": "uint256", "name": "amount", "type": "uint256" }, { "internalType": "address", "name": "recipient", "type": "address" } ], "internalType": "struct IPaymentMinimal.unlockPaymentParam", "name": "param", "type": "tuple" } ], "name": "unlockTokenPayment", "outputs": [ { "internalType": "bool", "name": "", "type": "bool" } ], "stateMutability": "nonpayable", "type": "function" } ]'
CONTRACT_CREATION_BLOCK = 33017517

start_block = CONTRACT_CREATION_BLOCK
batchSize = 5000
latest_block = w3.eth.get_block('latest')

# SwanPayment contract
is_address_valid = w3.isAddress(CONTRACT_ADDRESS)

# print(res)

while start_block <  latest_block.number:
    toBlock = start_block + batchSize

    contract = w3.eth.contract(address=Web3.toChecksumAddress(CONTRACT_ADDRESS), abi=ABI)

    LockPaymentevents = contract.events.LockPayment.getLogs(fromBlock=start_block, toBlock=toBlock)
    Refundevents = contract.events.Refund.getLogs(fromBlock=start_block, toBlock=toBlock)
    UnlockCarPayment = contract.events.UnlockCarPayment.getLogs(fromBlock=start_block, toBlock=toBlock)
    UnlockPayment = contract.events.UnlockPayment.getLogs(fromBlock=start_block, toBlock=toBlock)


    # events = contract.events.LockPayment().getLogs.createFilter(fromBlock=start_block)

    if LockPaymentevents != () :
        print(LockPaymentevents[0].blockNumber, LockPaymentevents[0].event)
    elif Refundevents != () :
        print(Refundevents[0].blockNumber, Refundevents[0].event)
    elif UnlockCarPayment != () :
        print(UnlockCarPayment[0].blockNumber, UnlockCarPayment[0].event)
    elif UnlockPayment != () :
        print(UnlockPayment[0].blockNumber, UnlockPayment[0].event)

    start_block = start_block + batchSize

# https://api.polygonscan.com/api?module=account&action=txlist&address=0xA1f32c758c4324cC3070A3AA107C4dC7DdFe1a6f&startblock=32818037&endblock=38519147&sort=asc&apikey=Z4PKKUT2I43FNR8JQMCQS8QXV6D2G6ZBQB

