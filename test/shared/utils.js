const { BigNumber } = ethers;

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

module.exports = {
	addBN,
	subBN,
	getBigNumber,
	advanceBlocksBy,
};
