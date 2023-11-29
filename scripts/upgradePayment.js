const { ethers, upgrades } = require('hardhat')

const PROXY = '0x8076FC0D5F8ffF71CdE8d50Bf6d43EE1Ce0d6387'

async function main() {
  const NewPayment = await ethers.getContractFactory('SpacePaymentV6')
  console.log('Upgrading Space Payment...')
  await upgrades.upgradeProxy(PROXY, NewPayment)
  console.log('Space Payment upgraded successfully')
}

main()
