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
import './Shared.t.sol';

contract MarketRouterTest is DSTest, Shared {

    function setUp() public {
        commonSetup();
    }

    function test_getMarketAddress() external {
        emit log_named_bytes32("INIT HASHCODE", getMarketContractInitBytecodeHash());
        assertEq(MarketRouter(marketRouter).getMarketAddress(address(this), oracle, sharedIdentifier), getExpectedMarketAddress(sharedIdentifier));
    }

    function test_createMarket(uint120 amount) external {
        if (amount == 0) return;
        string memory _identifier = "http://www.google.com/";
        MemeToken(memeToken).approve(marketRouter, amount);
        uint half = amount/2;
        MarketRouter(marketRouter).createAndPlaceBetOnMarket(address(this), oracle, _identifier, half, half, 1);
        address expectedMarketAddress = MarketRouter(marketRouter).getMarketAddress(address(this), oracle, _identifier);
        
        assertEq(getMarketStage(expectedMarketAddress), 1);
    }
    

    function testFail_createExistingMarket() external {
        string memory _identifier = "http://www.google.com/";
        MemeToken(memeToken).approve(marketRouter, 22*10**18);
        MarketRouter(marketRouter).createAndPlaceBetOnMarket(address(this), oracle, _identifier, 10*10**18, 1*10**18, 1);
        MarketRouter(marketRouter).createAndPlaceBetOnMarket(address(this), oracle, _identifier, 10*10**18, 1*10**18, 1); // should fail
    }

    function test_buyExactTokensForMaxCTokens() external {
        createDefaultMarket();

        (uint bCBefore, uint b0Before, uint b1Before) = getTokenBalances(address(this));

        // buy
        uint a0 = 5*10**18;
        uint a1 = 4*10**18;
        uint a = getAmounCToBuyTokens(a0, a1);
        MemeToken(memeToken).approve(marketRouter, a);
        MarketRouter(marketRouter).buyExactTokensForMaxCTokens(a0, a1, a, marketAddress);

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
        MarketRouter(marketRouter).buyExactTokensForMaxCTokens(a0, a1, a-1, marketAddress);
    }

    function test_buyMinTokensForExactCTokens() external {
        createDefaultMarket();

        (uint bCBefore, uint b0Before, uint b1Before) = getTokenBalances(address(this));

        // buy
        uint a = 5*10**18;
        uint a1 = 0;
        uint a0 = getTokenAmountToBuyWithAmountC(0, 1, a);
        MemeToken(memeToken).approve(marketRouter, a);
        MarketRouter(marketRouter).buyMinTokensForExactCTokens(a0, a1, a, 1, marketAddress);

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
        MarketRouter(marketRouter).buyMinTokensForExactCTokens(a0+1, a1, a, 1, marketAddress);
    }

    function test_sellExactTokensForMinCTokens() external {
        createDefaultMarket();

        // buy
        uint a0 = 5*10**18;
        uint a1 = 4*10**18;
        uint a = getAmounCToBuyTokens(a0, a1);
        MemeToken(memeToken).approve(marketRouter, a);
        MarketRouter(marketRouter).buyExactTokensForMaxCTokens(a0, a1, a, marketAddress);

        (uint bCBefore, uint b0Before, uint b1Before) = getTokenBalances(address(this));

        /// sell
        a0 = 2*10**18;
        a1 = 1*10**18;
        a = getAmountCBySellTokens(a0, a1);

        (,address token0, address token1) = Market(marketAddress).getTokenAddresses();
        OutcomeToken(token0).approve(marketRouter, a0);
        OutcomeToken(token1).approve(marketRouter, a1);
        MarketRouter(marketRouter).sellExactTokensForMinCTokens(a0, a1, a, marketAddress);

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
        MarketRouter(marketRouter).buyExactTokensForMaxCTokens(a0, a1, a, marketAddress);

        /// sell
        a0 = 2*10**18;
        a1 = 1*10**18;
        a = getAmountCBySellTokens(a0, a1);
        (,address token0, address token1) = Market(marketAddress).getTokenAddresses();
        OutcomeToken(token0).approve(marketRouter, a0);
        OutcomeToken(token1).approve(marketRouter, a1);
        MarketRouter(marketRouter).sellExactTokensForMinCTokens(a0, a1, a+1, marketAddress);
    }

    /* Error */
    function test_sellMaxTokensForExactCTokens() external {
        createDefaultMarket();

        // buy
        uint a0 = 5*10**18;
        uint a1 = 4*10**18;
        uint a = getAmounCToBuyTokens(a0, a1);
        MemeToken(memeToken).approve(marketRouter, a);
        MarketRouter(marketRouter).buyExactTokensForMaxCTokens(a0, a1, a, marketAddress);

        (uint bCBefore, uint b0Before, uint b1Before) = getTokenBalances(address(this));

        /// sell
        a = 1*10**18;
        a1 = 0;
        a0 = getTokenAmountToSellForAmountC(a1, 1, a);
        (,address token0, address token1) = Market(marketAddress).getTokenAddresses();
        OutcomeToken(token0).approve(marketRouter, a0);
        OutcomeToken(token1).approve(marketRouter, a1);
        MarketRouter(marketRouter).sellMaxTokensForExactCTokens(a0, a1, a, 1, marketAddress);

        (uint bCAfter, uint b0After, uint b1After) = getTokenBalances(address(this));

        assertEq(bCAfter, bCBefore+a);
        assertEq(b0After, b0Before-a0);
        assertEq(b1After, b1Before-a1);
    }

    function testFail_sellMaxTokensForExactCTokens() external {
        createDefaultMarket();

        // buy
        uint a0 = 5*10**18;
        uint a1 = 4*10**18;
        uint a = getAmounCToBuyTokens(a0, a1);
        MemeToken(memeToken).approve(marketRouter, a);
        MarketRouter(marketRouter).buyExactTokensForMaxCTokens(a0, a1, a, marketAddress);

        /// sell
        a = 1*10**18;
        a1 = 0;
        a0 = getTokenAmountToSellForAmountC(a1, 1, a);
        (,address token0, address token1) = Market(marketAddress).getTokenAddresses();
        OutcomeToken(token0).approve(marketRouter, a0);
        OutcomeToken(token1).approve(marketRouter, a1);
        MarketRouter(marketRouter).sellMaxTokensForExactCTokens(a0-1, a1, a, 1, marketAddress);
    }

    function test_stakeForOutcome() public {
        createDefaultMarket();
        expireMarket();
        MemeToken(memeToken).approve(marketRouter, 2*10**18);
        MarketRouter(marketRouter).stakeForOutcome(0, 2*10**18, marketAddress);
        assertEq(getStakeAmount(marketAddress, 0, address(this)), 2*10**18);
    }

    function testFail_lessThanDoubleStakeOutcome() public {
        createDefaultMarket();
        expireMarket();
        MemeToken(memeToken).approve(marketRouter, 2*10**18);
        MarketRouter(marketRouter).stakeForOutcome(0, 2*10**18, marketAddress);
        MemeToken(memeToken).approve(marketRouter, 4*10**18);
        MarketRouter(marketRouter).stakeForOutcome(1, 4*10**18, marketAddress);
        MemeToken(memeToken).approve(marketRouter, (8*10**18)-1);
        MarketRouter(marketRouter).stakeForOutcome(0, (8*10**18)-1, marketAddress);
    }

    function test_redeemWinning() public {
        createDefaultMarket();

        // buy
        uint a0 = 5*10**18;
        uint a1 = 4*10**18;
        uint a = getAmounCToBuyTokens(a0, a1);
        MemeToken(memeToken).approve(marketRouter, a);
        MarketRouter(marketRouter).buyExactTokensForMaxCTokens(a0, a1, a, marketAddress);

        expireMarket();
        expireBufferPeriod();

        (,address token0, address token1) = Market(marketAddress).getTokenAddresses();

        // redeem winning outcome
        (uint bCBefore, uint b0Before, uint b1Before) = getTokenBalances(address(this));
        OutcomeToken(token0).approve(marketRouter, a0);
        MarketRouter(marketRouter).redeemWinning(0, a0, marketAddress);
        (uint bCAfter, uint b0After, uint b1After) = getTokenBalances(address(this));
        assertEq(bCAfter, bCBefore+a0);
        assertEq(b0After, b0Before-a0);
        assertEq(b1After, b1Before);

        // redeem losing outcome
        (bCBefore, b0Before, b1Before) = getTokenBalances(address(this));

        OutcomeToken(token1).approve(marketRouter, a1);
        MarketRouter(marketRouter).redeemWinning(1, a1, marketAddress);
        (bCAfter, b0After, b1After) = getTokenBalances(address(this));
        assertEq(bCAfter, bCBefore);
        assertEq(b0After, b0Before);
        assertEq(b1After, b1Before-a1);
    }
}   
