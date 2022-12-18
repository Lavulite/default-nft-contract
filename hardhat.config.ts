import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-etherscan";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true
      },
      viaIR: true
    }
  },
  networks: {
    hardhat: {},
  },
  etherscan: {
    apiKey: {
      mainnet: process.env['ETHSCAN_API'] || '',
      goerli: process.env['ETHSCAN_API'] || '',
      polygon: process.env['POLYGONSCAN_API'] || '',
      polygonMumbai: process.env['POLYGONSCAN_API'] || '',

    },
  }
};

if (process.env.ALCHEMY_KEY) {
  config.networks!.mainnet = {
    url: "https://eth-mainnet.g.alchemy.com/v2/" + process.env.ALCHEMY_KEY,
    accounts: [`${process.env.PRIVATE_KEY}`],
  }
  config.networks!.goerli = {
    url: "https://eth-goerli.g.alchemy.com/v2/" + process.env.ALCHEMY_KEY,
    accounts: [`${process.env.PRIVATE_KEY}`],
  }
  config.networks!.mumbai = {
    url: "https://polygon-mumbai.g.alchemy.com/v2/" + process.env.ALCHEMY_KEY,
    accounts: [`${process.env.PRIVATE_KEY}`],
  }
}

export default config;