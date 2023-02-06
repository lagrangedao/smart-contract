from web3 import Web3
from decouple import config
from web3.middleware import geth_poa_middleware
import requests

# Config: 
startBlock = "26840271"
endblock = "latest"

# SpacePayment contract address
CONTRACT_ADDRESS = '0x724c478c880104bbfD40eddD241675B12751dC2d'
API_KEY = "5JZCBMKVI3P4CUFAZM5KQW6AQM14BRRYEI"

transactionResults = requests.get( "https://api-testnet.bscscan.com/api?module=account&action=txlist"
    + "&address=" + CONTRACT_ADDRESS
    + "&startblock=" + startBlock
    + "&endblock=" + endblock
    + "&sort=asc"
    + "&apikey=" + API_KEY )

#resJSON = transactionResults.json()["result"]

print(transactionResults)
