// const { waffle, ethers } = require("hardhat");
// const { BigNumber } = ethers;
// const { expect } = require("chai");

// function getBigNumber(amount, decimals = 18) {
// 	return BigNumber.from(amount).mul(BigNumber.from(10).pow(decimals));
// }

// async function checkTokenBalances(thisRef, eTokenC, eToken0, eToken1, address) {
// 	// check token balances of market
// 	const tokenCAddress = await thisRef.market.tokenC();
// 	const token0Address = await thisRef.market.token0();
// 	const token1Address = await thisRef.market.token1();
// 	expect(
// 		await thisRef.MemeToken.attach(tokenCAddress).balanceOf(address)
// 	).to.eq(getBigNumber(eTokenC));
// 	expect(
// 		await thisRef.OutcomeToken.attach(token0Address).balanceOf(address)
// 	).to.eq(getBigNumber(eToken0));
// 	expect(
// 		await thisRef.OutcomeToken.attach(token1Address).balanceOf(address)
// 	).to.eq(getBigNumber(eToken1));
// }
// async function checkReservesTokenC(
// 	thisRef,
// 	eReserveC,
// 	eReserveDoN0,
// 	eReserveDoN1
// ) {
// 	const tokenCReserves = await thisRef.market.getReservesTokenC();
// 	expect(tokenCReserves[0]).to.eq(getBigNumber(eReserveC));
// 	expect(tokenCReserves[1]).to.eq(getBigNumber(eReserveDoN0));
// 	expect(tokenCReserves[2]).to.eq(getBigNumber(eReserveDoN1));
// }

// async function checkReservesOTokens(thisRef, eReserve0, eReserve1) {
// 	const tokenOReserves = await thisRef.market.getReservesOTokens();
// 	expect(tokenOReserves[0]).to.eq(getBigNumber(eReserve0));
// 	expect(tokenOReserves[1]).to.eq(getBigNumber(eReserve1));
// }

// async function transferTokens(contract, owner, toAddress, amount) {
// 	await contract.connect(owner).transfer(toAddress, getBigNumber(amount));
// }

// async function approveTokens(contract, owner, toAddress, amount) {
// 	await contract.connect(owner).approve(toAddress, getBigNumber(amount));
// }

// describe("Market", function () {
// 	const fundAmount = 10;
// 	const identifier = ethers.utils.formatBytes32String("awdadawbda");
// 	const startingBalance = 100;

// 	before(async function () {
// 		this.Market = await ethers.getContractFactory("Market");
// 		this.MarketFactory = await ethers.getContractFactory("MarketFactory");
// 		this.OracleMultiSig = await ethers.getContractFactory("OracleMultiSig");
// 		this.MemeToken = await ethers.getContractFactory("MemeToken");
// 		this.OutcomeToken = await ethers.getContractFactory("OutcomeToken");

// 		// prepare accounts
// 		this.signers = await ethers.getSigners();
// 		this.owner = this.signers[0];
// 		this.marketCreator = this.signers[1];
// 		this.moderator = this.signers[2];
// 		this.trader1 = this.signers[3];
// 		this.trader2 = this.signers[4];
// 	});

// 	beforeEach(async function () {
// 		this.marketFactory = await this.MarketFactory.deploy();
// 		this.memeToken = await this.MemeToken.deploy();
// 		this.oracleMultiSig = await this.OracleMultiSig.deploy(
// 			[this.owner.address],
// 			"1",
// 			"10"
// 		);

// 		/*
//         Mint tokens for users
//         */
// 		this.memeToken.mint(
// 			this.marketCreator.address,
// 			getBigNumber(startingBalance)
// 		);
// 		this.memeToken.mint(
// 			this.trader1.address,
// 			getBigNumber(startingBalance)
// 		);
// 		this.memeToken.mint(
// 			this.trader2.address,
// 			getBigNumber(startingBalance)
// 		);

// 		/*
//         Setup oracle & mutisig
//         */
// 		await this.oracleMultiSig.addTxSetupOracle(
// 			true,
// 			"3",
// 			"100",
// 			this.memeToken.address,
// 			"50",
// 			"5",
// 			"25",
// 			"25"
// 		);

// 		/*
// 		Create a new market by marketCreator user & fund it
// 		 */
// 		await this.memeToken
// 			.connect(this.marketCreator)
// 			.approve(this.marketFactory.address, getBigNumber(fundAmount));
// 		await this.marketFactory
// 			.connect(this.marketCreator)
// 			.createMarket(
// 				this.marketCreator.address,
// 				this.oracleMultiSig.address,
// 				identifier,
// 				getBigNumber(fundAmount)
// 			);
// 		// get market address
// 		const marketAddress = await this.marketFactory.markets(
// 			this.marketCreator.address,
// 			this.oracleMultiSig.address,
// 			identifier
// 		);
// 		this.market = await this.Market.attach(marketAddress);
// 	});

// 	/*
//     1. Market funding
//     2. Trades
//     3.
//     */

// 	it("Should fund market ", async function () {
// 		// check market stage should be MarketFunded
// 		expect(await this.market.stage()).to.eq(1);

// 		await checkTokenBalances(
// 			this,
// 			fundAmount,
// 			fundAmount,
// 			fundAmount,
// 			this.market.address
// 		);
// 		await checkReservesTokenC(this, fundAmount, 0, 0);
// 		await checkReservesOTokens(this, fundAmount, fundAmount);
// 	});

// 	it("Should trade one token for another", async function () {
// 		const buyAmount = 5;
// 		await transferTokens(
// 			this.memeToken,
// 			this.trader1,
// 			this.market.address,
// 			buyAmount
// 		);
// 		await this.market.buy(
// 			getBigNumber(buyAmount),
// 			getBigNumber(0),
// 			this.trader1.address
// 		);
// 		await checkTokenBalances(
// 			this,
// 			fundAmount + buyAmount,
// 			fundAmount,
// 			fundAmount,
// 			this.market.address
// 		);
// 		await checkTokenBalances(
// 			this,
// 			startingBalance - buyAmount,
// 			buyAmount,
// 			buyAmount,
// 			this.trader1.address
// 		);
// 		await checkReservesTokenC(this, fundAmount + buyAmount, 0, 0);
// 		await checkReservesOTokens(this, fundAmount, fundAmount);
// 	});

// 	// describe("MarketFunding", function () {

// 	// });
// });

// // 1. Write tests for market.sol
// // 2. Fill up application form Mirror.xyz

// // console.log(
// // 	`allowance from market creator factor ${await this.memeToken.allowance(
// // 		this.marketCreator.address,
// // 		this.marketFactory.address
// // 	)}`
// // );

// // console.log(`meme token address ${this.memeToken.address}`);

// // console.log(
// // 	`balance of market creator ${await this.memeToken.balanceOf(
// // 		this.marketCreator.address
// // 	)}`
// // );
