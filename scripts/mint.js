const { ethers } = require('hardhat')

const overrides = {
  gasLimit: 9999999, // gas lmit for sendRequest
}
const URI =
  'https://2d9999d121.calibration-swan-acl.filswan.com/ipfs/QmZEPZos8pExSSqfZwi4RKrLHUGBgQ5KsHMP3poyPMBomA'
const GAS_LIMIT = 300000 // gas limit for fulfillRequest

async function main() {
  const minter = await ethers.getSigner()

  console.log('minter: ', minter.address)

  const nftFactory = await ethers.getContractFactory('LagrangeChainlinkData')
  const nftContractAddress = '0x2315804B67010B6AB003Bef541b22D19cC074f41'
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
