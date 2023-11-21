/** @type import('hardhat/config').HardhatUserConfig */
require('@nomiclabs/hardhat-ethers')
require('@openzeppelin/hardhat-upgrades')
require('dotenv').config()
require('@nomicfoundation/hardhat-verify')
require('@nomicfoundation/hardhat-chai-matchers')

module.exports = {
  solidity: {
    compilers: [
      {
        version: '0.8.9',
      },
      {
        version: '0.8.19',
      },
      {
        version: '0.8.20',
      },
      {
        version: '0.6.6',
        settings: {
          optimizer: {
            enabled: true,
            runs: 1_000,
          },
        },
      },
      {
        version: '0.4.24',
        settings: {
          optimizer: {
            enabled: true,
            runs: 1_000,
          },
        },
      },
    ],
  },
  networks: {
    hyperspace: {
      url: 'https://api.hyperspace.node.glif.io/rpc/v1',
      accounts: [process.env.private_key],
    },
    mumbai: {
      url: process.env.MUMBAI_RPC,
      accounts: [process.env.PRIVATE_KEY],
    },
    bsc: {
      url: 'https://data-seed-prebsc-1-s2.binance.org:8545',
      accounts: [process.env.PRIVATE_KEY],
    },
    sepolia: {
      url: 'https://rpc2.sepolia.org',
      accounts: [process.env.private_key],
    },
    opswan: {
      url: 'http://34.95.38.202:8545',
      accounts: [process.env.PRIVATE_KEY],
      chainId: 8598668088,
    },
    tbsc: {
      url: 'https://bsc-testnet.publicnode.com',
      accounts: [process.env.PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: {
      polygonMumbai: process.env.POLYGONSCAN_API_KEY,
      sepolia: process.env.ETHERSCAN_API_KEY,
      bscTestnet: process.env.BSCSCAN_API_KEY,
    },
    customChains: [
      {
        network: 'opswan',
        chainId: 8598668088,
        urls: {
          apiURL: 'http://34.130.248.50/api',
          browserURL: 'http://34.130.248.50',
        },
      },
    ],
  },
}
