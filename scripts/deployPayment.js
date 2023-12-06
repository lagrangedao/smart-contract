const { ethers, upgrades } = require('hardhat')

const TOKEN1 = '0x91B25A65b295F0405552A4bbB77879ab5e38166c'
const TOKEN2 = '0x0c1a5A0Cd0Bb4A9F564f09Cc66f4c921B560371a'
async function main() {
  const SP = await ethers.getContractFactory('SpacePaymentV6')

  console.log('Deploying SpacePayment...')

  const sp = await upgrades.deployProxy(SP, [TOKEN1, TOKEN2], {
    initializer: 'initialize',
  })
  await sp.waitForDeployment()

  console.log('SpacePayment deployed to:', await sp.getAddress())
}

main()
