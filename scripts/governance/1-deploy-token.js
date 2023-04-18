const { ethers } = require('hardhat')

async function main() {
  const deployer = await ethers.getSigner()
  console.log('deployer: ', deployer.address)

  console.log('deploying GovernanceToken...')
  const contractFactory = await ethers.getContractFactory('GovernanceToken')
  const contract = await contractFactory.deploy()

  console.log('address: ' + contract.address)
  await contract.deployed()
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
