import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  etherscan: {
    apiKey: process.env.POLYGONSCAN_MUMBAI_API
  },
  networks: {
    mumbai : {
       url: `https://polygon-mumbai.g.alchemy.com/v2/${process.env.TBL_ALCHEMY}`,
      // url: `https://polygon-mumbai.infura.io/v3/<projId>`,

      accounts: [process.env.TBL_PRIVATE_KEY || ""]
    }
  }
};

export default config;
