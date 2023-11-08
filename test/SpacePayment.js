const { expect } = require('chai')
const { MaxUint256 } = require('ethers')

describe('SpacePayment', function () {
  let spacePayment
  let token
  let usdc
  let owner
  let user
  let cp
  let ar
  let ap
  let taskId = 'Task123'
  let taskId2 = 'Task456'

  before(async () => {
    ;[owner, user, cp, ar, ap] = await ethers.getSigners()

    const Token = await ethers.getContractFactory('Token')
    const USDC = await ethers.getContractFactory('USDC')
    token = await Token.deploy('Token', 'TOK')
    await token.waitForDeployment()
    usdc = await USDC.deploy()
    await usdc.waitForDeployment()

    await usdc.mint(user, ethers.parseUnits('100', 'mwei'))
    await usdc.mint(cp, ethers.parseUnits('100', 'mwei'))
    await token.mint(ap, ethers.parseEther('100.0'))
    await usdc.mint(ap, ethers.parseUnits('100', 'mwei'))

    const SpacePayment = await ethers.getContractFactory('SpacePaymentV4')
    spacePayment = await upgrades.deployProxy(SpacePayment, [usdc.target], {
      initializer: 'initialize',
    })
    await spacePayment.waitForDeployment()
    await spacePayment.setRevenueToken(token.target)
    await spacePayment.setConversionRate('1230000000000') // 1.23x
    await spacePayment.setWallets(ar.address, ap.address)
    await spacePayment.setHardware(0, 'test hardware', '1000000', true) // 1 USD / hr
    await spacePayment.setRefundClaimDuration('3600')

    await usdc.connect(ap).approve(spacePayment, MaxUint256)
    await token.connect(ap).approve(spacePayment, MaxUint256)
  })

  it('Should deploy and initialize the contract', async function () {
    // Check if the contract was deployed and initialized correctly.
    const paymentToken = await spacePayment.paymentToken()
    const revenueToken = await spacePayment.revenueToken()
    const ownerAddress = await spacePayment.owner()

    // Perform assertions to check contract state.
    expect(revenueToken).to.equal(token.target)
    expect(paymentToken).to.equal(usdc.target)
    expect(ownerAddress).to.equal(owner.address)
  })

  it('Should allow a user to request a task', async function () {
    // Set the task ID, revenue, and task duration for testing.
    const revenue = ethers.parseUnits('5.0', 'mwei') // 1 ETH in wei

    // Ensure that the user has approved the contract to spend tokens by mocking the transferFrom function.
    await usdc.connect(user).approve(spacePayment.target, revenue)

    // Request a task and check locked revenue.
    await spacePayment.connect(user).lockRevenue(taskId, 0, 5)

    // Retrieve task details after the request.
    const task = await spacePayment.tasks(taskId)

    // Check that the user's address and revenue are correctly set in the task.
    expect(task.user).to.equal(user.address)
    expect(task.revenue).to.equal(revenue)
    expect(await usdc.balanceOf(user.address)).to.equal(
      ethers.parseUnits('95', 'mwei'),
    )
  })

  it('Should not allow a user to request the same task', async function () {
    // Set the task ID, revenue, and task duration for testing.
    const revenue = ethers.parseUnits('5.0', 'mwei') // 1 ETH in wei

    // Ensure that the user has approved the contract to spend tokens by mocking the transferFrom function.
    await usdc.connect(user).approve(spacePayment.target, revenue)

    // Request a task and check locked revenue.
    await expect(
      spacePayment.connect(user).lockRevenue(taskId, 0, 5),
    ).to.be.revertedWith('task id already in use')
    expect(await usdc.balanceOf(user.address)).to.equal(
      ethers.parseUnits('95', 'mwei'),
    )
  })

  it('Should only let admin assign task', async function () {
    await expect(
      spacePayment
        .connect(user)
        .assignTask(taskId, cp.address, ethers.parseUnits('10', 'mwei')),
    ).to.be.reverted
  })

  it('Should assign task to cp', async function () {
    await spacePayment.assignTask(
      taskId,
      cp.address,
      ethers.parseUnits('10', 'mwei'),
    )

    const assignedCp = (await spacePayment.tasks(taskId)).cp
    expect(assignedCp).to.equal(cp.address)
  })

  it('Should allow a computing provider to accept a task', async function () {
    // Set the task ID for testing.
    const collateral = ethers.parseUnits('10', 'mwei')

    await usdc.connect(cp).approve(spacePayment.target, collateral)
    // Accept the task as the computing provider.
    await spacePayment.connect(cp).lockCollateral(taskId)

    // Get the current block timestamp
    const currentTimestamp = (await ethers.provider.getBlock('latest'))
      .timestamp

    // Retrieve the task details after accepting.
    const task = await spacePayment.tasks(taskId)

    expect(parseInt(task.taskDeadline)).to.be.above(0)
    expect(task.taskDeadline).to.equal(currentTimestamp + 5 * 3600)
    expect(await usdc.balanceOf(cp.address)).to.equal(
      ethers.parseUnits('90', 'mwei'),
    )
  })

  it('Should mark the task as completed', async function () {
    await spacePayment.completeTask(taskId)
    const task = await spacePayment.tasks(taskId)

    // Get the current block timestamp
    const currentTimestamp = (await ethers.provider.getBlock('latest'))
      .timestamp

    expect(task.refundDeadline).to.equal(currentTimestamp + 3600)
  })

  it('Should allow user to request refund', async function () {
    // // Fast forward to a specific future timestamp (e.g., 2 hours ahead)
    // const futureTimestamp = currentTimestamp + 7200 // 2 hours in seconds
    // await network.provider.send('evm_setNextBlockTimestamp', [futureTimestamp])
    // await network.provider.send('evm_mine')

    // // Check the updated block timestamp
    // const updatedTimestamp = (await ethers.provider.getBlock('latest'))
    //   .timestamp

    await spacePayment.connect(user).requestRefund(taskId)
    const task = await spacePayment.tasks(taskId)

    expect(task.processingRefundClaim).to.be.true
  })

  it('Should verify refund claim', async function () {
    await spacePayment.validateClaim(taskId, true)
    const task = await spacePayment.tasks(taskId)

    expect(task.processingRefundClaim).to.be.false
    expect(await usdc.balanceOf(user)).to.equal('100000000')
    expect(await usdc.balanceOf(cp)).to.equal('90000000')
  })

  it('Should allow a computing provider to collect revenue', async function () {
    // Set the task ID, revenue, and task duration for testing.
    const revenue = ethers.parseUnits('5.0', 'mwei') // 1 ETH in wei
    const collateral = ethers.parseUnits('10.0', 'mwei')

    // Ensure that the user has approved the contract to spend tokens by mocking the transferFrom function.
    await usdc.connect(user).approve(spacePayment.target, revenue)
    await usdc.connect(cp).approve(spacePayment.target, collateral)

    // Request a task and check locked revenue.
    await spacePayment.connect(user).lockRevenue(taskId2, 0, 5)
    await spacePayment.assignTask(taskId2, cp.address, collateral)
    await spacePayment.connect(cp).lockCollateral(taskId2)
    await spacePayment.completeTask(taskId2)

    // Get the current block timestamp
    const currentTimestamp = (await ethers.provider.getBlock('latest'))
      .timestamp

    // Fast forward to a specific future timestamp (e.g., 2 hours ahead)
    const futureTimestamp = currentTimestamp + 3600 //1 hours in seconds
    await network.provider.send('evm_setNextBlockTimestamp', [futureTimestamp])
    await network.provider.send('evm_mine')

    // Collect revenue as the computing provider.
    await spacePayment.connect(cp).collectRevenue(taskId2)

    // Ensure that the revenue was collected.
    const task = await spacePayment.tasks(taskId2)
    expect(parseInt(task.revenue)).to.equal(0)

    expect(await usdc.balanceOf(user.address)).to.equal('95000000')
    expect(await usdc.balanceOf(cp.address)).to.equal('90000000')
    expect(await token.balanceOf(cp.address)).to.equal('6150000000000000000')

    expect(await usdc.balanceOf(ar.address)).to.equal('30000000')
    expect(await token.balanceOf(ar.address)).to.equal('0')
    expect(await usdc.balanceOf(ap.address)).to.equal('85000000')
    expect(await token.balanceOf(ap.address)).to.equal('93850000000000000000')
  })
})
