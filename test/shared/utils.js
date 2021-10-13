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

async function approveTokens(contract, owner, toAddress, amount) {
	await contract.connect(owner).approve(toAddress, amount);
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

module.exports = {
	addBN,
	subBN,
	getBigNumber,
	advanceBlocksBy,
	approveTokens,
	getTokenBalances,
};
