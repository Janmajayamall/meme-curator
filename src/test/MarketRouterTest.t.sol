// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import './../libraries/Math.sol';
import './../OracleMultiSig.sol';
import './../MemeToken.sol';
import './../MarketFactory.sol';
import './../MarketRouter.sol';
import './../libraries/Math.sol';
import './../OutcomeToken.sol';
import './../Market.sol';
import './../libraries/ERC20.sol';

contract MarketTestsShared is DSTest {

    struct OracleConfig {
        bool isActive;
        uint feeNum;
        uint feeDenom;
        address tokenC;
        uint expireAfterBlocks;
        uint donEscalationLimit;
        uint donBufferBlocks;
        uint resolutionBufferBlocks;
    }

    address marketAddress;
    bytes32 defaultIdentifier = 0x0401030400040101040403020201030003000000010202020104010201000103;
    address marketFactory;
    address marketRouter;
    address oracle;
    address memeToken;
    OracleConfig sharedOracleConfig;

    address hevm = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

    function setUp() public {
        marketFactory = address(new MarketFactory());
        marketRouter = address(new MarketRouter(marketFactory));

        memeToken = address(new MemeToken());
        MemeToken(memeToken).mint(address(this), type(uint).max);

        address[] memory oracleOwners = new address[](1);
        oracleOwners[0] = address(this);
        oracle = address(new OracleMultiSig(oracleOwners, 1, 10));
        sharedOracleConfig = OracleConfig(true, 10, 100, memeToken, 10, 5, 10, 10);
        OracleMultiSig(oracle).addTxSetupOracle(
            sharedOracleConfig.isActive,
            sharedOracleConfig.feeNum,
            sharedOracleConfig.feeDenom,
            sharedOracleConfig.tokenC,
            sharedOracleConfig.expireAfterBlocks,
            sharedOracleConfig.donEscalationLimit,
            sharedOracleConfig.donBufferBlocks,
            sharedOracleConfig.resolutionBufferBlocks
        );
    }

    function createDefaultMarket() internal {
        uint _funding = 10*10**18;
        MemeToken(memeToken).approve(marketRouter, _funding);
        MarketRouter(marketRouter).createMarket(address(this), oracle, defaultIdentifier, _funding);
        marketAddress = MarketRouter(marketRouter).getMarketAddress(address(this), oracle, defaultIdentifier);
    }

    function getMarketReserves() internal returns (uint rC, uint r0, uint r1){
        rC = Market(marketAddress).reserveC() + Market(marketAddress).reserveDoN0() + Market(marketAddress).reserveDoN1();
        r0 = Market(marketAddress).reserve0();
        r1 = Market(marketAddress).reserve1();
    }

    function getAmounCToBuyTokens(uint a0, uint a1) internal returns (uint a){
        (uint rc, uint r0, uint r1) = getMarketReserves();
        a = Math.getAmountCToBuyTokens(a0, a1, r0, r1);
    }

    function getTokenAmountToBuyWithAmountC(uint fixedTokenAmount, uint fixedTokenIndex, uint a) internal returns (uint tokenAmount) {
        (uint rc, uint r0, uint r1) = getMarketReserves();
        tokenAmount = Math.getTokenAmountToBuyWithAmountC(fixedTokenAmount, fixedTokenIndex, r0, r1, a);
    }

    function getAmountCBySellTokens(uint a0, uint a1) internal returns (uint a){
        (uint rc, uint r0, uint r1) = getMarketReserves();
        a = Math.getAmountCBySellTokens(a0, a1, r0, r1);
    }

    function getTokenAmountToSellForAmountC(uint fixedTokenAmount, uint fixedTokenIndex, uint a) internal returns (uint tokenAmount) {
        (uint rc, uint r0, uint r1) = getMarketReserves();
        tokenAmount = Math.getTokenAmountToSellForAmountC(fixedTokenAmount, fixedTokenIndex, r0, r1, a);
    }

    function getTokenBalances(address _of) internal returns (uint balanceC, uint balance0, uint balance1) {
        balanceC = MemeToken(memeToken).balanceOf(_of);
        balance0 = OutcomeToken(Market(marketAddress).token0()).balanceOf(_of);
        balance1 = OutcomeToken(Market(marketAddress).token1()).balanceOf(_of);
    }

    function test_createMarket(bytes32 _identifier, uint amount) external {
        if (amount == 0) return;
        MemeToken(memeToken).approve(marketRouter, amount);
        MarketRouter(marketRouter).createMarket(address(this), oracle, _identifier, amount);
        address expectedMarketAddress = MarketRouter(marketRouter).getMarketAddress(address(this), oracle, _identifier);
        assertEq(uint(Market(expectedMarketAddress).stage()), 1);
    }

    function testFail_createExistingMarket() external {
        bytes32 _identifier = 0x0401030400040101040403020201030003000000010202020104010201000103;
        uint _funding = 10*10**18;
        MemeToken(memeToken).approve(marketRouter, _funding);
        MarketRouter(marketRouter).createMarket(address(this), oracle, _identifier, _funding);
        MemeToken(memeToken).approve(marketRouter, _funding);
        MarketRouter(marketRouter).createMarket(address(this), oracle, _identifier, _funding); // should fail
    }

    function test_buyExactTokensForMaxCTokens() external {
        createDefaultMarket();

        (uint bCBefore, uint b0Before, uint b1Before) = getTokenBalances(address(this));

        // buy
        uint a0 = 5*10**18;
        uint a1 = 4*10**18;
        uint a = getAmounCToBuyTokens(a0, a1);
        MemeToken(memeToken).approve(marketRouter, a);
        MarketRouter(marketRouter).buyExactTokensForMaxCTokens(a0, a1, a, address(this), oracle, defaultIdentifier);

        (uint bCAfter, uint b0After, uint b1After) = getTokenBalances(address(this));

        assertEq(bCAfter, bCBefore-a);
        assertEq(b0After, b0Before+a0);
        assertEq(b1After, b1Before+a1);
    }

    // should fail
    function testFail_buyExactTokenForMaxTokens() external {
        createDefaultMarket();

        // buy
        uint a0 = 5*10**18;
        uint a1 = 4*10**18;
        uint a = getAmounCToBuyTokens(a0, a1);
        MemeToken(memeToken).approve(marketRouter, a);
        MarketRouter(marketRouter).buyExactTokensForMaxCTokens(a0, a1, a-1, address(this), oracle, defaultIdentifier);
    }

    function test_buyMinTokensForExactCTokens() external {
        createDefaultMarket();

        (uint bCBefore, uint b0Before, uint b1Before) = getTokenBalances(address(this));

        // buy
        uint a = 5*10**18;
        uint a1 = 0;
        uint a0 = getTokenAmountToBuyWithAmountC(0, 1, a);
        MemeToken(memeToken).approve(marketRouter, a);
        MarketRouter(marketRouter).buyMinTokensForExactCTokens(a0, a1, a, 1, address(this), oracle, defaultIdentifier);

        (uint bCAfter, uint b0After, uint b1After) = getTokenBalances(address(this));

        assertEq(bCAfter, bCBefore-a);
        assertEq(b0After, b0Before+a0);
        assertEq(b1After, b1Before+a1);
    }

    // should fail
    function testFail_buyMinTokensForExactCTokens() external {
        createDefaultMarket();
        // buy
        uint a = 5*10**18;
        uint a1 = 0;
        uint a0 = getTokenAmountToBuyWithAmountC(0, 1, a);
        MemeToken(memeToken).approve(marketRouter, a);
        MarketRouter(marketRouter).buyMinTokensForExactCTokens(a0+1, a1, a, 1, address(this), oracle, defaultIdentifier);
    }

    function test_sellExactTokensForMinCTokens() external {
        createDefaultMarket();

        // buy
        uint a0 = 5*10**18;
        uint a1 = 4*10**18;
        uint a = getAmounCToBuyTokens(a0, a1);
        MemeToken(memeToken).approve(marketRouter, a);
        MarketRouter(marketRouter).buyExactTokensForMaxCTokens(a0, a1, a, address(this), oracle, defaultIdentifier);

        (uint bCBefore, uint b0Before, uint b1Before) = getTokenBalances(address(this));

        /// sell
        a0 = 2*10**18;
        a1 = 1*10**18;
        a = getAmountCBySellTokens(a0, a1);
        OutcomeToken(Market(marketAddress).token0()).approve(marketRouter, a0);
        OutcomeToken(Market(marketAddress).token1()).approve(marketRouter, a1);
        MarketRouter(marketRouter).sellExactTokensForMinCTokens(a0, a1, a, address(this), oracle, defaultIdentifier);

        (uint bCAfter, uint b0After, uint b1After) = getTokenBalances(address(this));

        assertEq(bCAfter, bCBefore+a);
        assertEq(b0After, b0Before-a0);
        assertEq(b1After, b1Before-a1);
    }

    function testFail_sellExactTokensForMinCTokens() external {
        createDefaultMarket();

        // buy
        uint a0 = 5*10**18;
        uint a1 = 4*10**18;
        uint a = getAmounCToBuyTokens(a0, a1);
        MemeToken(memeToken).approve(marketRouter, a);
        MarketRouter(marketRouter).buyExactTokensForMaxCTokens(a0, a1, a, address(this), oracle, defaultIdentifier);

        /// sell
        a0 = 2*10**18;
        a1 = 1*10**18;
        a = getAmountCBySellTokens(a0, a1);
        OutcomeToken(Market(marketAddress).token0()).approve(marketRouter, a0);
        OutcomeToken(Market(marketAddress).token1()).approve(marketRouter, a1);
        MarketRouter(marketRouter).sellExactTokensForMinCTokens(a0, a1, a+1, address(this), oracle, defaultIdentifier);
    }

    /* Error */
    function test_sellMaxTokensForExactCTokens() external {
        createDefaultMarket();

        // buy
        uint a0 = 5*10**18;
        uint a1 = 4*10**18;
        uint a = getAmounCToBuyTokens(a0, a1);
        MemeToken(memeToken).approve(marketRouter, a);
        MarketRouter(marketRouter).buyExactTokensForMaxCTokens(a0, a1, a, address(this), oracle, defaultIdentifier);

        (uint bCBefore, uint b0Before, uint b1Before) = getTokenBalances(address(this));

        /// sell
        a = 1*10**18;
        a1 = 0;
        a0 = getTokenAmountToSellForAmountC(a1, 1, a);
        OutcomeToken(Market(marketAddress).token0()).approve(marketRouter, a0);
        OutcomeToken(Market(marketAddress).token1()).approve(marketRouter, a1);
        MarketRouter(marketRouter).sellExactTokensForMinCTokens(a0, a1, a, address(this), oracle, defaultIdentifier);

        (uint bCAfter, uint b0After, uint b1After) = getTokenBalances(address(this));

        assertEq(bCAfter, bCBefore+a);
        assertEq(b0After, b0Before-a0);
        assertEq(b1After, b1Before-a1);
    }

    function testF_sellMaxTokensForExactCTokens() external {
        createDefaultMarket();

        // buy
        uint a0 = 5*10**18;
        uint a1 = 4*10**18;
        uint a = getAmounCToBuyTokens(a0, a1);
        MemeToken(memeToken).approve(marketRouter, a);
        MarketRouter(marketRouter).buyExactTokensForMaxCTokens(a0, a1, a, address(this), oracle, defaultIdentifier);

        /// sell
        a = 1*10**18;
        a1 = 0;
        a0 = getTokenAmountToSellForAmountC(a1, 1, a);
        OutcomeToken(Market(marketAddress).token0()).approve(marketRouter, a0);
        OutcomeToken(Market(marketAddress).token1()).approve(marketRouter, a1);
        MarketRouter(marketRouter).sellExactTokensForMinCTokens(a0, a1, a+1, address(this), oracle, defaultIdentifier);
    }

}
