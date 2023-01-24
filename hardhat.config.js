require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const ALCHEMY_API_KEY = "exM95Sk_YW9zznpK7dh2jq8saTWOHOi0"
const MAINNET_PRIVATE_KEY = "6371b9991fc67f8cdca977e5e0c098872e5e1d64f55a5ff8be2058e3948e9df1";
const ETHERSCAN_API_KEY = "VM5EU43EPWVHHXBIJDQ4NEHKFFVYZMCFHD";
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.17",
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: `${ETHERSCAN_API_KEY}`,
  },
  networks: {
    goerli: {
      url: `https://eth-goerli.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
      accounts: [`${MAINNET_PRIVATE_KEY}`]
    },
    bsc_testnet: {
      url: `https://endpoints.omniatech.io/v1/bsc/testnet/public`,
      accounts: [`${MAINNET_PRIVATE_KEY}`]
    }
  }
};
