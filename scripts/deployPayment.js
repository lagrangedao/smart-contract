const { ethers, upgrades } = require('hardhat')

const TOKEN = '0x3CF24790B3af64029564E81B67aF299dB83Fd9e3'
async function main() {
  const SP = await ethers.getContractFactory('SpacePaymentV1')

  console.log('Deploying SpacePayment...')

  const sp = await upgrades.deployProxy(SP, [TOKEN], {
    initializer: 'initialize',
  })
  await sp.waitForDeployment()

  console.log('SpacePayment deployed to:', await sp.getAddress())
}

main()
