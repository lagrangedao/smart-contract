const { expect } = require('chai')

describe('TaskManager', function () {
  let taskManager
  let token
  let owner
  let user
  let cp

  before(async () => {
    ;[owner, user, cp] = await ethers.getSigners()

    const Token = await ethers.getContractFactory('Token')
    token = await Token.deploy('Token', 'TOK')
    await token.waitForDeployment()

    await token.mint(user, ethers.parseEther('1.0'))
    await token.mint(cp, ethers.parseEther('10.0'))

    const TaskManager = await ethers.getContractFactory('TaskManager')
    taskManager = await upgrades.deployProxy(TaskManager, [token.target], {
      initializer: 'initialize',
    })
    await taskManager.waitForDeployment()
  })

  it('Should deploy and initialize the contract', async function () {
    // Check if the contract was deployed and initialized correctly.
    const revenueToken = await taskManager.token()
    const ownerAddress = await taskManager.owner()

    // Perform assertions to check contract state.
    expect(revenueToken).to.equal(token.target)
    expect(ownerAddress).to.equal(owner.address)
  })

  it('Should allow a user to request a task', async function () {
    // Set the task ID, revenue, and task duration for testing.
    const taskId = 'Task123'
    const revenue = ethers.parseEther('1.0') // 1 ETH in wei
    const taskDuration = 3600 // 1 hour in seconds

    // Ensure that the user has approved the contract to spend tokens by mocking the transferFrom function.
    await token.connect(user).approve(taskManager.target, revenue)

    // Request a task and check locked revenue.
    await taskManager.connect(user).lockRevenue(taskId, taskDuration, revenue)

    // Retrieve task details after the request.
    const task = await taskManager.tasks(taskId)

    // Check that the user's address and revenue are correctly set in the task.
    expect(task.user).to.equal(user.address)
    expect(task.lockedRevenue).to.equal(revenue)
  })

  it('Should allow the owner to assign a task', async function () {
    // Set the task ID and the address of the computing provider for testing.
    const taskId = 'Task123'
    const computingProvider = cp.address
    const collateral = ethers.parseEther('10.0')

    // Assign the task to the computing provider.
    await taskManager
      .connect(owner)
      .assignTask(taskId, computingProvider, collateral) // Assuming a collateral value of 100 (in your contract, use the actual value).

    // Retrieve the assigned computing provider address from the contract.
    const assignedCp = (await taskManager.tasks(taskId)).assignedCP

    // Check if the assigned computing provider matches the expected value.
    expect(assignedCp).to.equal(computingProvider)
  })

  it('Should allow a computing provider to accept a task', async function () {
    // Set the task ID for testing.
    const taskId = 'Task123'
    const collateral = ethers.parseEther('10.0')

    await token.connect(cp).approve(taskManager.target, collateral)
    // Accept the task as the computing provider.
    await taskManager.connect(cp).lockCollateral(taskId)

    // Retrieve the task details after accepting.
    const task = await taskManager.tasks(taskId)
    const assignedCp = task.assignedCP

    // Check that the task is assigned to the computing provider and taskDeadline is set.
    expect(assignedCp).to.equal(cp.address)
    expect(parseInt(task.taskDeadline)).to.be.above(0)
  })

  it('Should allow a computing provider to terminate a task', async function () {
    // Set the task ID for testing.
    const taskId = 'Task123'

    // Terminate the task as the computing provider.
    await taskManager.connect(cp).terminateTask(taskId)

    // Retrieve the task details after terminating.
    const task = await taskManager.tasks(taskId)

    // Check that the locked revenue and collateral are reset to zero.
    expect(parseInt(task.lockedRevenue)).to.equal(0)
    expect(parseInt(task.lockedCollateral)).to.equal(0)
  })

  it('Should allow a computing provider to collect revenue', async function () {
    // Set the task ID for testing.
    const taskId = 'Task123'

    // Collect revenue as the computing provider.
    await taskManager.connect(cp).collectRevenue(taskId)

    // Ensure that the revenue was collected.
    const task = await taskManager.tasks(taskId)
    expect(parseInt(task.lockedRevenue)).to.equal(0)
  })
})
