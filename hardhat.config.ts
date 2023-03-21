import 'dotenv/config'
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.0",
  networks: {
    goerli: {
      url: process.env.ALCHEMY_GOERLI_URL,
      accounts:[process.env.GOERLI_WALLET_PRIVATE_KEY!]
    }
  }
};

export default config;
