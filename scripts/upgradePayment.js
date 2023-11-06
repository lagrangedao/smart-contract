const { ethers, upgrades } = require('hardhat')

const PROXY = '0x2108e71280b825131220cd710813c25874f0e718'

async function main() {
  const NewPayment = await ethers.getContractFactory('SpacePaymentV3')
  console.log('Upgrading Space Payment...')
  await upgrades.upgradeProxy(PROXY, NewPayment)
  console.log('Space Payment upgraded successfully')
}

main()
