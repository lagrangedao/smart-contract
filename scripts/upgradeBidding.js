const { ethers, upgrades } = require('hardhat')

const PROXY = '0x37c93891943D319e3546f6455b14661636dEAA5d'

async function main() {
  const NewPayment = await ethers.getContractFactory('BiddingContract')
  console.log('Upgrading BiddingContract...')
  await upgrades.upgradeProxy(PROXY, NewPayment)
  console.log('BiddingContract upgraded successfully')
}

main()
