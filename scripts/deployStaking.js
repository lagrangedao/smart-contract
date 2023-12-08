const { ethers, upgrades } = require('hardhat')

const AR_WALLET = '0x47846473daE8fA6E5E51e03f12AbCf4F5eDf9Bf5'
const AP_WALLET = '0x4BC1eE66695AD20771596290548eBE5Cfa1Be332'
const ADMIN_WALLET = '0x29eD49c8E973696D07E7927f748F6E5Eacd5516D'

const SWAN_CHAIN_USDC = '0x0c1a5A0Cd0Bb4A9F564f09Cc66f4c921B560371a'
const SWAN_CHAIN_SWAN = '0x407a5856050053CF1DB54113bd9Ea9D2Eeee7C35'

const SWAP = '0x9b89AA8ed8eF4EDeAAd266F58dfec09864bbeC1f'

async function main() {
  const Collateral = await ethers.getContractFactory('CollateralContract')
  const Bidding = await ethers.getContractFactory('BiddingContract')
  const USDC = await ethers.getContractFactory('USDC')
  const usdc = USDC.attach(SWAN_CHAIN_USDC)

  console.log('Deploying Collateral Contract...')

  //   const collateral = await upgrades.deployProxy(Collateral, [SWAN_CHAIN_SWAN], {
  //     initializer: 'initialize',
  //   })
  //   await collateral.waitForDeployment()

  //   console.log('Collateral Contract deployed to:', await collateral.getAddress())

  const collateral = Collateral.attach(
    '0xaAea25dF7D20f2098B816486880E4b706DD57044',
  )

  console.log('Deploying Bidding Contract...')

  const bidding = await upgrades.deployProxy(
    Bidding,
    [
      AR_WALLET,
      AP_WALLET,
      collateral.target,
      SWAN_CHAIN_USDC,
      SWAN_CHAIN_SWAN,
      SWAP,
    ],
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
  let tx3 = await usdc
    .connect(accounts[1])
    .approve(bidding.target, ethers.MaxInt256)
  console.log(tx3.hash)
}

main()
