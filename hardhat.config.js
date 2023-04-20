/** @type import('hardhat/config').HardhatUserConfig */
require('@nomiclabs/hardhat-waffle')
require('dotenv').config()

module.exports = {
  solidity: {
    version: '0.8.17',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
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
    },
    bsc: {
      url: 'https://data-seed-prebsc-1-s2.binance.org:8545',
      accounts: [process.env.private_key],
    },
  },
}
