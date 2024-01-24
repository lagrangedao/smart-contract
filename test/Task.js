const { expect } = require('chai')
const { upgrades } = require('hardhat')

describe('Task', function () {
  let Swan
  let swan
  let Task
  let CollateralContract
  let taskContract
  let collateralContract
  let owner
  let admin
  let user
  let cp1
  let cp2

  beforeEach(async function () {
    ;[owner, admin, cp1, cp2] = await ethers.getSigners()

    Task = await ethers.getContractFactory('Task')

    // Deploy CollateralContract
    Swan = await ethers.getContractFactory('Token')
    swan = await Swan.deploy('Swan Token', 'SWAN')
    await swan.mint(owner, ethers.parseEther('100'))

    CollateralContract = await ethers.getContractFactory('CollateralContract')
    collateralContract = await upgrades.deployProxy(CollateralContract, [])

    // Deploy BiddingContract
    BiddingContract = await ethers.getContractFactory('BiddingContract')
    biddingContract = await upgrades.deployProxy(BiddingContract, [
      owner.address,
      owner.address,
      collateralContract.target,
      swan.target,
    ])

    await collateralContract.addAdmin(biddingContract.target)
    await swan.approve(biddingContract.target, ethers.MaxUint256)

    await collateralContract.deposit(cp1.address, {
      value: ethers.parseEther('10'),
    })
    await collateralContract.deposit(cp2.address, {
      value: ethers.parseEther('10'),
    })

    // Transfer some SWAN tokens to the task contract
    await swan.mint(owner.address, ethers.parseEther('100'))

    await biddingContract.assignTask(
      'taskId',
      [cp1.address, cp2.address],
      ethers.parseEther('10'),
      ethers.parseEther('6'),
      3600,
    )

    let taskAddress = await biddingContract.tasks('taskId')
    taskContract = Task.attach(taskAddress)
  })

  it('should be initialized', async function () {
    expect(await taskContract.isAdmin(owner.address)).to.be.true
    expect(await taskContract.cpList(0)).to.equal(cp1.address)
    expect(await taskContract.cpList(1)).to.equal(cp2.address)
    expect(await taskContract.swanRewardAmount()).to.equal(
      ethers.parseEther('10'),
    )
    expect(await taskContract.swanCollateralAmount()).to.equal(
      ethers.parseEther('6'),
    )
    expect(await taskContract.duration()).to.equal(3600)
    // expect(await taskContract.refundClaimDuration()).to.equal(600)
    expect(await taskContract.collateralContract()).to.equal(
      collateralContract.target,
    )
  })

  it('should update end time by admin', async function () {
    let startTime = await taskContract.startTime()

    await taskContract.updateEndTime(startTime + BigInt(1000))
    expect(await taskContract.endTime()).to.equal(startTime + BigInt(1000))
  })

  it('should calculate payout correctly', async function () {
    let startTime = await taskContract.startTime()
    await taskContract.updateEndTime(startTime + BigInt(180))

    expect(await taskContract.rewardBalance()).to.equal(
      (ethers.parseEther('10') * BigInt(5)) / BigInt(100),
    )
    expect(await taskContract.refundBalance()).to.equal(
      (ethers.parseEther('10') * BigInt(95)) / BigInt(100),
    )
  })

  //   it('should complete task', async function () {
  //     await taskContract.completeTask(user.address)
  //     expect(await taskContract.refundDeadline()).to.not.equal(0)
  //     expect(await taskContract.rewardBalance()).to.equal(95) // 5% task fee deducted
  //     expect(await swanToken.balanceOf(owner.address)).to.equal(5) // Task fee transferred to owner
  //   })

  //   it('should request refund', async function () {
  //     await taskContract.requestRefund()
  //     expect(await taskContract.isProcessingRefundClaim()).to.be.true
  //   })

  //   it('should validate refund', async function () {
  //     await taskContract.requestRefund()
  //     await taskContract.connect(admin).validateRefund(true)
  //     expect(await taskContract.isProcessingRefundClaim()).to.be.false
  //   })

  it('should claim reward', async function () {
    let startTime = await taskContract.startTime()
    await taskContract.updateEndTime(startTime + BigInt(3600))
    await taskContract.connect(cp1).claimReward()
    const cp1Balance = await collateralContract.balances(cp1.address)
    const cp1FrozenBalance = await collateralContract.frozenBalance(cp1.address)
    const cp2Balance = await collateralContract.balances(cp2.address)
    const cp2FrozenBalance = await collateralContract.frozenBalance(cp2.address)
    expect(cp1Balance).to.equal(ethers.parseEther('10')) // Assuming reward is distributed evenly
    expect(cp2FrozenBalance).to.equal(ethers.parseEther('6')) // Assuming reward is distributed evenly
  })

  //   it('should claim refund', async function () {
  //     await taskContract.completeTask(user.address)
  //     await taskContract.claimRefund()
  //     const userBalance = await swanToken.balanceOf(user.address)
  //     expect(userBalance).to.equal(5) // Assuming refund amount is 50
  //   })
})
