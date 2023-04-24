const fs = require('fs')
const { ethers } = require('hardhat')

async function main() {
  const deployer = await ethers.getSigner()
  console.log('deployer: ', deployer.address)

  const subID = 423
  const source = fs.readFileSync('./temp-source.js').toString()

  const mumbaiLINK = '0x326C977E6efc84E512bB9C30f76E30c160eD06FB'
  const mumbaiOracle = '0x40193c8518BB267228Fc409a613bDbD8eC5a97b3'
  const fee = ethers.utils.parseEther('0.1')

  console.log('deploying...')
  //   const nftFactory = await ethers.getContractFactory('LagrangeChainlinkData')
  //   const nftContract = await nftFactory.deploy(
  //     network.config.oracleAddress,
  //     subID,
  //     source,
  //   )

  const nftFactory = await ethers.getContractFactory(
    'LagrangeChainlinkDataConsumer',
  )
  const nftContract = await nftFactory.deploy(mumbaiLINK, mumbaiOracle, fee)

  console.log('address: ' + nftContract.address)
  await nftContract.deployed()

  function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms))
  }
  await sleep(10000)

  console.log('verifying...')
  await hre.run('verify:verify', {
    address: nftContract.address,
    //constructorArguments: [network.config.oracleAddress, subID, source],
    constructorArguments: [mumbaiLINK, mumbaiOracle, fee],
  })
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
