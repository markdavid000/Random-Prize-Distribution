// import { HardhatUserConfig } from "hardhat/config";
require("dotenv").config();
import "@nomicfoundation/hardhat-toolbox";

module.exports = {
  solidity: "0.8.24",
  networks: {
    mumbai: {
      url: process.env.TESTNET_RPC,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
};
