const { waffle, ethers } = require("hardhat");
const { BigNumber } = ethers;
const { expect } = require("chai");

function getBigNumber(amount, decimals = 18) {
	return BigNumber.from(amount).mul(BigNumber.from(10).pow(decimals));
}

async function buyKnowTokensWithUnknownAmountC(thisRef, a0, a1) {
	var reserves = await thisRef.mathTest.getReserves();
	var amount = await thisRef.mathTest.getAmountCToBuyTokens(
		getBigNumber(a0),
		getBigNumber(a1),
		reserves[0],
		reserves[1]
	);

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

describe("Math", async function () {
	before(async function () {
		this.MathTest = await ethers.getContractFactory("MathTest");
		this.mathTest = await this.MathTest.deploy();
	});

	it("Balance trades", async function () {
		await this.mathTest.fund(getBigNumber(10));
		await buyKnowTokensWithUnknownAmountC(this, 5, 0);
		await buyKnowTokensWithUnknownAmountC(this, 3, 5);
		await buyUnknownTokensWithKnowAmountC(this, 0, 0, 8);
		await buyKnowTokensWithUnknownAmountC(this, 100, 0);
		await buyKnowTokensWithUnknownAmountC(this, 3, 300);
		await buyKnowTokensWithUnknownAmountC(this, 3, 234);
		await buyKnowTokensWithUnknownAmountC(this, 332, 5);
		await buyKnowTokensWithUnknownAmountC(this, 3, 123);
	});
});

// 1. Write tests for market.sol
// 2. Fill up application form Mirror.xyz

// console.log(
// 	`allowance from market creator factor ${await this.memeToken.allowance(
// 		this.marketCreator.address,
// 		this.marketFactory.address
// 	)}`
// );

// console.log(`meme token address ${this.memeToken.address}`);

// console.log(
// 	`balance of market creator ${await this.memeToken.balanceOf(
// 		this.marketCreator.address
// 	)}`
// );
