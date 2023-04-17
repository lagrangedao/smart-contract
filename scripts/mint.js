const { ethers } = require('hardhat')

const overrides = {
  gasLimit: 9999999, // gas lmit for sendRequest
}
const URI =
  'https://bc77513213.calibration-swan-acl.filswan.com/ipfs/QmbHYHjXo1phy8dM19zkAR53xerP4TmTuz4rH6UPRHehY5?filename=dataset_metadata.json'
const GAS_LIMIT = 300000 // gas limit for fulfillRequest

async function main() {
  const minter = await ethers.getSigner()

  console.log('minter: ', minter.address)

  const nftFactory = await ethers.getContractFactory('LagrangeChainlinkData')
  const nftContractAddress = '0xD81288579c13e26F621840B66aE16af1460ebB5a'
  const nftContract = nftFactory.attach(nftContractAddress)

  // await USDCInstance.connect(deployer).mint(addressList[0], fiveMillion);
  const tx = await nftContract.mint(URI, GAS_LIMIT, overrides)
  await tx.wait()

  console.log(tx)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
