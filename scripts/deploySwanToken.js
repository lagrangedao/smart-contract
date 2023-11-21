const { ethers, upgrades } = require('hardhat')

async function main() {
  const SwanToken = await ethers.getContractFactory('SwanTokenUpgradeable')

  console.log('Deploying SwanToken...')

  const swanToken = await upgrades.deployProxy(SwanToken, [], {
    initializer: 'initialize',
  })
  await swanToken.waitForDeployment()

  console.log('SwanToken deployed to:', await swanToken.getAddress())
}

main()
