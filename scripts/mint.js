const { ethers } = require('hardhat')

const overrides = {
  gasLimit: 9999999,
}

async function main() {
  const minter = await ethers.getSigner()

  console.log('deployer: ', minter.address)

  const nftFactory = await ethers.getContractFactory('LagrangeChainlinkData')
  const nftContractAddress = '0xe16E7BD6692Dbf67942d62E8991Ddd573ed49C32'
  const nftContract = nftFactory.attach(nftContractAddress)

  const args = [
    '0x95ba4cf87d6723ad9c0db21737d862be80e93911',
    '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48',
  ]

  const gasLimit = 100000

  // await USDCInstance.connect(deployer).mint(addressList[0], fiveMillion);
  const tx = await nftContract.mint(args, gasLimit, overrides)
  await tx.wait()

  console.log('complete mint.')
  console.log(tx)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
