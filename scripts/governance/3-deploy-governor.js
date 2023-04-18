const { ethers } = require('hardhat')

async function main() {
  const deployer = await ethers.getSigner()
  console.log('deployer: ', deployer.address)

  const TOKEN_ADDRESS = '0x44E147b52A0492A7dD9774575adA61ad95750993'
  const TIMELOCK_ADDRESS = '0x964f2e0362F7F935A02Fa2ea7e861aE53F47450D'
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
