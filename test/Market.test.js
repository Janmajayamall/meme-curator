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

async function advanceBlocksBy(blocks) {
	for (let i = 0; i < blocks; i++) {
		await ethers.provider.send("evm_mine", []);
	}
}

async function checkTokenBalances(thisRef, eTokenC, eToken0, eToken1, address) {
	// check token balances of market
	const tokenAddresses = await thisRef.market.getAddressOfTokens();
	const tokenCAddress = tokenAddresses[0];
	const token0Address = tokenAddresses[1];
	const token1Address = tokenAddresses[2];
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
	const tokenAddresses = await thisRef.market.getAddressOfTokens();
	const tokenCAddress = tokenAddresses[0];
	const token0Address = tokenAddresses[1];
	const token1Address = tokenAddresses[2];
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
	// console.log(
	// 	`******************************BUY OPERATION************************************`
	// );
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

	// await logReservesOTokens(thisRef);

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
	// await logReservesOTokens(thisRef);
	// console.log(
	// 	`******************************BUY OPERATION XXXXX************************************`
	// );
}

async function sellTrade(thisRef, a0, a1) {
	// console.log(
	// 	`******************************SELL OPERATION************************************`
	// );
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

	// await logReservesOTokens(thisRef);

	var amount = await thisRef.mathTest.getAmountCBySellTokens(
		a0,
		a1,
		reservesO[0],
		reservesO[1]
	);

	// transfer outcome tokens
	const tokenAddresses = await thisRef.market.getAddressOfTokens();
	const tokenCAddress = tokenAddresses[0];
	const token0Address = tokenAddresses[1];
	const token1Address = tokenAddresses[2];
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
	// await logReservesOTokens(thisRef);
	// console.log(
	// 	`******************************SELL OPERATION XXXXX************************************`
	// );
}

async function redeemWining(thisRef, amount, _for) {
	const tokenAddresses = await thisRef.market.getAddressOfTokens();
	const tokenCAddress = tokenAddresses[0];
	const token0Address = tokenAddresses[1];
	const token1Address = tokenAddresses[2];
	if (_for == 0) {
		await transferTokens(
			thisRef.OutcomeToken.attach(token0Address),
			thisRef.trader1,
			thisRef.market.address,
			amount
		);
	}
	if (_for == 1) {
		await transferTokens(
			thisRef.OutcomeToken.attach(token1Address),
			thisRef.trader1,
			thisRef.market.address,
			amount
		);
	}

	// redeem
	await thisRef.market.redeemWinning(_for, thisRef.trader1.address);
}

async function setOutcome(thisRef, to) {
	await thisRef.oracleMultiSig
		.connect(thisRef.owner)
		.addTxSetMarketOutcome(to, thisRef.market.address);
}

async function stakeOutcome(thisRef, _for, amount) {
	await transferTokens(
		thisRef.memeToken,
		thisRef.trader1,
		thisRef.market.address,
		amount
	);

	// stake
	await thisRef.market.stakeOutcome(_for, thisRef.trader1.address);
}

describe("Market", function () {
	const fundAmount = 10;
	const identifier = ethers.utils.formatBytes32String("awdadawbda");
	const startingBalance = 100;
	var oracleConfig = {
		isActive: true,
		feeNum: "3",
		feeDenom: "100",
		tokenC: undefined,
		expireAfterBlocks: "50",
		donEscalationLimit: "5",
		donBufferBlocks: "25",
		resolutionBufferBlocks: "25",
	};

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
		oracleConfig = {
			...oracleConfig,
			tokenC: this.memeToken.address,
		};
		await this.oracleMultiSig.addTxSetupOracle(
			oracleConfig.isActive,
			oracleConfig.feeNum,
			oracleConfig.feeDenom,
			oracleConfig.tokenC,
			oracleConfig.expireAfterBlocks,
			oracleConfig.donEscalationLimit,
			oracleConfig.donBufferBlocks,
			oracleConfig.resolutionBufferBlocks
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
	describe("Market stage - Market Funded", async function () {
		it("Should be funded", async function () {
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
			// await buyTrade(this, getBigNumber(0), getBigNumber(5));
			// await sellTrade(this, getBigNumber(0), getBigNumber(4));
			// await buyTrade(this, getBigNumber(2), getBigNumber(5));
			// await buyTrade(this, getBigNumber(12), getBigNumber(4));
			// await buyTrade(this, getBigNumber(0), getBigNumber(5));
			// await sellTrade(this, getBigNumber(10), getBigNumber(0));
		});

		it("Should fail for violating invariant during buy", async function () {
			var reservesO = await this.market.getReservesOTokens();
			var amount = await this.mathTest.getAmountCToBuyTokens(
				getBigNumber(5),
				0,
				reservesO[0],
				reservesO[1]
			);

			// paying less amount, than required
			amount = subBN(amount, getBigNumber(1));

			await transferTokens(
				this.memeToken,
				this.trader1,
				this.market.address,
				amount
			);
			await expect(
				this.market.buy(getBigNumber(5), 0, this.trader1.address)
			).to.be.revertedWith("ERR - INV");
		});

		it("Should fail for violating invariant during sell", async function () {
			// first buy
			await buyTrade(this, getBigNumber(0), getBigNumber(5));

			// sell
			var reservesO = await this.market.getReservesOTokens();
			var amount = await this.mathTest.getAmountCBySellTokens(
				0,
				getBigNumber(5),
				reservesO[0],
				reservesO[1]
			);

			// ask for more amount, than required
			amount = addBN(amount, getBigNumber(1));
			const tokenAddresses = await this.market.getAddressOfTokens();
			const token1Address = tokenAddresses[2];
			await transferTokens(
				this.OutcomeToken.attach(token1Address),
				this.trader1,
				this.market.address,
				getBigNumber(5)
			);

			await expect(
				this.market.sell(amount, this.trader1.address)
			).to.be.revertedWith("ERR - INV");
		});

		it("Should only allow buy & sell", async function () {
			// few trades
			await buyTrade(this, getBigNumber(0), getBigNumber(5));
			await sellTrade(this, getBigNumber(0), getBigNumber(4));
			await buyTrade(this, getBigNumber(2), getBigNumber(5));

			// set outcome throw error - this fails
			await setOutcome(this, 0);

			// redeem winning throws error
			await expect(
				redeemWining(this, 1, getBigNumber(5))
			).to.be.revertedWith("FALSE STATE");

			// stake outcome throws error
			await expect(
				stakeOutcome(this, getBigNumber(2), 0)
			).to.be.revertedWith("FALSE STATE");

			// redeem stake throws error
			await expect(this.market.redeemStake(0)).to.be.revertedWith(
				"FALSE STATE"
			);
		});
	});

	describe("Market stage - Market Buffer", async function () {
		beforeEach(async function () {
			// few trades
			await buyTrade(this, getBigNumber(0), getBigNumber(5));
			await sellTrade(this, getBigNumber(0), getBigNumber(4));
			await buyTrade(this, getBigNumber(2), getBigNumber(5));

			// expire market
			advanceBlocksBy(oracleConfig.expireAfterBlocks);
		});

		it("Should not allow anymore trades", async function () {
			await expect(
				buyTrade(this, getBigNumber(2), getBigNumber(5))
			).to.be.revertedWith("FALSE STATE");
		});

		it("Should only allow staking", async function () {
			await stakeOutcome(this, 0, getBigNumber(5));
			expect(await this.market.getStake(this.trader1.address, 0)).to.eq(
				getBigNumber(5)
			);
		});
	});
});
