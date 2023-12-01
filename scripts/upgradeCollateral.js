const { ethers, upgrades } = require('hardhat')

const PROXY = '0xbb3023a1Cc5013f6B17bC18a68Df3f2979291C95'

async function main() {
  const NewPayment = await ethers.getContractFactory('CollateralContract')
  console.log('Upgrading Collateral Contract...')
  await upgrades.upgradeProxy(PROXY, NewPayment)
  console.log('Collateral Contract upgraded successfully')
}

main()
