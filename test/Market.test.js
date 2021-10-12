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
	// console.log(tokenBalances, userTokenBalances);

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

async function redeemWining(thisRef, _for) {
	const tokenAddresses = await thisRef.market.getAddressOfTokens();
	const tokenCAddress = tokenAddresses[0];
	const token0Address = tokenAddresses[1];
	const token1Address = tokenAddresses[2];
	if (_for == 0) {
		const balance = await thisRef.OutcomeToken.attach(
			token0Address
		).balanceOf(thisRef.trader1.address);
		await transferTokens(
			thisRef.OutcomeToken.attach(token0Address),
			thisRef.trader1,
			thisRef.market.address,
			balance
		);
	}
	if (_for == 1) {
		const balance = await thisRef.OutcomeToken.attach(
			token1Address
		).balanceOf(thisRef.trader1.address);
		await transferTokens(
			thisRef.OutcomeToken.attach(token1Address),
			thisRef.trader1,
			thisRef.market.address,
			balance
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

async function createOracleMultiSig(thisRef, oracleConfig) {
	thisRef.oracleMultiSig = await thisRef.OracleMultiSig.deploy(
		[thisRef.owner.address],
		"1",
		"10"
	);
	await thisRef.oracleMultiSig.addTxSetupOracle(
		oracleConfig.isActive,
		oracleConfig.feeNum,
		oracleConfig.feeDenom,
		oracleConfig.tokenC,
		oracleConfig.expireAfterBlocks,
		oracleConfig.donEscalationLimit,
		oracleConfig.donBufferBlocks,
		oracleConfig.resolutionBufferBlocks
	);
	thisRef.oracleConfig = oracleConfig;
}

async function createNewMarket(thisRef, funding, identifier) {
	await thisRef.memeToken
		.connect(thisRef.marketCreator)
		.approve(thisRef.marketFactory.address, funding);
	await thisRef.marketFactory
		.connect(thisRef.marketCreator)
		.createMarket(
			thisRef.marketCreator.address,
			thisRef.oracleMultiSig.address,
			identifier,
			funding
		);
	// get market address
	const marketAddress = await thisRef.marketFactory.markets(
		thisRef.marketCreator.address,
		thisRef.oracleMultiSig.address,
		identifier
	);
	thisRef.market = await thisRef.Market.attach(marketAddress);
}

describe("Market", function () {
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
		this.mathTest = await this.MathTest.deploy();
		this.startingBalance = 1000000;

		/*
        Mint meme tokens for users
        */
		this.memeToken.mint(
			this.marketCreator.address,
			getBigNumber(this.startingBalance)
		);
		this.memeToken.mint(
			this.trader1.address,
			getBigNumber(this.startingBalance)
		);
		this.memeToken.mint(
			this.trader2.address,
			getBigNumber(this.startingBalance)
		);

		// create a market
		this.fundAmount = 10;
		await createOracleMultiSig(this, {
			isActive: true,
			feeNum: "3",
			feeDenom: "100",
			tokenC: this.memeToken.address,
			expireAfterBlocks: "50",
			donEscalationLimit: "5",
			donBufferBlocks: "25",
			resolutionBufferBlocks: "25",
		});
		await createNewMarket(
			this,
			getBigNumber(this.fundAmount),
			ethers.utils.formatBytes32String("danwdna")
		);
	});

	describe("Market stage - Market Funded", async function () {
		return;
		beforeEach(async function () {});

		it("Should be funded", async function () {
			// check market stage should be MarketFunded
			expect(await this.market.stage()).to.eq(1);

			await checkTokenBalances(
				this,
				getBigNumber(this.fundAmount),
				getBigNumber(this.fundAmount),
				getBigNumber(this.fundAmount),
				this.market.address
			);
			await checkReservesTokenC(
				this,
				getBigNumber(this.fundAmount),
				0,
				0
			);
			await checkReservesOTokens(
				this,
				getBigNumber(this.fundAmount),
				getBigNumber(this.fundAmount)
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
			await buyTrade(this, getBigNumber(0), getBigNumber(5));
			await sellTrade(this, getBigNumber(0), getBigNumber(1));

			// expire market
			await advanceBlocksBy(this.oracleConfig.expireAfterBlocks);
		});

		it("Should not allow anymore trades", async function () {
			await expect(
				buyTrade(this, getBigNumber(2), getBigNumber(5))
			).to.be.revertedWith("FALSE STATE");
		});

		it("Should allow staking", async function () {
			await stakeOutcome(this, 0, getBigNumber(5));
			expect(await this.market.getStake(this.trader1.address, 0)).to.eq(
				getBigNumber(5)
			);

			// doubled
			await stakeOutcome(this, 1, getBigNumber(5 + 5));
			expect(await this.market.getStake(this.trader1.address, 1)).to.eq(
				getBigNumber(10)
			);
		});

		it("Should fail since consecutive stake is not double", async function () {
			await stakeOutcome(this, 0, getBigNumber(5));
			await expect(
				stakeOutcome(this, 1, getBigNumber(5 + 3))
			).to.revertedWith("DBL STAKE");
		});

		it("Should cut short donBuffer & change to Market Resolve after hitting escalation limit", async function () {
			for (
				let i = 0;
				i < Number(this.oracleConfig.donEscalationLimit);
				i++
			) {
				if (i % 2 == 0) {
					await stakeOutcome(this, 0, getBigNumber(2 ** (i + 1)));
				} else {
					await stakeOutcome(this, 0, getBigNumber(2 ** (i + 1)));
				}
			}

			// should throw error
			await expect(
				stakeOutcome(this, 0, getBigNumber(2 ** 7))
			).to.be.revertedWith("FALSE STATE");

			// stage should be Market Resolve
			expect(await this.market.stage()).to.be.eq(3);
		});

		it("Should resolve market (i.e. Market closed) after few escalations which were followed by no escalation before ending don buffer", async function () {
			const donBufferBlocks = Number(this.oracleConfig.donBufferBlocks);
			await stakeOutcome(this, 0, getBigNumber(2));
			await advanceBlocksBy(donBufferBlocks - 10);
			await stakeOutcome(this, 1, getBigNumber(4));
			await advanceBlocksBy(donBufferBlocks - 5);
			await stakeOutcome(this, 0, getBigNumber(8));
			await advanceBlocksBy(donBufferBlocks - 4);

			// market will close with outcome set as 0
			await advanceBlocksBy(donBufferBlocks);

			await expect(
				stakeOutcome(this, 1, getBigNumber(128))
			).to.revertedWith("FALSE STATE");

			// stage should be still be Market Buffer since Market Closed modifier hasn't processed a valid call
			expect(await this.market.stage()).to.be.eq(2);

			// redeem stake to close the market
			await this.market.redeemStake(0);

			// market stage should be Market Closed now
			expect(await this.market.stage()).to.be.eq(4);

			// outcome should be 0
			expect(await this.market.outcome()).to.be.eq(0);
		});

		it("Should directly jump to Market Closed after market expiry since Buffer blocks are 0", async function () {
			// new market & oracle with donBufferBlocks 0
			await createOracleMultiSig(this, {
				isActive: true,
				feeNum: "3",
				feeDenom: "100",
				tokenC: this.memeToken.address,
				expireAfterBlocks: "50",
				donEscalationLimit: "5",
				donBufferBlocks: "0",
				resolutionBufferBlocks: "25",
			});
			await createNewMarket(
				this,
				getBigNumber(10),
				ethers.utils.formatBytes32String("danwdna")
			);

			// tilting market towards one outcome i.e. 1
			await buyTrade(this, getBigNumber(0), getBigNumber(5));
			await buyTrade(this, getBigNumber(0), getBigNumber(5));
			await sellTrade(this, getBigNumber(0), getBigNumber(1));

			// expire market
			await advanceBlocksBy(50);

			// stage should still be Market Funded since no other modifier is called
			expect(await this.market.stage()).to.be.eq(1);

			// escalation should fail, since transition to Market Buffer stage not possible
			await expect(
				stakeOutcome(this, 1, getBigNumber(2))
			).to.revertedWith("FALSE STATE");

			// reedWinning to call Market Closed modifier
			await redeemWining(this, 1);

			// stage should Market Closed
			expect(await this.market.stage()).to.be.eq(4);

			// outcome should be 1
			expect(await this.market.outcome()).to.be.eq(1);
		});
		// test 0

		// test 0 escalation limit & 0 buffer blocks -> desired result is market goes directly to result after expiry.
		// i.e. buffer blocks
	});

	// test escalation limit == 0
	describe("Escalation limit == 0. After market expiry market transitions directly to MarketResolve", async function () {
		beforeEach(async function () {
			// new market & oracle with escalation limit 0
			await createOracleMultiSig(this, {
				isActive: true,
				feeNum: "3",
				feeDenom: "100",
				tokenC: this.memeToken.address,
				expireAfterBlocks: "50",
				donEscalationLimit: "0",
				donBufferBlocks: "25",
				resolutionBufferBlocks: "100",
			});
			await createNewMarket(
				this,
				getBigNumber(10),
				ethers.utils.formatBytes32String("danwdna")
			);

			// tilting market towards one outcome i.e. 1
			await buyTrade(this, getBigNumber(0), getBigNumber(5));
			await buyTrade(this, getBigNumber(0), getBigNumber(5));
			await sellTrade(this, getBigNumber(0), getBigNumber(1));

			// redeemWinning & setOutcome not allowed
			await expect(redeemWining(this, 1)).to.be.revertedWith("FALSE MC");

			// expire market
			await advanceBlocksBy(50);

			// outcome stake is not allowed, even market expiration
			await expect(
				stakeOutcome(this, 1, getBigNumber(2))
			).to.revertedWith("FALSE STATE");

			// stage should be market funding
			expect(await this.market.stage()).to.be.eq(1);

			// redeemWinning is not allowed, since waiting for resolution or resolution expiry
			await expect(redeemWining(this, 1)).to.be.revertedWith("FALSE MC");

			// advance blocks such that block number >= donBufferEndsAtBlock. redeemWinning still shouldn't be allowed since waiting for resolution or resolution expiry
			await advanceBlocksBy(25); // 75
			await expect(redeemWining(this, 1)).to.be.revertedWith("FALSE MC");
		});

		it("Should resolve after oracle sets outcome", async function () {
			// outcome should be 2 right now
			expect(await this.market.outcome()).to.be.eq(2);

			// oracle sets market outcome to 0
			await setOutcome(this, 0);

			// advance blocks such that resolution period expires. Should not change to outcome to 1
			advanceBlocksBy(25);

			// market should be closed
			expect(await this.market.stage()).to.be.eq(4);

			// redeem winning
			expect(await redeemWining(this, 0));

			// outcome should be set to 0
			expect(await this.market.outcome()).to.be.eq(0);
		});

		it("Should resolve to 1 after resolution period expires", async function () {
			// expire resolution period {block is already 75, so increase by 25}, thus market automatically resolves to 1
			advanceBlocksBy(25);

			// oracle tries to set market outcome to 0 & fails silently (since it's a low level call in multi sig)
			await setOutcome(this, 0);

			// market stage should still be MarketFunded, since MarketClosed modifier hasn't been called yet
			expect(await this.market.stage()).to.be.eq(1);

			// redeem winning - calls MarketClosed Modifier
			expect(await redeemWining(this, 1));

			// market stage should be 4 (MarketClosed))
			expect(await this.market.stage()).to.be.eq(4);

			// outcome should be set
			expect(await this.market.outcome()).to.be.eq(1);
		});
	});

	// test MarketBuffer = 0
	describe("donBufferBlocks == 0. After market expiry market transitions directly to Market Closed", async function () {
		beforeEach(async function () {
			// new market & oracle with donBufferBlocks = 0
			await createOracleMultiSig(this, {
				isActive: true,
				feeNum: "3",
				feeDenom: "100",
				tokenC: this.memeToken.address,
				expireAfterBlocks: "50",
				donEscalationLimit: "0",
				donBufferBlocks: "0",
				resolutionBufferBlocks: "100",
			});
			await createNewMarket(
				this,
				getBigNumber(10),
				ethers.utils.formatBytes32String("danwdna")
			);

			// tilting market towards one outcome i.e. 1
			await buyTrade(this, getBigNumber(0), getBigNumber(5));
			await buyTrade(this, getBigNumber(0), getBigNumber(5));
			await sellTrade(this, getBigNumber(0), getBigNumber(1));

			// advance blocks such that block number >= donBufferEndsAtBlock. redeemWinning still shouldn't be allowed since waiting for resolution or resolution expiry
			await advanceBlocksBy(25); // 75
			await expect(redeemWining(this, 1)).to.be.revertedWith("FALSE MC");
		});

		it("Should close market after market expiry with outcome set 1", async function () {
			// expire market
			await advanceBlocksBy(50);

			// outcome stake is not allowed
			await expect(
				stakeOutcome(this, 1, getBigNumber(2))
			).to.revertedWith("FALSE STATE");

			// set outcome should not change anything & fails
			await setOutcome(this, 0);
			expect(await this.market.outcome()).to.be.eq(2); // showing that set outcome failed

			// stage should be market funding
			expect(await this.market.stage()).to.be.eq(1);

			// redeemWinning - closes the market
			await redeemWining(this, 1);

			// market stage should be closed now
			expect(await this.market.stage()).to.be.eq(4);

			// outcome should be set to 1 now
			expect(await this.market.outcome()).to.be.eq(1); // showing that set outcome failed
		});
	});
});
