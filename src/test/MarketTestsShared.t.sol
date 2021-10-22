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

// contract MarketTestsShared is DSTest, Shared {

//     function redeemStake(uint _for, uint outcome, uint stakeAmount, uint expectedWinning) internal {
//         uint tokenCBalanceBefore = MemeToken(memeToken).balanceOf(address(this));
//         Market(marketAddress).redeemStake(_for);
//         uint tokenCBalanceAfter = MemeToken(memeToken).balanceOf(address(this));

//         if (_for == outcome){
//             assertEq(tokenCBalanceAfter, tokenCBalanceBefore + stakeAmount + expectedWinning);
//         }else if (outcome == 2){
//             assertEq(tokenCBalanceAfter, tokenCBalanceBefore + stakeAmount);
//         }else {
//             assertEq(tokenCBalanceAfter, tokenCBalanceBefore);
//         }
//     }

//     function redeemWinning(uint _for, uint tokenAmount, uint _outcome) internal {
//         address token0 = Market(marketAddress).token0();
//         address token1 = Market(marketAddress).token1();
//         if (_for == 0){
//             OutcomeToken(token0).transfer(marketAddress, tokenAmount);
//         }else if (_for == 1){
//             OutcomeToken(token1).transfer(marketAddress, tokenAmount);
//         }
//         uint tokenCBalanceBefore = MemeToken(memeToken).balanceOf(address(this));
//         Market(marketAddress).redeemWinning(_for, address(this));
//         uint tokenCBalanceAfter = MemeToken(memeToken).balanceOf(address(this));

//         uint expectedWin;
//         if (_outcome == 2){
//             expectedWin = tokenAmount/2;
//         }else if (_outcome == _for){
//             expectedWin = tokenAmount;
//         }

//         assertEq(tokenCBalanceAfter, tokenCBalanceBefore+expectedWin);
//     }

//     function simTradesInFavorOfOutcome0() internal {
//         uint a0 = 10*10**18;
//         uint a1 = 0;
//         uint a = Math.getAmountCToBuyTokens(a0, a1, sharedFundingAmount, sharedFundingAmount);
//         MemeToken(memeToken).transfer(marketAddress, a);
//         Market(marketAddress).buy(a0, a1, address(this));
//         a0 = 0;
//         a1 = 4*10**18;
//         a = Math.getAmountCToBuyTokens(a0, a1, sharedFundingAmount+a-10*10**18, sharedFundingAmount+a);
//         MemeToken(memeToken).transfer(marketAddress, a);
//         Market(marketAddress).buy(a0, a1, address(this));
//     }

//     function simTradesInFavorOfOutcome1() internal {
//         uint a1 = 10*10**18;
//         uint a0 = 0;
//         uint a = Math.getAmountCToBuyTokens(a0, a1, sharedFundingAmount, sharedFundingAmount);
//         MemeToken(memeToken).transfer(marketAddress, a);
//         Market(marketAddress).buy(a0, a1, address(this));
//         a1 = 0;
//         a0 = 4*10**18;
//         a = Math.getAmountCToBuyTokens(a0, a1, sharedFundingAmount+a, sharedFundingAmount+a-10*10**18);
//         MemeToken(memeToken).transfer(marketAddress, a);
//         Market(marketAddress).buy(a0, a1, address(this));
//     }

//     function simStakingRoundsTillEscalationLimit(uint escalationLimit) internal {
//         simStakingInfo.lastAmountStaked = 0;
//         simStakingInfo.lastOutcomeStaked = 2;
//         simStakingInfo.stakeAmounts[0] = 0;
//         simStakingInfo.stakeAmounts[1] = 0;
//         for (uint index = 0; index < escalationLimit; index++) {
//             // advance blocks to test increase in buffer blocks
//             advanceBlocksBy(sharedOracleConfig.donBufferBlocks - (1));

//             uint _amount = (2*10**18)*(2**index);
//             uint _outcome = index % 2;
//             MemeToken(memeToken).transfer(marketAddress, _amount); 
//             Market(marketAddress).stakeOutcome(_outcome, address(this));
//             simStakingInfo.lastOutcomeStaked = _outcome;
//             simStakingInfo.lastAmountStaked = _amount;
//             simStakingInfo.stakeAmounts[_outcome] += _amount;

//         }
//     }

//     function simStakingRoundsBeforeEscalationLimit(uint escalationLimit) internal {
//         simStakingInfo.lastAmountStaked = 0;
//         simStakingInfo.lastOutcomeStaked = 2;
//         simStakingInfo.stakeAmounts[0] = 0;
//         simStakingInfo.stakeAmounts[1] = 0;
//         for (uint index = 0; index < escalationLimit-1; index++) {
//             advanceBlocksBy(sharedOracleConfig.donBufferBlocks - (1));

//             uint _amount = (2*10**18)*(2**index);
//             uint _outcome = index % 2;
//             MemeToken(memeToken).transfer(marketAddress, _amount); 
//             Market(marketAddress).stakeOutcome(_outcome, address(this));
//             simStakingInfo.lastOutcomeStaked = _outcome;
//             simStakingInfo.lastAmountStaked = _amount;
//             simStakingInfo.stakeAmounts[_outcome] += _amount;
//         }
//     }

//     function oneOffBuy(uint amount0, uint amount1) internal {
//         uint r0 = Market(marketAddress).reserve0();
//         uint r1 = Market(marketAddress).reserve1();
//         uint amount = Math.getAmountCToBuyTokens(amount0, amount1, r0, r1);
//         MemeToken(memeToken).transfer(marketAddress, amount);
//         Market(marketAddress).buy(amount0, amount1, address(this));
//     }

//     function oneOffSell(uint amount0, uint amount1) internal{
//         uint r0 = Market(marketAddress).reserve0();
//         uint r1 = Market(marketAddress).reserve1();
//         uint amount = Math.getAmountCBySellTokens(amount0, amount1, r0, r1);
//         address token0 = Market(marketAddress).token0();
//         address token1 = Market(marketAddress).token1();
//         OutcomeToken(token0).transfer(marketAddress, amount0);
//         OutcomeToken(token1).transfer(marketAddress, amount1);
//         Market(marketAddress).sell(amount, address(this));
//     }

//     function keepReservesAndBalsInCheck() internal {
//         uint reserve0 = Market(marketAddress).reserve0();
//         uint reserve1 = Market(marketAddress).reserve1();
//         uint reserveC = Market(marketAddress).reserveC();
//         uint reserveDoN0 = Market(marketAddress).reserveDoN0();
//         uint reserveDoN1 = Market(marketAddress).reserveDoN1();

//         address tokenC = Market(marketAddress).tokenC();
//         address token0 = Market(marketAddress).token0();
//         address token1 = Market(marketAddress).token1();
//         assertEq(reserveC+reserveDoN0+reserveDoN1, MemeToken(tokenC).balanceOf(marketAddress));
//         assertEq(reserve0, OutcomeToken(token0).balanceOf(marketAddress));
//         assertEq(reserve1, OutcomeToken(token1).balanceOf(marketAddress));
//         // emit log_named_uint("yo yo yo", OutcomeToken(token0).balanceOf(marketAddress));
//         // emit log_named_uint("yo yo yo", reserve0);
//     } 

//     // function test_dawda() public {
//     //     // bytes memory initCode = type(Market).creationCode;
//     //     // initHash = keccak256(initCode);
//     //     emit log_named_bytes32("INIT HASHCODE", getMarketContractInitBytecodeHash());
//     //     // require(false);
//     //     MemeToken(memeToken).approve(marketRouter, 10*10**18);
//     //     MarketRouter(marketRouter).createMarket(address(this), oracle, 0x0401030400040101040403020201030003000000010202020104010201000103, 10*10**18);
//     //     // MarketRouter(marketRouter).createMarket(address(this), oracle, 0x0401030400040101040403020201030003000000010202020104010201000103);
//     //     // // // require(false);
//     // }

//     // function test_dadadadad() public {
//     //     address o1 = address(new OutcomeToken());
//     // }

//     function setUp() virtual public {
//         commonSetup();
//     }
// }
