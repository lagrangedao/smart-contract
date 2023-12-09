const { ethers, upgrades } = require('hardhat')
require('fs')

async function main() {
  const Generator = await ethers.getContractFactory('Generator')

  let source = fs.readFileSync('source.js').toString()
  let donId =
    '0x66756e2d706f6c79676f6e2d6d756d6261692d31000000000000000000000000'

  console.log('Deploying Generator...')

  const generator = await Generator.deploy(source, donId)
  await generator.waitForDeployment()

  console.log('Generator deployed to:', await generator.getAddress())
}

main()
