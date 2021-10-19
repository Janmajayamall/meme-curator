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
// import "./MarketTestsShared.t.sol";

// contract MarketFundedTest is MarketTestsShared {
    
//     function setUp() override public {
//         commonSetup();
//     }

//     struct DeployParams {
//         address creator;
//         address oracle;
//         bytes32 identifier;
//     }
//     DeployParams public deployParams;

//     function test_marketCreation() public  {
//         deployParams = DeployParams({creator: address(this), oracle: oracle, identifier:0x0401030400040101040403020201030003000000010202020104010201000103});
//         address marketAddress = address(new Market());
//     }

//     function testFail_marketCreationInactiveOracle() public  {
//         address[] memory oracleOwners = new address[](1);
//         oracleOwners[0] = address(this);
//         address tempOracle = address(new OracleMultiSig(oracleOwners, 1, 10));
//         OracleMultiSig(tempOracle).addTxSetupOracle(
//             false,
//             sharedOracleConfig.feeNum,
//             sharedOracleConfig.feeDenom,
//             sharedOracleConfig.tokenC,
//             sharedOracleConfig.expireAfterBlocks,
//             sharedOracleConfig.donEscalationLimit,
//             sharedOracleConfig.donBufferBlocks,
//             sharedOracleConfig.resolutionBufferBlocks
//         );

//         deployParams = DeployParams({creator: address(this), oracle: tempOracle, identifier:0x0401030400040101040403020201030003000000010202020104010201000103});
//         address marketAddress = address(new Market());
//     }

//     function testFail_marketCreationWithInvalidOracleFee() public {
//         address[] memory oracleOwners = new address[](1);
//         oracleOwners[0] = address(this);
//         address tempOracle = address(new OracleMultiSig(oracleOwners, 1, 10));
//         OracleMultiSig(tempOracle).addTxSetupOracle(
//             true,
//             100,
//             99,
//             sharedOracleConfig.tokenC,
//             sharedOracleConfig.expireAfterBlocks,
//             sharedOracleConfig.donEscalationLimit,
//             sharedOracleConfig.donBufferBlocks,
//             sharedOracleConfig.resolutionBufferBlocks
//         );

//         deployParams = DeployParams({creator: address(this), oracle: tempOracle, identifier:0x0401030400040101040403020201030003000000010202020104010201000103});
//         address marketAddress = address(new Market());
//     }


//     function test_marketCreationWithMarketFactory(bytes32 _identifier, uint120 _fundingAmount) public {
//         if (_fundingAmount  == 0) return;
//         MarketFactory(marketFactory).createMarket(address(this), oracle, _identifier);
//         address expectedAddress = getExpectedMarketAddress(_identifier);

//         uint size;
//         assembly {
//             size := extcodesize(expectedAddress)
//         }
//         assertGt(size, 0);
//     }


//     function test_marketCreationWithMarketRouter(bytes32 _identifier, uint120 _fundingAmount) public {
//         if (_fundingAmount  == 0) return;
//         MemeToken(memeToken).approve(marketRouter, _fundingAmount);
//         MarketRouter(marketRouter).createMarket(address(this), oracle, _identifier, _fundingAmount);

//         // check market exists
//         address expectedAddress = getExpectedMarketAddress(_identifier);

//         // check market has been funded & tokenC balance == _fundingAmount
//         assertEq(uint(Market(expectedAddress).stage()), uint(1));
//         assertEq(MemeToken(memeToken).balanceOf(expectedAddress), _fundingAmount);

//         // check outcome token balances == _fundingAmount
//         address token0 = Market(expectedAddress).token0();
//         address token1 = Market(expectedAddress).token1();
//         assertEq(OutcomeToken(token0).balanceOf(expectedAddress), _fundingAmount);
//         assertEq(OutcomeToken(token1).balanceOf(expectedAddress), _fundingAmount);
//     }

//     function test_marketBuyPostFunding(bytes32 _identifier, uint120 _fundingAmount, uint120 _a0, uint120 _a1) public {
//         if (_fundingAmount == 0) return;
//         createMarket(_identifier, _fundingAmount);
//         // buy amount
//         uint a0 = uint(_a0);
//         uint a1 = uint(_a1);
//         uint a = Math.getAmountCToBuyTokens(a0, a1, _fundingAmount, _fundingAmount);
//         MemeToken(memeToken).transfer(marketAddress, a);
//         address token0 = Market(marketAddress).token0();
//         address token1 = Market(marketAddress).token1();
//         uint token0BalanceBefore = OutcomeToken(token0).balanceOf(address(this));
//         uint token1BalanceBefore = OutcomeToken(token1).balanceOf(address(this));
//         Market(marketAddress).buy(a0, a1, address(this));
//         assertEq(OutcomeToken(token0).balanceOf(address(this)), token0BalanceBefore+a0);
//         assertEq(OutcomeToken(token1).balanceOf(address(this)), token1BalanceBefore+a1);
//         keepReservesAndBalsInCheck();
//     }

//     function test_marketSellPostFunding(bytes32 _identifier, uint120 _fundingAmount, uint120 _a0, uint120 _a1) public {
//         if (_fundingAmount == 0) return;
//         createMarket(_identifier, _fundingAmount);

//         // buy amount
//         uint a0 = _a0;
//         uint a1 = _a1;
//         uint a = Math.getAmountCToBuyTokens(a0, a1, _fundingAmount, _fundingAmount);
//         MemeToken(memeToken).transfer(marketAddress, a);
//         Market(marketAddress).buy(a0, a1, address(this));
//         keepReservesAndBalsInCheck();

//         // sell tokens
//         uint sa = Math.getAmountCBySellTokens(a0, a1, _fundingAmount + a - a0, _fundingAmount + a - a1);
//         address token0 = Market(marketAddress).token0();
//         address token1 = Market(marketAddress).token1();
//         OutcomeToken(token0).transfer(marketAddress, a0);
//         OutcomeToken(token1).transfer(marketAddress, a1);
//         uint memeBalanceBefore = MemeToken(memeToken).balanceOf(address(this));
//         Market(marketAddress).sell(sa, address(this));
//         uint memeBalanceAfter = MemeToken(memeToken).balanceOf(address(this));
//         assertEq(memeBalanceBefore + sa, memeBalanceAfter);
//         keepReservesAndBalsInCheck();
//     }

//     function testFail_fund() public {
//         createDefaultMarket();

//         simTradesInFavorOfOutcome0();

//         MemeToken(memeToken).transfer(marketAddress, 10*10**18);
//         Market(marketAddress).fund();
//     }

//     function testFail_stakeOutcome() public {
//         createDefaultMarket();
//         simTradesInFavorOfOutcome0();
//         simStakingRoundsBeforeEscalationLimit(sharedOracleConfig.donEscalationLimit);
//     }

//     function testFail_redeemWinning() public {
//         createDefaultMarket();
//         simTradesInFavorOfOutcome0();
//         redeemWinning(0, 10*10**18, 0);
//     }

//     function testFail_redeemStake() public {
//         createDefaultMarket();
//         simTradesInFavorOfOutcome0();
//         redeemStake(0, 0, 10*10**18, 0);
//     }

//     function testFail_setOutcome() public {
//         createDefaultMarket();
//         simTradesInFavorOfOutcome0();

//         OracleMultiSig(oracle).addTxSetMarketOutcome(0, marketAddress);
//         assertEq(Market(marketAddress).outcome(), 0);
//     }

//     function testFail_tradePostMarketExpiry() public {
//         createDefaultMarket();
//         simTradesInFavorOfOutcome0();

//         expireMarket();

//         uint r0 = Market(marketAddress).reserve0();
//         uint r1 = Market(marketAddress).reserve1();
//         uint a = Math.getAmountCToBuyTokens(10*10**18, 0, r0, r1);
//         MemeToken(memeToken).transfer(marketAddress, a);
//         Market(marketAddress).buy(10*10**18, 0, address(this));
//     }
// }
