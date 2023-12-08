const { ethers, upgrades } = require('hardhat')

const PROXY = '0x2656D8AAecadd41766a958db807d1BBACd1ECD71'

async function main() {
  const NewPayment = await ethers.getContractFactory('BiddingContract')
  console.log('Upgrading BiddingContract...')
  await upgrades.upgradeProxy(PROXY, NewPayment)
  console.log('BiddingContract upgraded successfully')
}

main()
