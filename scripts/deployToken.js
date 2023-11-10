const { ethers, upgrades } = require('hardhat')

async function main() {
  const USDC = await ethers.getContractFactory('USDC')

  console.log('Deploying USDC...')

  const usdc = await USDC.deploy()
  await usdc.waitForDeployment()

  console.log('USDC deployed to:', await usdc.getAddress())
}

main()
