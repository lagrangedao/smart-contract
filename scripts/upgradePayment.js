const { ethers, upgrades } = require('hardhat')

const PROXY = '0xB8C33A9C75CFd4C7A748109372a1bd2c61A5cA69'

async function main() {
  const NewPayment = await ethers.getContractFactory('SpacePaymentV5')
  console.log('Upgrading Space Payment...')
  await upgrades.upgradeProxy(PROXY, NewPayment)
  console.log('Space Payment upgraded successfully')
}

main()
