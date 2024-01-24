const { expect } = require('chai')
const { upgrades } = require('hardhat')

describe('BiddingContract', function () {
  let Swan
  let swan
  let BiddingContract
  let CollateralContract
  let Task
  let biddingContract
  let collateralContract
  let taskImplementation
  let owner
  let admin
  let user1
  let user2

  beforeEach(async function () {
    ;[owner, admin, user1, user2] = await ethers.getSigners()

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
  })

  //   it('should be initialized', async () => {
  //     await biddingContract.collateralContract = collateralContract.target
  //   })

  it('should assign a task', async function () {
    const taskId = 'task-id'
    const reward = ethers.parseEther('1')
    const collateral = ethers.parseEther('0.3')
    const duration = 3600 // 1 hour
    const cpList = [user1.address, user2.address]

    await collateralContract.deposit(user1.address, { value: reward })
    await collateralContract.deposit(user2.address, { value: reward })

    await biddingContract.assignTask(
      taskId,
      cpList,
      reward,
      collateral,
      duration,
    )

    let taskContractAddress = await biddingContract.tasks(taskId)

    const event = await biddingContract.queryFilter('TaskCreated')
    expect(event.length).to.equal(1)
    expect(event[0].args.taskId).to.equal(taskId)
    expect(event[0].args.taskContractAddress).to.equal(taskContractAddress)

    const taskContract = Task.attach(taskContractAddress)
    const isAdmin = await taskContract.isAdmin(biddingContract.target)
    expect(isAdmin)

    const taskReward = await taskContract.swanRewardAmount()
    expect(taskReward).to.equal(reward)

    const taskCollateral = await taskContract.swanCollateralAmount()
    expect(taskCollateral).to.equal(collateral)

    const taskDuration = await taskContract.duration()
    expect(taskDuration).to.equal(duration)

    const taskRefundClaimDuration = await taskContract.refundClaimDuration()
    expect(taskRefundClaimDuration).to.equal(0) // Refund claim duration is not set in this test

    const taskCollateralContract = await taskContract.collateralContract()
    expect(taskCollateralContract).to.equal(collateralContract.target)

    const taskBalanceInCollateralContract = await collateralContract.taskBalance(
      taskContractAddress,
    )
    expect(taskBalanceInCollateralContract).to.equal(
      BigInt(cpList.length) * collateral,
    )
  })

  it('should not allow the same taskId', async () => {
    const taskId = 'task-id'
    const reward = ethers.parseEther('1')
    const collateral = ethers.parseEther('0.3')
    const duration = 3600 // 1 hour
    const cpList = [user1.address, user2.address]

    await collateralContract.deposit(user1.address, { value: reward })
    await collateralContract.deposit(user2.address, { value: reward })

    await biddingContract.assignTask(
      taskId,
      cpList,
      reward,
      collateral,
      duration,
    )

    await expect(
      biddingContract.assignTask(taskId, cpList, reward, collateral, duration),
    ).to.be.reverted
  })
})
