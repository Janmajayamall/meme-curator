const { waffle, ethers } = require("hardhat");
const { BigNumber } = ethers;
const { expect } = require("chai");

const {
	addBN,
	subBN,
	getBigNumber,
	advanceBlocksBy,
} = require("./shared/utils");

async function buyKnowTokensWithUnknownAmountC(
	thisRef,
	a0,
	a1,
	distortValBy = 0
) {
	var reserves = await thisRef.mathTest.getReserves();
	var amount = await thisRef.mathTest.getAmountCToBuyTokens(
		getBigNumber(a0),
		getBigNumber(a1),
		reserves[0],
		reserves[1]
	);

	// distorts amount value according to distortValBy parameter
	// helps to see the effect of paying extra (or less, if -ve) amount on rP
	amount = BigNumber.from(amount).add(getBigNumber(distortValBy));
	await thisRef.mathTest.buy(getBigNumber(a0), getBigNumber(a1), amount);
}

async function buyUnknownTokensWithKnowAmountC(
	thisRef,
	fixedTokenAmount,
	fixedTokenIndex,
	amount
) {
	var reserves = await thisRef.mathTest.getReserves();
	var tokenAmount = await thisRef.mathTest.getTokenAmountToBuyWithAmountC(
		getBigNumber(fixedTokenAmount),
		fixedTokenIndex,
		reserves[0],
		reserves[1],
		getBigNumber(amount)
	);

	if (fixedTokenIndex == 0) {
		await thisRef.mathTest.buy(
			fixedTokenAmount,
			tokenAmount,
			getBigNumber(amount)
		);
	} else if (fixedTokenIndex == 1) {
		await thisRef.mathTest.buy(
			tokenAmount,
			fixedTokenAmount,
			getBigNumber(amount)
		);
	}
}

async function sellKnowTokensForUnknownAmountC(
	thisRef,
	a0,
	a1,
	distortValBy = 0
) {
	var reserves = await thisRef.mathTest.getReserves();
	var amount = await thisRef.mathTest.getAmountCBySellTokens(
		getBigNumber(a0),
		getBigNumber(a1),
		reserves[0],
		reserves[1]
	);

	// distorts amount value according to distortValBy parameter
	// helps to see the effect of paying extra (or less, if -ve) amount on rP
	amount = BigNumber.from(amount).add(getBigNumber(distortValBy));

	await thisRef.mathTest.sell(getBigNumber(a0), getBigNumber(a1), amount);
}

async function sellUnknownTokensForKnowAmountC(
	thisRef,
	fixedTokenAmount,
	fixedTokenIndex,
	amount
) {
	var reserves = await thisRef.mathTest.getReserves();
	var tokenAmount = await thisRef.mathTest.getTokenAmountToSellForAmountC(
		getBigNumber(fixedTokenAmount),
		fixedTokenIndex,
		reserves[0],
		reserves[1],
		getBigNumber(amount)
	);

	if (fixedTokenIndex == 0) {
		await thisRef.mathTest.sell(
			fixedTokenAmount,
			tokenAmount,
			getBigNumber(amount)
		);
	} else if (fixedTokenIndex == 1) {
		await thisRef.mathTest.sell(
			tokenAmount,
			fixedTokenAmount,
			getBigNumber(amount)
		);
	}
}

describe("MarketRouter", async function () {
	before(async function () {
		this.MarketFactory = await ethers.getContractFactory("MarketFactory");
		this.MarketRouter = await ethers.getContractFactory("MarketRouter");
		this.Market = await ethers.getContractFactory("Market");
		this.OracleMultiSig = await ethers.getContractFactory("OracleMultiSig");
		this.MemeToken = await ethers.getContractFactory("MemeToken");
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
		this.marketRouter = await this.MarketRouter.deploy(
			this.marketFactory.address
		);
		this.mathTest = await this.MathTest.deploy();

		this.startingBalance = 100;
		await this.memeToken.mint(
			this.marketCreator.address,
			getBigNumber(this.startingBalance)
		);
		await this.memeToken.mint(
			this.trader1.address,
			getBigNumber(this.startingBalance)
		);
		await this.memeToken.mint(
			this.trader2.address,
			getBigNumber(this.startingBalance)
		);

		// create oracle multi sig
		this.oracleConfig = {
			isActive: true,
			feeNum: "3",
			feeDenom: "100",
			tokenC: this.memeToken.address,
			expireAfterBlocks: "50",
			donEscalationLimit: "5",
			donBufferBlocks: "25",
			resolutionBufferBlocks: "25",
		};
		this.oracleMultiSig = await this.OracleMultiSig.deploy(
			[this.owner.address],
			"1",
			"10"
		);
		await this.oracleMultiSig.addTxSetupOracle(
			this.oracleConfig.isActive,
			this.oracleConfig.feeNum,
			this.oracleConfig.feeDenom,
			this.oracleConfig.tokenC,
			this.oracleConfig.expireAfterBlocks,
			this.oracleConfig.donEscalationLimit,
			this.oracleConfig.donBufferBlocks,
			this.oracleConfig.resolutionBufferBlocks
		);

		// create a new market
		this.funding = 10;
		this.identifier = ethers.utils.formatBytes32String("212131213");
		await this.memeToken
			.connect(this.marketCreator)
			.approve(this.marketFactory.address, getBigNumber(this.funding));
		await this.marketFactory
			.connect(this.marketCreator)
			.createMarket(
				this.marketCreator.address,
				this.oracleMultiSig.address,
				this.identifier,
				getBigNumber(this.funding)
			);
		// get market address
		this.marketAddress = await this.marketFactory.markets(
			this.marketCreator.address,
			this.oracleMultiSig.address,
			this.identifier
		);
		this.market = await this.Market.attach(this.marketAddress);
	});

	it("Should match market's address with address derived in market router contract", async function () {
		// check that market's address matches with address derived in market router
		const contractAddress = await this.marketRouter.getMarketAddress(
			this.marketCreator.address,
			this.oracleMultiSig.address,
			this.identifier
		);
		expect(contractAddress).to.eq(this.market.address);
	});

    /* 
    1. Buy tokens without violating slippage
     */

	it("Balanced trades", async function () {
		// await this.mathTest.fund(getBigNumber(10));
		// await buyKnowTokensWithUnknownAmountC(this, 0, 5);
		// await sellKnowTokensForUnknownAmountC(this, 0, 4);
		// await sellKnowTokensForUnknownAmountC(this, 0, 57);
		// await sellUnknownTokensForKnowAmountC(this, 0, 0, 5);
	});
});
