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

    const delegateTx = await token.delegate(owner.address)
    await delegateTx.wait()

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
      const { box, governor, owner } = await loadFixture(deployFixture)

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
      const proposal = proposalReceipt.events[0].args

      expect(proposal.proposer).to.equal(owner.address)
      expect(proposal.targets[0]).to.equal(box.address)
      expect(proposal.calldatas[0]).to.equal(encodedFunctionCall)

      expect(await governor.state(proposal.proposalId)).to.equal(0)
      await mine(2)
      expect(await governor.state(proposal.proposalId)).to.equal(1)
    })

    it('Should vote on proposal', async () => {
      const { token, box, governor, owner } = await loadFixture(deployFixture)

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
      const proposal = proposalReceipt.events[0].args

      await mine(2)
      // 0:Pending, 1:Active, 2:Canceled, 3:Defeated, 4:Succeeded, 5:Queued, 6:Expired, 7:Executed
      expect(await governor.state(proposal.proposalId)).to.equal(1)

      // 0 = Against, 1 = For, 2 = Abstain for this example
      const voteTx = await governor.castVote(proposal.proposalId, 1)
      await voteTx.wait(1)

      const votes = await governor.proposalVotes(proposal.proposalId)

      expect(
        await governor.hasVoted(proposal.proposalId, owner.address),
      ).to.equal(true)
      expect(await token.balanceOf(owner.address)).to.be.equal(votes.forVotes)
    })

    it('Should queue and execute proposal', async () => {
      const { box, governor, owner } = await loadFixture(deployFixture)

      const encodedFunctionCall = box.interface.encodeFunctionData('store', [
        1234,
      ])
      const description = 'Proposal: Store 1234 in Box'
      const descriptionHash = ethers.utils.keccak256(
        ethers.utils.toUtf8Bytes(description),
      )

      const proposeTx = await governor.propose(
        [box.address],
        [0],
        [encodedFunctionCall],
        description,
      )
      const proposalReceipt = await proposeTx.wait(1)
      const proposal = proposalReceipt.events[0].args

      await mine(2)
      // 0:Pending, 1:Active, 2:Canceled, 3:Defeated, 4:Succeeded, 5:Queued, 6:Expired, 7:Executed
      expect(await governor.state(proposal.proposalId)).to.equal(1)

      // 0 = Against, 1 = For, 2 = Abstain for this example
      const voteTx = await governor.castVote(proposal.proposalId, 1)
      await voteTx.wait(1)

      await mine(51000) // wait for voting period to end

      const queueTx = await governor.queue(
        [box.address],
        [0],
        [encodedFunctionCall],
        descriptionHash,
      )
      await queueTx.wait(1)

      await mine(4000) // wait for timelock min delay

      expect(await box.retrieve()).to.equal(0)

      // this will fail on a testnet because you need to wait for the MIN_DELAY!
      const executeTx = await governor.execute(
        [box.address],
        [0],
        [encodedFunctionCall],
        descriptionHash,
      )
      await executeTx.wait(1)

      expect(await box.retrieve()).to.equal(1234)
    })

    it('Should not be able to execute before quorum and threshold', async () => {
      const { box, governor, addr1 } = await loadFixture(deployFixture)

      const encodedFunctionCall = box.interface.encodeFunctionData('store', [
        1234,
      ])
      const description = 'Proposal: Store 1234 in Box'
      const descriptionHash = ethers.utils.keccak256(
        ethers.utils.toUtf8Bytes(description),
      )

      const proposeTx = await governor.propose(
        [box.address],
        [0],
        [encodedFunctionCall],
        description,
      )
      const proposalReceipt = await proposeTx.wait(1)
      const proposal = proposalReceipt.events[0].args

      await mine(2)
      // 0:Pending, 1:Active, 2:Canceled, 3:Defeated, 4:Succeeded, 5:Queued, 6:Expired, 7:Executed
      expect(await governor.state(proposal.proposalId)).to.equal(1)

      // 0 = Against, 1 = For, 2 = Abstain for this example
      const voteTx = await governor
        .connect(addr1)
        .castVote(proposal.proposalId, 1)
      await voteTx.wait(1)

      await expect(
        governor.queue(
          [box.address],
          [0],
          [encodedFunctionCall],
          descriptionHash,
        ),
      ).to.be.reverted
    })

    it('Should not be able to vote after voting period ends', async () => {
      const { box, governor } = await loadFixture(deployFixture)

      const encodedFunctionCall = box.interface.encodeFunctionData('store', [
        1234,
      ])
      const description = 'Proposal: Store 1234 in Box'

      const proposeTx = await governor.propose(
        [box.address],
        [0],
        [encodedFunctionCall],
        description,
      )
      const proposalReceipt = await proposeTx.wait(1)
      const proposal = proposalReceipt.events[0].args

      await mine(51000) // wait for voting period to end

      // 0 = Against, 1 = For, 2 = Abstain for this example
      await expect(governor.castVote(proposal.proposalId, 1)).to.be.reverted
    })

    it('Should not be able to create proposal without enough voting power', async () => {
      const { box, governor, addr1 } = await loadFixture(deployFixture)

      const encodedFunctionCall = governor.interface.encodeFunctionData(
        'setProposalThreshold',
        [1234],
      )
      const description = 'Proposal: Change Proposal Threshold'
      const descriptionHash = ethers.utils.keccak256(
        ethers.utils.toUtf8Bytes(description),
      )

      const proposeTx = await governor
        .connect(addr1)
        .propose([governor.address], [0], [encodedFunctionCall], description)
      const proposalReceipt = await proposeTx.wait(1)
      const proposalId = proposalReceipt.events[0].args.proposalId

      await mine(2)
      const voteTx = await governor.castVote(proposalId, 1)
      await voteTx.wait(1)

      await mine(51000) // wait for voting period to end

      const queueTx = await governor.queue(
        [governor.address],
        [0],
        [encodedFunctionCall],
        descriptionHash,
      )
      await queueTx.wait(1)

      await mine(4000) // wait for timelock min delay

      const executeTx = await governor.execute(
        [governor.address],
        [0],
        [encodedFunctionCall],
        descriptionHash,
      )
      await executeTx.wait(1)

      expect(await governor.proposalThreshold()).to.equal(1234)

      // addr 1 has 0 voting power, below new threshold, so should revert
      await expect(
        governor
          .connect(addr1)
          .propose([box.address], [0], [encodedFunctionCall], description),
      ).to.be.reverted
    })
  })
})
