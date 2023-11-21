const { ethers, upgrades } = require('hardhat')

const TOKEN1 = '0xFEA043Bf8b514F9FD8E87C4b7Dfc81096E4c6Ec8'
const TOKEN2 = '0xc648B1a7645FA706B52B1dFC799e7B2b487c08AD'
async function main() {
  const SP = await ethers.getContractFactory('SpacePaymentV4')

  console.log('Deploying SpacePayment...')

  const sp = await upgrades.deployProxy(SP, [TOKEN1, TOKEN2], {
    initializer: 'initialize',
  })
  await sp.waitForDeployment()

  console.log('SpacePayment deployed to:', await sp.getAddress())
}

main()
