const { ethers, upgrades } = require('hardhat')

const AR_WALLET = '0x47846473daE8fA6E5E51e03f12AbCf4F5eDf9Bf5'
const AP_WALLET = '0x4BC1eE66695AD20771596290548eBE5Cfa1Be332'
const ADMIN_WALLET = '0x29eD49c8E973696D07E7927f748F6E5Eacd5516D'

const WETH_ADDRESS = '0x4A5d0592CDA144fCCe9543a4D3dEB121CbB0221D'

async function main() {
  const Collateral = await ethers.getContractFactory('CollateralContractV2')
  const Bidding = await ethers.getContractFactory('BiddingContractV2')
  const WETH = await ethers.getContractFactory('WETH9')
  const weth = WETH.attach(WETH_ADDRESS)

  console.log('Deploying Collateral Contract...')

  //   const collateral = await upgrades.deployProxy(Collateral, [SWAN_CHAIN_SWAN], {
  //     initializer: 'initialize',
  //   })
  //   await collateral.waitForDeployment()

  //   console.log('Collateral Contract deployed to:', await collateral.getAddress())

  const collateral = Collateral.attach(
    '0x494E750c3ED3AD9e2fcD8aEEDf54b2D98Bd8B1dA',
  )

  console.log('Deploying Bidding Contract...')

  const bidding = await upgrades.deployProxy(
    Bidding,
    [AR_WALLET, AP_WALLET, collateral.target, weth.target],
    {
      initializer: 'initialize',
    },
  )
  await bidding.waitForDeployment()

  console.log('Bidding Contract deployed to:', await bidding.getAddress())

  console.log('Setting Bidding Contract as Collateral Admin')
  let tx = await collateral.addAdmin(bidding.target)
  await tx.wait()
  console.log(tx.hash)

  console.log('Setting Admin as Bidding Admin')
  let tx2 = await bidding.addAdmin(ADMIN_WALLET)
  await tx2.wait()
  console.log(tx2.hash)

  console.log('Approving spending for Bidding of AP funds')
  let accounts = await ethers.getSigners()
  let tx3 = await weth
    .connect(accounts[1])
    .approve(bidding.target, ethers.MaxInt256)
  console.log(tx3.hash)
}

main()
