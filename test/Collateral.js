const { expect } = require('chai')
const { upgrades } = require('hardhat')

describe('CollateralContract', function () {
  let CollateralContract
  let collateralContract
  let owner
  let admin
  let user1
  let user2

  beforeEach(async function () {
    ;[owner, admin, user1, user2, task] = await ethers.getSigners()

    // Deploy the CollateralContract
    CollateralContract = await ethers.getContractFactory('CollateralContract')
    collateralContract = await upgrades.deployProxy(CollateralContract, [])
    await collateralContract.addAdmin(admin.address)
  })

  it('should deposit ETH into the contract', async function () {
    const depositAmount = ethers.parseEther('1')

    await expect(() =>
      collateralContract.deposit(user1.address, { value: depositAmount }),
    ).to.changeEtherBalance(owner, -depositAmount)

    const userBalance = await collateralContract.balances(user1.address)
    expect(userBalance).to.equal(depositAmount)

    const event = await collateralContract.queryFilter('Deposit')
    expect(event.length).to.equal(1)
    expect(event[0].args.fundingWallet).to.equal(owner.address)
    expect(event[0].args.receivingWallet).to.equal(user1.address)
    expect(event[0].args.depositAmount).to.equal(depositAmount)
  })

  it('should withdraw ETH from the contract', async function () {
    const depositAmount = ethers.parseEther('1')
    await collateralContract.deposit(user1.address, { value: depositAmount })

    const withdrawAmount = ethers.parseEther('0.5')
    await expect(() =>
      collateralContract.connect(user1).withdraw(withdrawAmount),
    ).to.changeEtherBalance(user1, withdrawAmount)

    const userBalance = await collateralContract.balances(user1.address)
    expect(userBalance).to.equal(depositAmount - withdrawAmount)

    const event = await collateralContract.queryFilter('Withdraw')
    expect(event.length).to.equal(1)
    expect(event[0].args.fundingWallet).to.equal(user1.address)
    expect(event[0].args.withdrawAmount).to.equal(withdrawAmount)
  })

  it('should lock collateral for a task', async function () {
    const depositAmount = ethers.parseEther('1')
    await collateralContract.deposit(user1.address, { value: depositAmount })
    await collateralContract.deposit(user2.address, { value: depositAmount })

    const taskContract = ethers.Wallet.createRandom().address
    const cpList = [user1.address, user2.address]
    const collateralAmount = ethers.parseEther('0.4')

    await collateralContract
      .connect(admin)
      .lockCollateral(taskContract, cpList, collateralAmount)

    for (const cp of cpList) {
      const cpBalance = await collateralContract.balances(cp)
      expect(cpBalance).to.equal(depositAmount - collateralAmount)
      const frozenBalance = await collateralContract.frozenBalance(cp)
      expect(frozenBalance).to.equal(collateralAmount)
    }

    const taskBalance = await collateralContract.taskBalance(taskContract)
    expect(taskBalance).to.equal(BigInt(cpList.length) * collateralAmount)

    const event = await collateralContract.queryFilter('LockCollateral')
    expect(event.length).to.equal(1)
    expect(event[0].args.taskContract).to.equal(taskContract)
    expect(event[0].args.cpList).to.deep.equal(cpList)
    expect(event[0].args.collateralAmount).to.equal(collateralAmount)
  })

  it('should unlock collateral for a task', async function () {
    const depositAmount = ethers.parseEther('1')
    await collateralContract.deposit(user1.address, { value: depositAmount })
    await collateralContract.deposit(user2.address, { value: depositAmount })

    const taskContract = task.address
    const cpList = [user1.address, user2.address]
    const collateralAmount = ethers.parseEther('0.4')

    await collateralContract
      .connect(admin)
      .lockCollateral(taskContract, cpList, collateralAmount)

    await collateralContract
      .connect(task)
      .unlockCollateral(user1.address, collateralAmount)

    const userBalance = await collateralContract.balances(user1.address)
    expect(userBalance).to.equal(
      depositAmount - collateralAmount + collateralAmount,
    )

    const frozenBalance = await collateralContract.frozenBalance(user1.address)
    expect(frozenBalance).to.equal(collateralAmount - collateralAmount)

    const taskBalance = await collateralContract.taskBalance(taskContract)
    expect(taskBalance).to.equal(
      BigInt(cpList.length) * collateralAmount - collateralAmount,
    )

    const event = await collateralContract.queryFilter('UnlockCollateral')
    expect(event.length).to.equal(1)
    expect(event[0].args.taskContract).to.equal(taskContract)
    expect(event[0].args.cp).to.equal(user1.address)
    expect(event[0].args.collateralAmount).to.equal(collateralAmount)
  })
})
