const { ethers, upgrades } = require('hardhat')

const AR_WALLET = '0x47846473daE8fA6E5E51e03f12AbCf4F5eDf9Bf5'
const AP_WALLET = '0x4BC1eE66695AD20771596290548eBE5Cfa1Be332'

const SWAN_CHAIN_USDC = '0xc648B1a7645FA706B52B1dFC799e7B2b487c08AD'
const SWAN_CHAIN_SWAN = '0xc648B1a7645FA706B52B1dFC799e7B2b487c08AD'

const SWAP = '0xaAc390a1A1C1BCF35261181207Ecf6f565dbacb5'

async function main() {
  const Collateral = await ethers.getContractFactory('CollateralContract')
  const Bidding = await ethers.getContractFactory('BiddingContract')

  //   console.log('Deploying Collateral Contract...')

  //   const collateral = await upgrades.deployProxy(Collateral, [SWAN_CHAIN_SWAN], {
  //     initializer: 'initialize',
  //   })
  //   await collateral.waitForDeployment()

  //   console.log('Collateral Contract deployed to:', await collateral.getAddress())

  console.log('Deploying Bidding Contract...')

  const bidding = await upgrades.deployProxy(
    Bidding,
    [
      AR_WALLET,
      AP_WALLET,
      '0x05affDe63dC23bc629D8b1b9Ccc04A8fb758e6C3',
      SWAN_CHAIN_USDC,
      SWAN_CHAIN_USDC,
      SWAP,
    ],
    {
      initializer: 'initialize',
    },
  )
  await bidding.waitForDeployment()

  console.log('Bidding Contract deployed to:', await bidding.getAddress())

  //   console.log('Setting Bidding Contract as Collateral Admin')
  //   let tx = await collateral.addAdmin(bidding.target)
  //   await tx.wait()
  //   console.log(tx.hash)
}

main()
