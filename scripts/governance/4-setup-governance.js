const { ethers } = require('hardhat')

async function main() {
  const TOKEN_ADDRESS = '0x6e47e89bFA98c912A293C9b4FE8d6415Ac86CE12'
  const TIMELOCK_ADDRESS = '0x65b81EE8beBA62eC1A047F9d77736fa03b8c4e82'
  const GOVERNOR_ADDRESS = '0x67FaAaf08De1cB6de51fCb936893c542692b9115'
  const ADDRESS_ZERO = ethers.constants.AddressZero

  const Token = await ethers.getContractFactory('GovernanceToken')
  const TimeLock = await ethers.getContractFactory('TimeLock')
  const Governor = await ethers.getContractFactory('GovernorContract')

  const token = Token.attach(TOKEN_ADDRESS)
  const timeLock = TimeLock.attach(TIMELOCK_ADDRESS)
  const governor = Governor.attach(GOVERNOR_ADDRESS)

  console.log('----------------------------------------------------')
  console.log('Setting up contracts for roles...')
  // would be great to use multicall here...
  const deployer = await ethers.getSigner()
  const proposerRole = await timeLock.PROPOSER_ROLE()
  const executorRole = await timeLock.EXECUTOR_ROLE()
  const adminRole = await timeLock.TIMELOCK_ADMIN_ROLE()

  const proposerTx = await timeLock.grantRole(proposerRole, governor.address)
  await proposerTx.wait(1)
  const executorTx = await timeLock.grantRole(executorRole, ADDRESS_ZERO)
  await executorTx.wait(1)
  const revokeTx = await timeLock.revokeRole(adminRole, deployer.address)
  await revokeTx.wait(1)
  // Guess what? Now, anything the timelock wants to do has to go through the governance process!
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
