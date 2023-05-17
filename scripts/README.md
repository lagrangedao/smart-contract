# Lagrange Scripts

This folder contains Python scripts to interact with LagrangeDAO contracts

## Set up

### Install Packages:

```
pip install web3 python-dotenv
```

### Create your own .env

copy _.env.template_ to _.env_

```
wallet_address = " "
private_key = " "
rpc_endpoint = "https://polygon-rpc.com"
SQLALCHEMY_DATABASE_URI="mysql+pymysql://user:pass@127.0.0.1:3306/lagrange"
DOMAIN="127.0.0.1"
```

update the file with your own values.

### Before Running

The current `token_contract_address` and `space_contract_address` are deployed on the Hyperspace testnet. To deploy your own, follow the instructions in the `../hardhat` folder

You will need some LAD tokens to run the script successfully.

## Running

### Buy Space

Run the script:

```
python buy-space.py
```

Example output

```
Connected to blockchain, chain id is 80001. the latest block is 31,028,769

wallet address: 0xA878795d2C93985444f1e2A077FA324d59C759b0
account balance: 149,990,287.0 LAD

 0. CPU Only - 2 vCPU - 16 GiB - Free
 1. CPU Only - 8 vCPU - 32 GiB - 1 LAD per block
 2. Nvidia T4 - 4 vCPU - 15 GiB - 20 LAD per block
 3. Nvidia T4 - 8 vCPU - 30 GiB - 30 LAD per block
 4. Nvidia A10G - 4 vCPU - 15 GiB - 35 LAD per block
 5. Nvidia A10G - 12 vCPU - 46 GiB - 105 LAD per block

Select the hardware (#): 3
How many blocks: 3
Confirm purchasing hardware type 1 for 100 blocks (100 LAD)?
Ok [y/n]?y

depositing 100 LAD into contract...
transaction hash: 0x5ab4ab50af8e8b6eae450e212beb7e4d151d0f3697640f8d280e7b11f59182f7

purchasing space...
transaction hash: 0x21aa29a839d29a9ada0a331cfdd38eec5aabccd19b824a9da04b04966bd23514
```

### Mint NFT

Note: The current contract is deployed to the Polygon Mumbai network.

Run the script:

```
python mint.py
```

Before running, you will need a NFT to mint, upload a JSON file to IPFS containing an owner address property:

```
{
    ...,
    "owner": "0x...",
    ...
}
```

Example output

```
Connected to https://polygon-mumbai.g.alchemy.com/v2/JpRokS66sMaDD680W2NWwqhLuqDC1f7l, chain id is 80001. the latest block is 34,783,446

Your address: 0xc17ae0520803E715D020C03D29D452520D6aEbf9

NFT Metadata (IPFS URL): https://2d9999d121.calibration-swan-acl.filswan.com/ipfs/QmZEPZos8pExSSqfZwi4RKrLHUGBgQ5KsHMP3poyPMBomA

Confirm minting NFT of https://2d9999d121.calibration-swan-acl.filswan.com/ipfs/QmZEPZos8pExSSqfZwi4RKrLHUGBgQ5KsHMP3poyPMBomA?
Ok [y/n]?y

Minting...
Mint is completed. Transaction Hash: 0x042186563c2d5e22aa39b35c1218874001753d8b7f049f8e4b0c93f85ca3aff1
View on Block Explorer: https://mumbai.polygonscan.com/tx/0x042186563c2d5e22aa39b35c1218874001753d8b7f049f8e4b0c93f85ca3aff1
```

### Factory mint script:

Note: The current contract is deployed on the Sepolia testnet

1. Configure the `rpc_endpoint` to the Sepolia testnet in the .env file. Example:

```
rpc_endpoint = "https://eth-sepolia.public.blastapi.io"
```

2. Also, configure your `private_key` and `wallet_address` in the .env file.
3. Run the factory minting script:

```
python3 factory-mint.py
```

4. When prompted, input the IPFS uri.  
   Example: https://3b46ed854.acl.multichain.storage/ipfs/QmfWumvNSWTTXS6QTkmsEunDtUqGTwFyGNDp8bMCxxUK6y
