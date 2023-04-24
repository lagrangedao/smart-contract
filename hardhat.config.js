/** @type import('hardhat/config').HardhatUserConfig */
require('@nomiclabs/hardhat-waffle')
require('@nomiclabs/hardhat-etherscan')
require('dotenv').config()
require('./tasks/mint')

module.exports = {
  solidity: {
    compilers: [
      {
        version: '0.8.7',
        settings: {
          optimizer: {
            enabled: true,
            runs: 1_000,
          },
        },
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
  defaultNetwork: 'hyperspace',
  networks: {
    hyperspace: {
      url: 'https://api.hyperspace.node.glif.io/rpc/v1',
      accounts: [process.env.private_key],
    },
    mumbai: {
      url: process.env.rpc_endpoint,
      accounts: [process.env.private_key],
      oracleAddress: '0xeA6721aC65BCeD841B8ec3fc5fEdeA6141a0aDE4',
    },
    bsc: {
      url: 'https://data-seed-prebsc-1-s2.binance.org:8545',
      accounts: [process.env.private_key],
    },
  },
  etherscan: {
    apiKey: {
      polygonMumbai: process.env.POLYGONSCAN_API_KEY,
    },
  },
}
