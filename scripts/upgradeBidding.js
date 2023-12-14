const { ethers, upgrades } = require('hardhat')

const PROXY = '0x1beeD4d28757a5b692722311DF9A2c8D53B32a90'

async function main() {
  const NewPayment = await ethers.getContractFactory('BiddingContract')
  console.log('Upgrading BiddingContract...')
  await upgrades.upgradeProxy(PROXY, NewPayment)
  console.log('BiddingContract upgraded successfully')
}

main()
