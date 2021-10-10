const { waffle, ethers } = require("hardhat");
const { BigNumber } = ethers;
const { expect } = require("chai");

function getBigNumber(amount, decimals = 18) {
	return BigNumber.from(amount).mul(BigNumber.from(10).pow(decimals));
}

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

describe("Math", async function () {
	before(async function () {
		this.MathTest = await ethers.getContractFactory("MathTest");
		this.mathTest = await this.MathTest.deploy();
	});

	it("Balanced trades", async function () {
		await this.mathTest.fund(getBigNumber(10));
		await buyKnowTokensWithUnknownAmountC(this, 10, 10);
		await buyKnowTokensWithUnknownAmountC(this, 0, 18);
		await buyKnowTokensWithUnknownAmountC(this, 23, 0);
		await buyKnowTokensWithUnknownAmountC(this, 10, 0);
		await sellKnowTokensForUnknownAmountC(this, 0, 10, -1);
		// await sellKnowTokensForUnknownAmountC(this, 0, 57);
		// await sellUnknownTokensForKnowAmountC(this, 0, 0, 5);
	});
});
