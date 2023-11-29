const { expect } = require('chai')
const { MaxUint256 } = require('ethers')

describe('SpacePayment', function () {
  let spacePayment
  let collateralContract
  let token
  let usdc
  let owner
  let user
  let cp
  let ar
  let ap

  before(async () => {
    ;[owner, user, cp, cp2, ar, ap] = await ethers.getSigners()

    const Token = await ethers.getContractFactory('Token')
    const USDC = await ethers.getContractFactory('USDC')
    token = await Token.deploy('Token', 'TOK')
    await token.waitForDeployment()
    usdc = await USDC.deploy()
    await usdc.waitForDeployment()

    await usdc.mint(user, ethers.parseUnits('100', 'mwei'))
    await usdc.mint(cp, ethers.parseUnits('100', 'mwei'))
    await usdc.mint(cp2, ethers.parseUnits('100', 'mwei'))
    await usdc.mint(ap, ethers.parseUnits('100', 'mwei'))

    await token.mint(user, ethers.parseEther('100.0'))
    await token.mint(cp, ethers.parseEther('100.0'))
    await token.mint(cp2, ethers.parseEther('100.0'))
    await token.mint(ap, ethers.parseEther('100.0'))

    const SpacePayment = await ethers.getContractFactory('PaymentContract')
    spacePayment = await upgrades.deployProxy(SpacePayment, [usdc.target], {
      initializer: 'initialize',
    })
    await spacePayment.waitForDeployment()
    await spacePayment.setWallet(ar.address)
    await spacePayment.setHardware(0, 'test hardware', '1000000', true) // 1 USD / hr

    // await usdc.connect(ap).approve(spacePayment, MaxUint256)
    // await token.connect(ap).approve(spacePayment, MaxUint256)

    let CollateralContract = await ethers.getContractFactory(
      'CollateralContract',
    )
    collateralContract = await upgrades.deployProxy(
      CollateralContract,
      [token.target],
      {
        initializer: 'initialize',
      },
    )
  })

  it('Should deploy and initialize the contract', async function () {
    // Check if the contract was deployed and initialized correctly.
    const paymentToken = await spacePayment.paymentToken()
    const ownerAddress = await spacePayment.owner()

    // Perform assertions to check contract state.
    expect(paymentToken).to.equal(usdc.target)
    expect(ownerAddress).to.equal(owner.address)
  })

  it('Should let user pay', async function () {
    await usdc.connect(user).approve(spacePayment, '1000000')
    await spacePayment.connect(user).lockRevenue('space1', 0, 1)

    let userBalance = await usdc.balanceOf(user.address)
    let arBalance = await usdc.balanceOf(ar.address)

    // Perform assertions to check contract state.
    expect(userBalance).to.equal('99000000')
    expect(arBalance).to.equal('1000000')
  })

  it('Should let cps deposit', async function () {
    await token.connect(cp).approve(collateralContract, ethers.parseEther('10'))
    await token
      .connect(cp2)
      .approve(collateralContract, ethers.parseEther('10'))
    await collateralContract
      .connect(cp)
      .deposit(cp.address, ethers.parseEther('10'))
    await collateralContract
      .connect(cp2)
      .deposit(cp2.address, ethers.parseEther('10'))

    let cpBalance = await token.balanceOf(cp.address)
    let cp2Balance = await token.balanceOf(cp2.address)
    let contractBalance = await token.balanceOf(collateralContract.target)

    // Perform assertions to check contract state.
    expect(cpBalance).to.equal(ethers.parseEther('90'))
    expect(cp2Balance).to.equal(ethers.parseEther('90'))
    expect(contractBalance).to.equal(ethers.parseEther('20'))
  })
})
