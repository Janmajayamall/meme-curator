const { waffle, ethers } = require("hardhat");
const { BigNumber } = ethers;
const { expect } = require("chai");


function getBigNumber(amount, decimals = 18) {
	return BigNumber.from(amount).mul(BigNumber.from(10).pow(decimals));
}

describe("Market", function () {
	before(async function () {
		this.Market = await ethers.getContractFactory("Market");
		this.MarketFactory = await ethers.getContractFactory("MarketFactory");
		this.OracleMultiSig = await ethers.getContractFactory("OracleMultiSig");
		this.MemeToken = await ethers.getContractFactory("MemeToken");

		// prepare accounts
		this.signers = await ethers.getSigners();
		this.owner = this.signers[0];
		this.marketCreator = this.signers[1];
		this.moderator = this.signers[2];
		this.trader1 = this.signers[3];
		this.trader2 = this.signers[4];
	});

	beforeEach(async function () {
		this.marketFactory = await this.MarketFactory.deploy();
		console.log("market factory deployed");
		this.memeToken = await this.MemeToken.deploy();
		console.log("meme token deployed");
		this.oracleMultiSig = await this.OracleMultiSig.deploy(
			[this.owner.address],
			"1",
			"10"
		);
		console.log("oracle multisig token deployed");

		/* 
        Mint tokens for users
        */
		this.memeToken.mint(this.marketCreator.address, getBigNumber(100));
		this.memeToken.mint(this.trader1.address, getBigNumber(100));
		this.memeToken.mint(this.trader2.address, getBigNumber(100));
		console.log("meme token minted");
		/* 
        Setup oracle
        & mutisig
        */
		await this.oracleMultiSig.addTxSetupOracle(
			true,
			"3",
			"100",
			this.memeToken.address,
			"50",
			"5",
			"25",
			"25"
		);

		// create a new market
		this.memeToken.approve(this.marketFactory.address, getBigNumber(10));
		this.market = this.marketFactory.createMarket(
			this.marketCreator,
			this.oracleMultiSig.address,
			ethers.utils.formatBytes32String("aiwdjaoid"),
			getBigNumber(10)
		);
		console.log(
			"good good ******************************************************************************"
		);
	});

	/* 
    1. Market funding
    2. Trades
    
    */

	it("shoud do something", function () {
		expect("10").to.eq("10");
	});
	// describe("MarketFunding", function () {

	// });
});
