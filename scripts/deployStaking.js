const { ethers, upgrades } = require('hardhat')

const AR_WALLET = '0x47846473daE8fA6E5E51e03f12AbCf4F5eDf9Bf5'
const AP_WALLET = '0x4BC1eE66695AD20771596290548eBE5Cfa1Be332'
const ADMIN_WALLET = '0x29eD49c8E973696D07E7927f748F6E5Eacd5516D'

const SWAN_CHAIN_SWAN = '0x91B25A65b295F0405552A4bbB77879ab5e38166c'

const COLLATERAL = ''
const BIDDING = ''

async function main() {
  const Collateral = await ethers.getContractFactory('CollateralContract')
  const Bidding = await ethers.getContractFactory('BiddingContract')
  const Swan = await ethers.getContractFactory('Token')
  let swan = Swan.attach(SWAN_CHAIN_SWAN)
  let collateral = ''
  let bidding = ''

  if (COLLATERAL) {
    console.log('Attaching Collateral Contract...')
    collateral = Collateral.attach(COLLATERAL)
  } else {
    console.log('Deploying Collateral Contract...')
    collateral = await upgrades.deployProxy(Collateral, [], {
      initializer: 'initialize',
    })
    await collateral.waitForDeployment()
  }

  console.log('Collateral Contract deployed to:', await collateral.getAddress())

  if (BIDDING) {
    console.log('Attaching Bidding Contract...')
    bidding = Bidding.attach(BIDDING)
  } else {
    console.log('Deploying Bidding Contract...')
    bidding = await upgrades.deployProxy(
      Bidding,
      [AR_WALLET, AP_WALLET, collateral.target, SWAN_CHAIN_SWAN],
      {
        initializer: 'initialize',
      },
    )
    await bidding.waitForDeployment()
  }

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
  let tx3 = await swan
    .connect(accounts[1])
    .approve(bidding.target, ethers.MaxInt256)
  console.log(tx3.hash)
}

main()
