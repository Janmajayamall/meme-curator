// // SPDX-License-Identifier: GPL-3.0-or-later
// pragma solidity ^0.8.0;

// import "ds-test/test.sol";
// import './../libraries/Math.sol';
// import './../OracleMultiSig.sol';
// import './../MemeToken.sol';
// import './../MarketFactory.sol';
// import './../MarketRouter.sol';
// import './../libraries/Math.sol';
// import './../OutcomeToken.sol';
// import './../Market.sol';
// import './Shared.t.sol';

// contract MarketRouterTest is DSTest, Shared {

//     function setUp() public {
//         commonSetup();
//     }

//     function test_getMarketAddress() external {
//         emit log_named_bytes32("INIT HASHCODE", getMarketContractInitBytecodeHash());
//         assertEq(MarketRouter(marketRouter).getMarketAddress(address(this), oracle, sharedIdentifier), getExpectedMarketAddress(sharedIdentifier));
//     }

//     function test_createMarket(bytes32 _identifier, uint amount) external {
//         if (amount == 0) return;
//         MemeToken(memeToken).approve(marketRouter, amount);
//         MarketRouter(marketRouter).createMarket(address(this), oracle, _identifier, amount);
//         address expectedMarketAddress = MarketRouter(marketRouter).getMarketAddress(address(this), oracle, _identifier);
        
//         assertEq(uint(Market(expectedMarketAddress).stage()), 1);
//     }
    

//     function testFail_createExistingMarket() external {
//         bytes32 _identifier = 0x0401030400040101040403020201030003000000010202020104010201000103;
//         uint _funding = 10*10**18;
//         MemeToken(memeToken).approve(marketRouter, _funding);
//         MarketRouter(marketRouter).createMarket(address(this), oracle, _identifier, _funding);
//         MemeToken(memeToken).approve(marketRouter, _funding);
//         MarketRouter(marketRouter).createMarket(address(this), oracle, _identifier, _funding); // should fail
//     }

//     function test_buyExactTokensForMaxCTokens() external {
//         createDefaultMarket();

//         (uint bCBefore, uint b0Before, uint b1Before) = getTokenBalances(address(this));

//         // buy
//         uint a0 = 5*10**18;
//         uint a1 = 4*10**18;
//         uint a = getAmounCToBuyTokens(a0, a1);
//         MemeToken(memeToken).approve(marketRouter, a);
//         MarketRouter(marketRouter).buyExactTokensForMaxCTokens(a0, a1, a, address(this), oracle, sharedIdentifier);

//         (uint bCAfter, uint b0After, uint b1After) = getTokenBalances(address(this));

//         assertEq(bCAfter, bCBefore-a);
//         assertEq(b0After, b0Before+a0);
//         assertEq(b1After, b1Before+a1);
//     }

//     // should fail
//     function testFail_buyExactTokenForMaxTokens() external {
//         createDefaultMarket();

//         // buy
//         uint a0 = 5*10**18;
//         uint a1 = 4*10**18;
//         uint a = getAmounCToBuyTokens(a0, a1);
//         MemeToken(memeToken).approve(marketRouter, a);
//         MarketRouter(marketRouter).buyExactTokensForMaxCTokens(a0, a1, a-1, address(this), oracle, sharedIdentifier);
//     }

//     function test_buyMinTokensForExactCTokens() external {
//         createDefaultMarket();

//         (uint bCBefore, uint b0Before, uint b1Before) = getTokenBalances(address(this));

//         // buy
//         uint a = 5*10**18;
//         uint a1 = 0;
//         uint a0 = getTokenAmountToBuyWithAmountC(0, 1, a);
//         MemeToken(memeToken).approve(marketRouter, a);
//         MarketRouter(marketRouter).buyMinTokensForExactCTokens(a0, a1, a, 1, address(this), oracle, sharedIdentifier);

//         (uint bCAfter, uint b0After, uint b1After) = getTokenBalances(address(this));

//         assertEq(bCAfter, bCBefore-a);
//         assertEq(b0After, b0Before+a0);
//         assertEq(b1After, b1Before+a1);
//     }

//     // should fail
//     function testFail_buyMinTokensForExactCTokens() external {
//         createDefaultMarket();
//         // buy
//         uint a = 5*10**18;
//         uint a1 = 0;
//         uint a0 = getTokenAmountToBuyWithAmountC(0, 1, a);
//         MemeToken(memeToken).approve(marketRouter, a);
//         MarketRouter(marketRouter).buyMinTokensForExactCTokens(a0+1, a1, a, 1, address(this), oracle, sharedIdentifier);
//     }

//     function test_sellExactTokensForMinCTokens() external {
//         createDefaultMarket();

//         // buy
//         uint a0 = 5*10**18;
//         uint a1 = 4*10**18;
//         uint a = getAmounCToBuyTokens(a0, a1);
//         MemeToken(memeToken).approve(marketRouter, a);
//         MarketRouter(marketRouter).buyExactTokensForMaxCTokens(a0, a1, a, address(this), oracle, sharedIdentifier);

//         (uint bCBefore, uint b0Before, uint b1Before) = getTokenBalances(address(this));

//         /// sell
//         a0 = 2*10**18;
//         a1 = 1*10**18;
//         a = getAmountCBySellTokens(a0, a1);
//         OutcomeToken(Market(marketAddress).token0()).approve(marketRouter, a0);
//         OutcomeToken(Market(marketAddress).token1()).approve(marketRouter, a1);
//         MarketRouter(marketRouter).sellExactTokensForMinCTokens(a0, a1, a, address(this), oracle, sharedIdentifier);

//         (uint bCAfter, uint b0After, uint b1After) = getTokenBalances(address(this));

//         assertEq(bCAfter, bCBefore+a);
//         assertEq(b0After, b0Before-a0);
//         assertEq(b1After, b1Before-a1);
//     }

//     function testFail_sellExactTokensForMinCTokens() external {
//         createDefaultMarket();

//         // buy
//         uint a0 = 5*10**18;
//         uint a1 = 4*10**18;
//         uint a = getAmounCToBuyTokens(a0, a1);
//         MemeToken(memeToken).approve(marketRouter, a);
//         MarketRouter(marketRouter).buyExactTokensForMaxCTokens(a0, a1, a, address(this), oracle, sharedIdentifier);

//         /// sell
//         a0 = 2*10**18;
//         a1 = 1*10**18;
//         a = getAmountCBySellTokens(a0, a1);
//         OutcomeToken(Market(marketAddress).token0()).approve(marketRouter, a0);
//         OutcomeToken(Market(marketAddress).token1()).approve(marketRouter, a1);
//         MarketRouter(marketRouter).sellExactTokensForMinCTokens(a0, a1, a+1, address(this), oracle, sharedIdentifier);
//     }

//     /* Error */
//     function test_sellMaxTokensForExactCTokens() external {
//         createDefaultMarket();

//         // buy
//         uint a0 = 5*10**18;
//         uint a1 = 4*10**18;
//         uint a = getAmounCToBuyTokens(a0, a1);
//         MemeToken(memeToken).approve(marketRouter, a);
//         MarketRouter(marketRouter).buyExactTokensForMaxCTokens(a0, a1, a, address(this), oracle, sharedIdentifier);

//         (uint bCBefore, uint b0Before, uint b1Before) = getTokenBalances(address(this));

//         /// sell
//         a = 1*10**18;
//         a1 = 0;
//         a0 = getTokenAmountToSellForAmountC(a1, 1, a);
//         OutcomeToken(Market(marketAddress).token0()).approve(marketRouter, a0);
//         OutcomeToken(Market(marketAddress).token1()).approve(marketRouter, a1);
//         MarketRouter(marketRouter).sellMaxTokensForExactCTokens(a0, a1, a, 1, address(this), oracle, sharedIdentifier);

//         (uint bCAfter, uint b0After, uint b1After) = getTokenBalances(address(this));

//         assertEq(bCAfter, bCBefore+a);
//         assertEq(b0After, b0Before-a0);
//         assertEq(b1After, b1Before-a1);
//     }

//     function testFail_sellMaxTokensForExactCTokens() external {
//         createDefaultMarket();

//         // buy
//         uint a0 = 5*10**18;
//         uint a1 = 4*10**18;
//         uint a = getAmounCToBuyTokens(a0, a1);
//         MemeToken(memeToken).approve(marketRouter, a);
//         MarketRouter(marketRouter).buyExactTokensForMaxCTokens(a0, a1, a, address(this), oracle, sharedIdentifier);

//         /// sell
//         a = 1*10**18;
//         a1 = 0;
//         a0 = getTokenAmountToSellForAmountC(a1, 1, a);
//         OutcomeToken(Market(marketAddress).token0()).approve(marketRouter, a0);
//         OutcomeToken(Market(marketAddress).token1()).approve(marketRouter, a1);
//         MarketRouter(marketRouter).sellMaxTokensForExactCTokens(a0-1, a1, a, 1, address(this), oracle, sharedIdentifier);
//     }

//     function test_stakeForOutcome() public {
//         createDefaultMarket();
//         expireMarket();
//         MemeToken(memeToken).approve(marketRouter, 2*10**18);
//         MarketRouter(marketRouter).stakeForOutcome(0, 2*10**18, address(this), oracle, sharedIdentifier);
//         assertEq(Market(marketAddress).stakes(0, address(this)), 2*10**18);
//     }

//     function testFail_lessThanDoubleStakeOutcome() public {
//         createDefaultMarket();
//         expireMarket();
//         MemeToken(memeToken).approve(marketRouter, 2*10**18);
//         MarketRouter(marketRouter).stakeForOutcome(0, 2*10**18, address(this), oracle, sharedIdentifier);
//         MemeToken(memeToken).approve(marketRouter, 4*10**18);
//         MarketRouter(marketRouter).stakeForOutcome(1, 4*10**18, address(this), oracle, sharedIdentifier);
//         MemeToken(memeToken).approve(marketRouter, (8*10**18)-1);
//         MarketRouter(marketRouter).stakeForOutcome(0, (8*10**18)-1, address(this), oracle, sharedIdentifier);
//     }

//     function test_redeemWinning() public {
//         createDefaultMarket();

//         // buy
//         uint a0 = 5*10**18;
//         uint a1 = 4*10**18;
//         uint a = getAmounCToBuyTokens(a0, a1);
//         MemeToken(memeToken).approve(marketRouter, a);
//         MarketRouter(marketRouter).buyExactTokensForMaxCTokens(a0, a1, a, address(this), oracle, sharedIdentifier);

//         expireMarket();
//         expireBufferPeriod();

//         // redeem winning outcome
//         (uint bCBefore, uint b0Before, uint b1Before) = getTokenBalances(address(this));
//         OutcomeToken(Market(marketAddress).token0()).approve(marketRouter, a0);
//         MarketRouter(marketRouter).redeemWinning(0, a0, address(this), oracle, sharedIdentifier);
//         (uint bCAfter, uint b0After, uint b1After) = getTokenBalances(address(this));
//         assertEq(bCAfter, bCBefore+a0);
//         assertEq(b0After, b0Before-a0);
//         assertEq(b1After, b1Before);

//         // redeem losing outcome
//         (bCBefore, b0Before, b1Before) = getTokenBalances(address(this));
//         OutcomeToken(Market(marketAddress).token1()).approve(marketRouter, a1);
//         MarketRouter(marketRouter).redeemWinning(1, a1, address(this), oracle, sharedIdentifier);
//         (bCAfter, b0After, b1After) = getTokenBalances(address(this));
//         assertEq(bCAfter, bCBefore);
//         assertEq(b0After, b0Before);
//         assertEq(b1After, b1Before-a1);
//     }
// }   
