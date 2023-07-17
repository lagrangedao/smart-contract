const { ethers } = require('hardhat')

async function main() {
  const deployer = await ethers.getSigner()
  console.log('deployer: ', deployer.address)

  const MIN_DELAY = 3600

  console.log('deploying TimeLock...')
  const contractFactory = await ethers.getContractFactory('TimeLock')
  const contract = await contractFactory.deploy(
    MIN_DELAY,
    [],
    [],
    deployer.address,
  )

  console.log('address: ' + contract.address)
  await contract.deployed()
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
