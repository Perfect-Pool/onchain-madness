require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-waffle");
require("@nomicfoundation/hardhat-verify");
require("dotenv").config();

const privateKey = process.env.PRIVATE_KEY;

module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  defaultNetwork: "hardhat",
  networks: {
    "base-testnet": {
      url: process.env.BASE_TESTNET_RPC_URL,
      accounts: [privateKey],
      chainId: parseInt(process.env.BASE_TESTNET_CHAIN_ID),
    },
    base: {
      url: process.env.BASE_RPC_URL,
      accounts: [privateKey],
      chainId: parseInt(process.env.BASE_CHAIN_ID),
    },
  },
  etherscan: {
    apiKey: {
      base: process.env.BASE_BLOCK_EXPLORER_API_KEY,
      "base-testnet": process.env.BASE_TESTNET_BLOCK_EXPLORER_API_KEY,
    },
    customChains: [
      {
        network: "base-testnet",
        chainId: parseInt(process.env.BASE_TESTNET_CHAIN_ID),
        urls: {
          apiURL: process.env.BASE_TESTNET_BLOCK_EXPLORER_API_URL,
          browserURL: process.env.BASE_TESTNET_BLOCK_EXPLORER_URL,
        },
      },
      {
        network: "base",
        chainId: parseInt(process.env.BASE_CHAIN_ID),
        urls: {
          apiURL: process.env.BASE_BLOCK_EXPLORER_API_URL,
          browserURL: process.env.BASE_BLOCK_EXPLORER_URL,
        },
      },
    ],
  },
};
