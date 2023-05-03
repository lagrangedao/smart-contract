const {
  loadFixture,
  time,
  mine,
} = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')

describe('Governor Contract', function () {
  async function deployToken() {
    const [owner, addr1, addr2] = await ethers.getSigners()

    const Token = await ethers.getContractFactory('GovernanceToken')

    const token = await Token.deploy()
    await token.deployed()

    // Fixtures can return anything you consider useful for your tests
    return { token, owner, addr1, addr2 }
  }

  async function deployFixture() {
    const [owner, addr1, addr2] = await ethers.getSigners()
    const MIN_DELAY = 3600
    const VOTING_DELAY = 1
    const VOTING_PERIOD = 50400
    const QUORUM_PERCENTAGE = 4
    const ADDRESS_ZERO = ethers.constants.AddressZero

    const Token = await ethers.getContractFactory('GovernanceToken')
    const Timelock = await ethers.getContractFactory('TimeLock')
    const Governor = await ethers.getContractFactory('GovernorContract')
    const Box = await ethers.getContractFactory('Box')

    const token = await Token.deploy()
    await token.deployed()
    const timeLock = await Timelock.deploy(MIN_DELAY, [], [], owner.address)
    await timeLock.deployed()
    const governor = await Governor.deploy(
      token.address,
      timeLock.address,
      VOTING_DELAY,
      VOTING_PERIOD,
      QUORUM_PERCENTAGE,
    )
    await governor.deployed()
    const box = await Box.deploy()
    await box.deployed()
    const transferTx = await box.transferOwnership(timeLock.address)
    await transferTx.wait()

    const proposerRole = await timeLock.PROPOSER_ROLE()
    const executorRole = await timeLock.EXECUTOR_ROLE()
    const adminRole = await timeLock.TIMELOCK_ADMIN_ROLE()

    const proposerTx = await timeLock.grantRole(proposerRole, governor.address)
    await proposerTx.wait(1)
    const executorTx = await timeLock.grantRole(executorRole, ADDRESS_ZERO)
    await executorTx.wait(1)
    const revokeTx = await timeLock.revokeRole(adminRole, owner.address)
    await revokeTx.wait(1)

    // Fixtures can return anything you consider useful for your tests
    return { token, timeLock, governor, box, owner, addr1, addr2 }
  }

  describe('Deployment', async () => {
    it('Max supply should be minted to deployer', async function () {
      const { token, owner } = await loadFixture(deployFixture)

      let maxSupply = await token.MAX_SUPPLY()
      expect(await token.balanceOf(owner.address)).to.equal(maxSupply)
    })

    it('Governor should have correct settings', async function () {
      const { governor } = await loadFixture(deployFixture)

      expect(await governor.votingDelay()).to.equal(1)
      expect(await governor.votingPeriod()).to.equal(50400)
    })

    it('Box should have no inital value', async function () {
      const { box, timeLock } = await loadFixture(deployFixture)

      expect(await box.owner()).to.equal(timeLock.address)
      expect(await box.retrieve()).to.equal(0)
    })
  })

  describe('Proposals', async () => {
    it('Should create proposal', async function () {
      const { box, governor } = await loadFixture(deployFixture)

      const encodedFunctionCall = box.interface.encodeFunctionData('store', [
        1234,
      ])

      const proposeTx = await governor.propose(
        [box.address],
        [0],
        [encodedFunctionCall],
        'Proposal: Store 1234 in Box',
      )
      const proposalReceipt = await proposeTx.wait(1)
      const proposalId = proposalReceipt.events[0].args.proposalId
      console.log('Proposal ID: ', proposalId)

      const proposalState = await governor.state(proposalId)
      const proposalSnapShot = await governor.proposalSnapshot(proposalId)
      const proposalDeadline = await governor.proposalDeadline(proposalId)

      // the Proposal State is an enum data type, defined in the IGovernor contract.
      // 0:Pending, 1:Active, 2:Canceled, 3:Defeated, 4:Succeeded, 5:Queued, 6:Expired, 7:Executed
      console.log(`Current Proposal State: ${proposalState}`)
      // What block # the proposal was snapshot
      console.log(`Current Proposal Snapshot: ${proposalSnapShot}`)
      // The block number the proposal voting expires
      console.log(`Current Proposal Deadline: ${proposalDeadline}`)
    })
  })
})
