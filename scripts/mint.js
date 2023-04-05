const { ethers } = require('hardhat')

const overrides = {
  gasLimit: 9999999, // gas lmit for sendRequest
}
const URI =
  'https://bc77513213.calibration-swan-acl.filswan.com/ipfs/Qmb58B2GHyhYSsq3mH7hp9WxhnPf9ohAuK1SsFPLMiGMu8'
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
