const { ethers, upgrades } = require('hardhat')

const PROXY = '0x9D5924893C10cb801A8548307698E2149C4d3083'

async function main() {
  const NewPayment = await ethers.getContractFactory('SpacePaymentV6')
  console.log('Importing Space Payment...')
  await upgrades.forceImport(PROXY, NewPayment)
  console.log('Space Payment imported successfully')
}

main()
