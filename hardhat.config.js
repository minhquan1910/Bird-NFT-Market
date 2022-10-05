require("@nomiclabs/hardhat-waffle");
require('dotenv').config()

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "hardhat",
  networks:{
    hardhat:{
      chainId: 1337 //Default chain
    },
    ropsten:{
      url: `https://ropsten.infura.io/v3/${process.env.PROJECT_ID}`,
      accounts:[process.env.PRIVATE_KEY]
    },
    mainnet:{
      url: `https://mainnet.infura.io/v3/${process.env.PROJECT_ID}`,
      accounts:[process.env.PRIVATE_KEY]
    }
  },
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
};
