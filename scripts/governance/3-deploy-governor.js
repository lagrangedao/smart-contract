const { ethers } = require('hardhat')

async function main() {
  const deployer = await ethers.getSigner()
  console.log('deployer: ', deployer.address)

  const TOKEN_ADDRESS = '0x6e47e89bFA98c912A293C9b4FE8d6415Ac86CE12'
  const TIMELOCK_ADDRESS = '0x65b81EE8beBA62eC1A047F9d77736fa03b8c4e82'
  const VOTING_DELAY = 1
  const VOTING_PERIOD = 5
  const QUORUM_PERCENTAGE = 4

  console.log('deploying GovernorContract...')
  const contractFactory = await ethers.getContractFactory('GovernorContract')
  const contract = await contractFactory.deploy(
    TOKEN_ADDRESS,
    TIMELOCK_ADDRESS,
    VOTING_DELAY,
    VOTING_PERIOD,
    QUORUM_PERCENTAGE,
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
