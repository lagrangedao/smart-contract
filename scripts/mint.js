const { ethers } = require('hardhat')

const overrides = {
  gasLimit: 9999999,
}

async function main() {
  const minter = await ethers.getSigner()

  console.log('minter: ', minter.address)

  const nftFactory = await ethers.getContractFactory('LagrangeChainlinkData')
  const nftContractAddress = '0x6c1f02f31CC933f8bf27f20B1Fde70563027e997'
  const nftContract = nftFactory.attach(nftContractAddress)

  const gasLimit = 100000

  // await USDCInstance.connect(deployer).mint(addressList[0], fiveMillion);
  const tx = await nftContract.mint(nftContractAddress, gasLimit, overrides)
  await tx.wait()

  console.log(tx)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
