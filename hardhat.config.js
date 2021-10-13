require("@nomiclabs/hardhat-waffle");
require("hardhat-contract-sizer");

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
	// solidity: "0.8.4",
	solidity: {
		compilers: [
			{
				version: "0.8.4",
			},
			{
				version: "0.7.0",
			},
		],
	},
	contractSizer: {
		alphaSort: true,
		disambiguatePaths: false,
		runOnCompile: false,
		strict: false,
	},
	networks: {
		hardhat: {
			gas: 12000000,
			blockGasLimit: 0x1fffffffffffff,
			allowUnlimitedContractSize: true,
			timeout: 1800000,
		},
	},
};
