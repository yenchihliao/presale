require("@nomiclabs/hardhat-waffle");
// require("hardhat-contract-sizer");
require("dotenv").config();
require("@nomiclabs/hardhat-etherscan");
require("@openzeppelin/hardhat-upgrades");
// require("solidity-coverage");

const privateKey = process.env.PRIVATE_KEY.split(", ");
const etherscanApiKey = process.env.ETHERSCAN_API_KEY;
const infuraProjectId = process.env.INFURA_PROJECT_ID;

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  networks: {
    "taisys-dev": {
      url: "https://dev-rpc.taisys.dev",
      chainId: 1182,
      accounts: privateKey,
    },
    "vegas-stg": {
      url: "https://stg-rpc.vegas.one",
      chainId: 1268,
      accounts: privateKey,
    },
    "vegas-testnet": {
      url: "https://testnet-rpc.vegas.one",
      chainId: 1272,
      accounts: privateKey,
    },
    goerli: {
      url: `https://goerli.infura.io/v3/${infuraProjectId}`,
      chainId: 5,
      accounts: privateKey,
    },
  },
  etherscan: {
    apiKey: {
      "taisys-dev": "api-key",
      "vegas-stg": "api-key",
      "vegas-testnet": "api-key",
      goerli: etherscanApiKey,
    },
    customChains: [
      {
        network: "taisys-dev",
        chainId: 1182,
        urls: {
          apiURL: "https://dev-explorer.taisys.dev/api",
          browserURL: "https://dev-explorer.taisys.dev/",
        },
      },
      {
        network: "vegas-stg",
        chainId: 1268,
        urls: {
          apiURL: "https://stg-explorer.vegas.one/api",
          browserURL: "https://stg-explorer.vegas.one/",
        },
      },
      {
        network: "vegas-testnet",
        chainId: 1272,
        urls: {
          apiURL: "https://testnet-explorer.vegas.one/api",
          browserURL: "https://testnet-explorer.vegas.one/",
        },
      },
    ],
  },
  solidity: {
    compilers: [
      {
        version: "0.8.4",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
};
