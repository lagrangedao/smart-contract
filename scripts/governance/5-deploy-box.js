const { ethers } = require('hardhat')

async function main() {
  const TIMELOCK_ADDRESS = '0x65b81EE8beBA62eC1A047F9d77736fa03b8c4e82'

  const deployer = await ethers.getSigner()
  console.log('deployer: ', deployer.address)

  console.log('deploying Box...')
  const contractFactory = await ethers.getContractFactory('Box')
  const contract = await contractFactory.deploy()

  console.log('address: ' + contract.address)
  await contract.deployed()

  const TimeLock = await ethers.getContractFactory('TimeLock')
  const timeLock = TimeLock.attach(TIMELOCK_ADDRESS)
  console.log('transferring box to timelock...')
  const transferTx = await contract.transferOwnership(timeLock.address)
  await transferTx.wait(1)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
