# Lagrange Contracts

1. `LagrangeDAOToken` is an ERC-20 contract
2. `LagrangePlatform` rewards users for uploading data and models to the Langrange Platform
3. `SpacePayment` allows users to purchase spaces
4. `Job Processor` allows users to create computing jobs and allows computing providers (CPs) to complete jobs, deposit and claim collateral.

## Addresses

### Hyperspace Testnet

| Contract     | Address                                    |
| ------------ | ------------------------------------------ |
| LADToken     | 0xCdB765D539637a4A6B434ea43C27eE0C05804B33 |
| SpacePayment | 0x82D937426F43e99DA6811F167eCFB0103cd07E6B |
| DataNFT      | 0xD32E5567BbAFcb001f6B847f2d3129147D4c5640 |

### Binance Testnet

| Contract     | Address                                    |
| ------------ | ------------------------------------------ |
| LADToken     | 0x05dD79893Aa2cFA754aEBb33398416F90590D5B1 |
| SpacePayment | 0x5DF166d2875c82f6f3B172e8eeBAbB87b627014c |

## Functions

## LagrangeDAOToken.sol

LagrangeDaoToken is a ERC-20 contract for LAD tokens, used to pay for spaces and computing over data. LAD has an 1B token cap with 15% initial mint.

- `initialize(address holder)` initially mint the 15% of token cap to the `holder` address

## LangrangePlatform.sol

Users will upload data and models to the server and call this contract to request the upload reward. The backend will verify the data/model is uploaded and reward the uploader.

- `rewardDataUpload(string wcid, uint size)`

The uploader gets rewarded 1 LAD if the data is under 1GB, otherwise they receive 0.5 LAD per GB. This emits a `DataUpload` event for the backend to verify.

- `rewardModelUpload(string wcid)`

The uploader gets rewarded 2 LAD for a model. This emits a `ModelUpload` event for the backend to verify.

- `withdraw(uint amount)` the owner can withdraw LAD tokens from the contract.

## SpacePayment.sol

Handles payment for spaces and manages their expiry blocks.

- `deposit(uint amount)` Users can deposit LAD into the contract, must call `approve` on the ERC-20 first.

- `balanceOf(address account)` get the account LAD balance in the contract

- `hardwareInfo(uint hardwareType)` get the `name` and `pricePerBlock` of a hardware type

- `buySpace(uint hardwareType, uint blocks)`

Users can purchase space with a numbered hardware type used for computing, as well as the number of blocks for duration

- `extendSpace(uint spaceId, uint blocks)` extends space by a number of blocks at the same hardware price

- `isExpired(uint spaceId)` checks the duration of the space with the current block number to see if the block is expired or not

- `spaceInfo(uint spaceId)` returns the space info such as the owner, the hardware type, and expiry block

- `changeHardware(uint hardwareType, string newName, uint newPrice)` the owner can change the hardware types

- `withdraw(uint amount)` the owner can withdraw LAD tokens from the contract.

# Data NFTs

A data NFT represents the copyright (or exclusive license against copyright) for a data asset on the blockchain. When a user publishes a dataset on Lagrange DAO, they can request a data NFT as part of the process. This data NFT is proof of your claim of base IP.

After uploading a dataset, the user can request their data NFT. This will trigger
Chainlink Functions to verify the user is the owner of the dataset (according to Lagrange DAO). After verification is complete, the user can claim their data NFT.

![](./datanft-diagram.png)

### Sepolia Testnet

| Contract       | Address                                    |
| -------------- | ------------------------------------------ |
| DataNFTFactory | 0x26FE0adD600965518c06c25CCff182115917C34A |
