const { ethers, upgrades } = require('hardhat')

const AR_WALLET = '0x47846473daE8fA6E5E51e03f12AbCf4F5eDf9Bf5'
const AP_WALLET = '0x4BC1eE66695AD20771596290548eBE5Cfa1Be332'
const ADMIN_WALLET = '0x29eD49c8E973696D07E7927f748F6E5Eacd5516D'

// const SWAN_CHAIN_USDC = '0x0c1a5A0Cd0Bb4A9F564f09Cc66f4c921B560371a'
const SWAN_CHAIN_SWAN = '0x91B25A65b295F0405552A4bbB77879ab5e38166c'

// const SWAP = '0xaAc390a1A1C1BCF35261181207Ecf6f565dbacb5'

async function main() {
  const Collateral = await ethers.getContractFactory('NativeCollateralContract')
  const Bidding = await ethers.getContractFactory('BiddingContract')
  const Swan = await ethers.getContractFactory('Token')
  let swan = Swan.attach(SWAN_CHAIN_SWAN)

  console.log('Deploying Collateral Contract...')

  const collateral = await upgrades.deployProxy(Collateral, [], {
    initializer: 'initialize',
  })
  await collateral.waitForDeployment()

  console.log('Collateral Contract deployed to:', await collateral.getAddress())
  console.log('Deploying Bidding Contract...')

  const bidding = await upgrades.deployProxy(
    Bidding,
    [AR_WALLET, AP_WALLET, collateral.target, SWAN_CHAIN_SWAN],
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
  let tx3 = await swan
    .connect(accounts[1])
    .approve(bidding.target, ethers.MaxInt256)
  console.log(tx3.hash)
}

main()
