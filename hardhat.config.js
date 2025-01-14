require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: "0.8.28",
    defaultNetwork: 'hardhat',
    solidity: {
        compilers: [
            {
                version: '0.8.28'
            }
        ]
    },
    networks: {
        hardhat: {
            forking: {
                live: false,
                saveDeployments: false,
                accounts: [],
                url: process.env.MAINNET_NODE || "https://rpc.ankr.com/eth"
            }
        }

    },
    mocha: {
        timeout: 60000
    }
};