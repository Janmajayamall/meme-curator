const { waffle, ethers } = require("hardhat");
const { BigNumber } = ethers;
const { expect } = require("chai");

function addBN(x, y) {
	return BigNumber.from(x).add(BigNumber.from(y));
}

function subBN(x, y) {
	return BigNumber.from(x).sub(BigNumber.from(y));
}

function getBigNumber(amount, decimals = 18) {
	return BigNumber.from(amount).mul(BigNumber.from(10).pow(decimals));
}

async function checkTokenBalances(thisRef, eTokenC, eToken0, eToken1, address) {
	// check token balances of market
	const tokenCAddress = await thisRef.market.tokenC();
	const token0Address = await thisRef.market.token0();
	const token1Address = await thisRef.market.token1();
	expect(
		await thisRef.MemeToken.attach(tokenCAddress).balanceOf(address)
	).to.eq(eTokenC);
	expect(
		await thisRef.OutcomeToken.attach(token0Address).balanceOf(address)
	).to.eq(eToken0);
	expect(
		await thisRef.OutcomeToken.attach(token1Address).balanceOf(address)
	).to.eq(eToken1);
}

async function getTokenBalances(thisRef, address) {
	// check token balances of market
	const tokenCAddress = await thisRef.market.tokenC();
	const token0Address = await thisRef.market.token0();
	const token1Address = await thisRef.market.token1();
	return Promise.all([
		thisRef.MemeToken.attach(tokenCAddress).balanceOf(address),
		thisRef.OutcomeToken.attach(token0Address).balanceOf(address),
		thisRef.OutcomeToken.attach(token1Address).balanceOf(address),
	]);
}

async function checkReservesTokenC(
	thisRef,
	eReserveC,
	eReserveDoN0,
	eReserveDoN1
) {
	const tokenCReserves = await thisRef.market.getReservesTokenC();
	expect(tokenCReserves[0]).to.eq(eReserveC);
	expect(tokenCReserves[1]).to.eq(eReserveDoN0);
	expect(tokenCReserves[2]).to.eq(eReserveDoN1);
}

async function checkReservesOTokens(thisRef, eReserve0, eReserve1) {
	const tokenOReserves = await thisRef.market.getReservesOTokens();
	expect(tokenOReserves[0]).to.eq(eReserve0);
	expect(tokenOReserves[1]).to.eq(eReserve1);
}

async function logReservesOTokens(thisRef) {
	const tokenOReserves = await thisRef.market.getReservesOTokens();
	console.log(
		`r0 - ${tokenOReserves[0].toString()}, r1 - ${tokenOReserves[1].toString()} rP - ${BigNumber.from(
			tokenOReserves[0]
		)
			.mul(BigNumber.from(tokenOReserves[1]))
			.toString()}`
	);
}

async function transferTokens(contract, owner, toAddress, amount) {
	await contract.connect(owner).transfer(toAddress, amount);
}

async function approveTokens(contract, owner, toAddress, amount) {
	await contract.connect(owner).approve(toAddress, amount);
}

async function buyTrade(thisRef, a0, a1) {
	console.log(
		`******************************BUY OPERATION************************************`
	);
	var tokenBalances = await getTokenBalances(thisRef, thisRef.market.address);
	var userTokenBalances = await getTokenBalances(
		thisRef,
		thisRef.trader1.address
	);

	var reservesO = await thisRef.market.getReservesOTokens();
	var reservesC = await thisRef.market.getReservesTokenC();

	expect(reservesC[0]).to.eq(tokenBalances[0]);
	expect(reservesO[0]).to.eq(tokenBalances[1]);
	expect(reservesO[1]).to.eq(tokenBalances[2]);

	await logReservesOTokens(thisRef);

	var amount = await thisRef.mathTest.getAmountCToBuyTokens(
		a0,
		a1,
		reservesO[0],
		reservesO[1]
	);
	await transferTokens(
		thisRef.memeToken,
		thisRef.trader1,
		thisRef.market.address,
		amount
	);
	await thisRef.market.buy(a0, a1, thisRef.trader1.address);

	await checkTokenBalances(
		thisRef,
		addBN(tokenBalances[0], amount),
		subBN(addBN(tokenBalances[1], amount), a0),
		subBN(addBN(tokenBalances[2], amount), a1),
		thisRef.market.address
	);

	// check token balances of user
	await checkTokenBalances(
		thisRef,
		subBN(userTokenBalances[0], amount),
		addBN(userTokenBalances[1], a0),
		addBN(userTokenBalances[2], a1),
		thisRef.trader1.address
	);

	await checkReservesTokenC(thisRef, addBN(tokenBalances[0], amount), 0, 0);
	await checkReservesOTokens(
		thisRef,
		subBN(addBN(tokenBalances[1], amount), a0),
		subBN(addBN(tokenBalances[2], amount), a1)
	);
	await logReservesOTokens(thisRef);
	console.log(
		`******************************BUY OPERATION XXXXX************************************`
	);
}

async function sellTrade(thisRef, a0, a1) {
	console.log(
		`******************************SELL OPERATION************************************`
	);
	var tokenBalances = await getTokenBalances(thisRef, thisRef.market.address);
	var userTokenBalances = await getTokenBalances(
		thisRef,
		thisRef.trader1.address
	);

	var reservesO = await thisRef.market.getReservesOTokens();
	var reservesC = await thisRef.market.getReservesTokenC();

	expect(reservesC[0]).to.eq(tokenBalances[0]);
	expect(reservesO[0]).to.eq(tokenBalances[1]);
	expect(reservesO[1]).to.eq(tokenBalances[2]);

	await logReservesOTokens(thisRef);

	var amount = await thisRef.mathTest.getAmountCBySellTokens(
		a0,
		a1,
		reservesO[0],
		reservesO[1]
	);
	console.log(amount.toString());

	// transfer outcome tokens
	const tokenCAddress = await thisRef.market.tokenC();
	const token0Address = await thisRef.market.token0();
	const token1Address = await thisRef.market.token1();
	await transferTokens(
		thisRef.OutcomeToken.attach(token0Address),
		thisRef.trader1,
		thisRef.market.address,
		a0
	);
	await transferTokens(
		thisRef.OutcomeToken.attach(token1Address),
		thisRef.trader1,
		thisRef.market.address,
		a1
	);
	await thisRef.market.sell(amount, thisRef.trader1.address);

	await checkTokenBalances(
		thisRef,
		subBN(tokenBalances[0], amount),
		subBN(addBN(tokenBalances[1], a0), amount),
		subBN(addBN(tokenBalances[2], a1), amount),
		thisRef.market.address
	);

	// check token balances of user
	await checkTokenBalances(
		thisRef,
		addBN(userTokenBalances[0], amount),
		subBN(userTokenBalances[1], a0),
		subBN(userTokenBalances[2], a1),
		thisRef.trader1.address
	);

	await checkReservesTokenC(thisRef, subBN(tokenBalances[0], amount), 0, 0);
	await checkReservesOTokens(
		thisRef,
		subBN(addBN(tokenBalances[1], a0), amount),
		subBN(addBN(tokenBalances[2], a1), amount)
	);
	await logReservesOTokens(thisRef);
	console.log(
		`******************************SELL OPERATION XXXXX************************************`
	);
}

describe("Market", function () {
	const fundAmount = 10;
	const identifier = ethers.utils.formatBytes32String("awdadawbda");
	const startingBalance = 100;

	before(async function () {
		this.Market = await ethers.getContractFactory("Market");
		this.MarketFactory = await ethers.getContractFactory("MarketFactory");
		this.OracleMultiSig = await ethers.getContractFactory("OracleMultiSig");
		this.MemeToken = await ethers.getContractFactory("MemeToken");
		this.OutcomeToken = await ethers.getContractFactory("OutcomeToken");
		this.MathTest = await ethers.getContractFactory("MathTest");

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
		this.memeToken = await this.MemeToken.deploy();
		this.oracleMultiSig = await this.OracleMultiSig.deploy(
			[this.owner.address],
			"1",
			"10"
		);
		this.mathTest = await this.MathTest.deploy();

		/*
        Mint tokens for users
        */
		this.memeToken.mint(
			this.marketCreator.address,
			getBigNumber(startingBalance)
		);
		this.memeToken.mint(
			this.trader1.address,
			getBigNumber(startingBalance)
		);
		this.memeToken.mint(
			this.trader2.address,
			getBigNumber(startingBalance)
		);

		/*
        Setup oracle & mutisig
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

		/*
		Create a new market by marketCreator user & fund it
		 */
		await this.memeToken
			.connect(this.marketCreator)
			.approve(this.marketFactory.address, getBigNumber(fundAmount));
		await this.marketFactory
			.connect(this.marketCreator)
			.createMarket(
				this.marketCreator.address,
				this.oracleMultiSig.address,
				identifier,
				getBigNumber(fundAmount)
			);
		// get market address
		const marketAddress = await this.marketFactory.markets(
			this.marketCreator.address,
			this.oracleMultiSig.address,
			identifier
		);
		this.market = await this.Market.attach(marketAddress);
	});

	/*
    1. Market funding
    2. Trades
    3.
    */

	it("Should fund market ", async function () {
		// check market stage should be MarketFunded
		expect(await this.market.stage()).to.eq(1);

		await checkTokenBalances(
			this,
			getBigNumber(fundAmount),
			getBigNumber(fundAmount),
			getBigNumber(fundAmount),
			this.market.address
		);
		await checkReservesTokenC(this, getBigNumber(fundAmount), 0, 0);
		await checkReservesOTokens(
			this,
			getBigNumber(fundAmount),
			getBigNumber(fundAmount)
		);
	});

	it("Should pass all buys & sells", async function () {
		await buyTrade(this, getBigNumber(0), getBigNumber(5));
		await sellTrade(this, getBigNumber(0), getBigNumber(4));
		await buyTrade(this, getBigNumber(2), getBigNumber(5));
		await buyTrade(this, getBigNumber(12), getBigNumber(4));
		await buyTrade(this, getBigNumber(0), getBigNumber(5));
		await sellTrade(this, getBigNumber(10), getBigNumber(0));
	});

	// Should fail for violating invariant during buy & sell

	// it("Should fail for exceeding outcome limit during sell"){}

	// Should fail exceeding tokenC limit during buy

	describe("MarketFunding", function () {});
});
