// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "./MarketTestsShared.t.sol";
import './../libraries/Math.sol';
import './../OracleMultiSig.sol';
import './../MemeToken.sol';
import './../MarketFactory.sol';
import './../MarketRouter.sol';
import './../libraries/Math.sol';
import './../OutcomeToken.sol';

contract MarketBufferTest is MarketTestsShared {
    function setUp() override public {
        commonSetup();
        createDefaultMarket();
    }

    /* 
    Tests for when buffer period is active, post market expiration
     */
    function test_stakeOutcome() public {
        expireMarket();

        assertEq(uint(Market(marketAddress).stage()), uint(1)); // still in MarketFunded

        // staking
        uint marketBalanceBefore = MemeToken(memeToken).balanceOf(marketAddress);
        simStakingRoundsBeforeEscalationLimit(sharedOracleConfig.donEscalationLimit);
        uint marketBalanceAfter = MemeToken(memeToken).balanceOf(marketAddress);
        assertEq(marketBalanceAfter, marketBalanceBefore+simStakingInfo.stakeAmounts[0]+simStakingInfo.stakeAmounts[1]); // balance increased by expected staked amount in simulation
        assertEq(simStakingInfo.stakeAmounts[0], Market(marketAddress).stakes(0, address(this))); // expected amount staked for outcome matches amount staked
        assertEq(simStakingInfo.stakeAmounts[1], Market(marketAddress).stakes(1, address(this)));
        assertEq(simStakingInfo.stakeAmounts[0], Market(marketAddress).reserveDoN0()); // reserveDoN0 matches amount taked for outcome 0
        assertEq(simStakingInfo.stakeAmounts[1], Market(marketAddress).reserveDoN1()); // reserveDoN1 matches amount taked for outcome 1
        keepReservesAndBalsInCheck();

        assertEq(uint(Market(marketAddress).stage()), uint(2)); // stage is now MarketBuffer
    }

    function testFail_stakeOutcomeZeroStakeAmount() public {
        expireMarket();
        Market(marketAddress).stakeOutcome(0, address(this));
        assertEq(uint(Market(marketAddress).stage()), uint(1));
    }

    function testFail_stakeOutcomeInvalidOutcome() public {
        expireMarket();
        Market(marketAddress).stakeOutcome(2, address(this));
    }

    function testFail_stakeOutcomeInvalidSubsequentAmount() public {
        expireMarket();

        MemeToken(memeToken).transfer(marketAddress, 2*10**18); // 1st stake
        Market(marketAddress).stakeOutcome(0, address(this));
        keepReservesAndBalsInCheck();

        MemeToken(memeToken).transfer(marketAddress, 4*10**18); // 2nd stake
        Market(marketAddress).stakeOutcome(1, address(this));
        keepReservesAndBalsInCheck();

        MemeToken(memeToken).transfer(marketAddress, (8*10**18)-1); // 3nd stake invalid
        Market(marketAddress).stakeOutcome(0, address(this));
    }

    // should fail
    function testFail_buyOutcome() public {
        simTradesInFavorOfOutcome0();
        expireMarket();

        // try trading
        oneOffBuy(10*10**18, 0);
    }

    // should fail
    function testFail_sellOutcome() public {
        simTradesInFavorOfOutcome0();
        expireMarket();

        // try trading
        oneOffSell(2*10**18, 0);
    }

    // should fail
    function testFail_setOutcome() public {
        simTradesInFavorOfOutcome0();
        expireMarket();

        OracleMultiSig(oracle).addTxSetMarketOutcome(0, marketAddress);
        assertEq(Market(marketAddress).outcome(), 0);
    }

    function testFail_setOutcomeAfterFewEscalations() public {
        simTradesInFavorOfOutcome0();
        expireMarket();

        simStakingRoundsBeforeEscalationLimit(sharedOracleConfig.donEscalationLimit);

        OracleMultiSig(oracle).addTxSetMarketOutcome(0, marketAddress);
        assertEq(Market(marketAddress).outcome(), 0);
    }

    // should fail
    function testFail_redeemStake() public {
        simTradesInFavorOfOutcome0();
        expireMarket();

        MemeToken(memeToken).transfer(marketAddress, 2*10**18);
        Market(marketAddress).stakeOutcome(0, address(this));

        Market(marketAddress).redeemStake(0);
    }

    // should fail 
    function testFail_redeemWinning() public {
        simTradesInFavorOfOutcome0();
        expireMarket();

        address token0 = Market(marketAddress).token0();
        address token1 = Market(marketAddress).token1();
        OutcomeToken(token0).transfer(marketAddress, OutcomeToken(token0).balanceOf(address(this)));
        Market(marketAddress).redeemWinning(0, address(this));
    }

    function testFail_claimReserve() public {
        simTradesInFavorOfOutcome0();
        expireMarket();

        simStakingRoundsBeforeEscalationLimit(sharedOracleConfig.donEscalationLimit);
        
        Market(marketAddress).claimReserve();
    }

    /* 
    Tests for when buffer period is active ENDS
     */

    /* 
    Tests for when escalation limit is reached
     */
    function test_stakeOutcomeTillEscalationLimit() public {
        expireMarket();

        assertEq(uint(Market(marketAddress).stage()), uint(1));

        simStakingRoundsTillEscalationLimit(sharedOracleConfig.donEscalationLimit);

        assertEq(uint(Market(marketAddress).stage()), uint(3)); // market stage is now MarketResolve
    }

    function testFail_stakeOutcomePostEscalationLimit() public {
        expireMarket();
        assertEq(uint(Market(marketAddress).stage()), uint(1));

        // hit escalation limit
        simStakingRoundsTillEscalationLimit(sharedOracleConfig.donEscalationLimit);

        // should fail since market is in stage Market Resolve
        MemeToken(memeToken).transfer(marketAddress, simStakingInfo.lastAmountStaked*2); 
        Market(marketAddress).stakeOutcome(0, address(this)); 
    }

    /* 
    Tests for when buffer period expires, without hitting escalation limit
     */
    function testFail_stakeOutcomePostBufferExpiryWithNoPriorStakes() public {
        // tilt odds in favour of outcome 0
        simTradesInFavorOfOutcome0();
        expireMarket();
        // expire buffer period
        expireBufferPeriod();

        MemeToken(memeToken).transfer(marketAddress, 2*10**18); 
        Market(marketAddress).stakeOutcome(0, address(this)); 
    }

    function testFail_stakeOutcomePostBufferExpiryWithPriorStakes() public {
        simTradesInFavorOfOutcome0();
        expireMarket();

        // simulate staking 
        simStakingRoundsBeforeEscalationLimit(sharedOracleConfig.donEscalationLimit);

        // expire buffer period
        expireBufferPeriod();

        MemeToken(memeToken).transfer(marketAddress, simStakingInfo.lastAmountStaked*2); 
        Market(marketAddress).stakeOutcome(0, address(this)); 
    }

    function test_outcomeSetToFavoredOutcomePostBufferExpiry() public {
        // tilt odds in favour of outcome 0
        simTradesInFavorOfOutcome0();

        expireMarket();
        expireBufferPeriod(); // notice since no staking, outcome is set to favored outcome i.e. 0

        assertEq(Market(marketAddress).outcome(), 2); // outcome is still 2

        // redeem winning to close the market & set the outcomme
        redeemWinning(0, 10*10**18, 0);
        keepReservesAndBalsInCheck();
        redeemWinning(1, 4*10**18, 0);
        keepReservesAndBalsInCheck();

        // market resolved to outcome 0 & market stage is 4 
        assertEq(uint(Market(marketAddress).stage()), 4); 
        assertEq(Market(marketAddress).outcome(), 0); 
    }

    function test_outcomeSetTo2PostBufferExpiry() public {
        // make odds equal for both outcomes
        uint amount = Math.getAmountCToBuyTokens(10*10**18, 0, sharedFundingAmount, sharedFundingAmount);
        MemeToken(memeToken).transfer(marketAddress, amount);
        Market(marketAddress).buy(10*10**18, 0, address(this));
        keepReservesAndBalsInCheck();
        amount = Math.getAmountCToBuyTokens(0, 10*10**18, sharedFundingAmount+amount-(10*10**18), sharedFundingAmount+amount);
        MemeToken(memeToken).transfer(marketAddress, amount);
        Market(marketAddress).buy(0, 10*10**18, address(this));
        keepReservesAndBalsInCheck();

        // expire market & buffer period
        expireMarket();
        expireBufferPeriod();

        assertEq(Market(marketAddress).outcome(), 2); // outcome is still 2

        uint reserve0 = Market(marketAddress).reserve0();

        redeemWinning(0, 10*10**18, 2);
        keepReservesAndBalsInCheck();
        redeemWinning(1, 10*10**18, 2);
        keepReservesAndBalsInCheck();

        // market resolved to outcome 2 & market stage is 4 
        assertEq(uint(Market(marketAddress).stage()), 4); 
        assertEq(Market(marketAddress).outcome(), 2); 


    }

    function test_outcomeSetToLastStakedOutcomePostBufferExpiry() public {
        simTradesInFavorOfOutcome0();
        expireMarket();

        // few staking rounds
        simStakingRoundsBeforeEscalationLimit(sharedOracleConfig.donEscalationLimit);
        keepReservesAndBalsInCheck();

        expireBufferPeriod();

        assertEq(Market(marketAddress).outcome(), 2); // outcome is still 2

        redeemStake(
            simStakingInfo.lastOutcomeStaked, 
            simStakingInfo.lastOutcomeStaked, 
            simStakingInfo.stakeAmounts[simStakingInfo.lastOutcomeStaked], 
            simStakingInfo.stakeAmounts[1-simStakingInfo.lastOutcomeStaked]
        ); // redeem winning stake
        redeemStake(
            1-simStakingInfo.lastOutcomeStaked, 
            simStakingInfo.lastOutcomeStaked, 
            simStakingInfo.stakeAmounts[1-simStakingInfo.lastOutcomeStaked], 
            0
        ); // redeem losing stake
        keepReservesAndBalsInCheck();

        // market resolved 
        assertEq(uint(Market(marketAddress).stage()), 4); 
        assertEq(Market(marketAddress).outcome(), simStakingInfo.lastOutcomeStaked); 

        // redeem winning
        if (simStakingInfo.lastOutcomeStaked == 0){
            redeemWinning(0, 10*10**18, 0);
            keepReservesAndBalsInCheck();
            redeemWinning(1, 4*10**18, 0);
            keepReservesAndBalsInCheck();
        }else {
            redeemWinning(0, 10*10**18, 1);
            keepReservesAndBalsInCheck();
            redeemWinning(1, 4*10**18, 1);
            keepReservesAndBalsInCheck();
        }
    }

    function test_claimReserve() public {
        simTradesInFavorOfOutcome0();
        expireMarket();

        simStakingRoundsBeforeEscalationLimit(sharedOracleConfig.donEscalationLimit);

        expireBufferPeriod();

        redeemWinning(0, 2*10**18, simStakingInfo.lastOutcomeStaked); // market changes to closed

        address token0 = Market(marketAddress).token0();
        address token1 = Market(marketAddress).token1();
        uint reserve0Before = Market(marketAddress).reserve0();
        uint reserve1Before = Market(marketAddress).reserve1();
        uint balance0before = OutcomeToken(token0).balanceOf(address(this));
        uint balance1before = OutcomeToken(token1).balanceOf(address(this));
        Market(marketAddress).claimReserve(); // claiming reserver tokens
        assertEq(reserve0Before+balance0before, OutcomeToken(token0).balanceOf(address(this))); // token0 balance should increase by reserve0
        assertEq(reserve1Before+balance1before, OutcomeToken(token1).balanceOf(address(this))); // token1 balance should increase by reserve1
        assertEq(uint(0), Market(marketAddress).reserve0()); // token reserve should be 0
        assertEq(uint(0), Market(marketAddress).reserve1());
        assertEq(uint(0), OutcomeToken(token0).balanceOf(marketAddress)); // token balance of market should be 0
        assertEq(uint(0), OutcomeToken(token1).balanceOf(marketAddress)); // token balance of market should be 0

        // redeem tokenC
        uint tokenCBalanceBefore = MemeToken(memeToken).balanceOf(address(this));
        uint expectedWin;
        if (simStakingInfo.lastOutcomeStaked == 0){
                expectedWin = OutcomeToken(token0).balanceOf(address(this));
                OutcomeToken(token0).transfer(marketAddress, expectedWin);
                Market(marketAddress).redeemWinning(0, address(this));
        }else {
                expectedWin = OutcomeToken(token1).balanceOf(address(this));
                OutcomeToken(token1).transfer(marketAddress, expectedWin);
                Market(marketAddress).redeemWinning(1, address(this));
        }
        uint tokenCBalanceAfter =  MemeToken(memeToken).balanceOf(address(this));
        assertEq(tokenCBalanceAfter-tokenCBalanceBefore, expectedWin);
    }

    /* 
    Tests for buffer period is zero
     */
     function checkStateMarketExpiresWithNoBufferPeriod() internal {
        // change oracle's donEscalationLimit to zero & create a new default market
        OracleMultiSig(oracle).addTxChangeDoNBufferBlocks(0);
        assertEq(OracleMultiSig(oracle).donBufferBlocks(), 0);

        createMarket(0x0101000100010001010101000101000001010001010100000101000001010101, 1*10**18);
        simTradesInFavorOfOutcome0();
        expireMarket();
     }

     function test_zeroBufferBlocksResolveToFavoredOutcome() public {
        checkStateMarketExpiresWithNoBufferPeriod();

        assertEq(uint(Market(marketAddress).stage()), 1); // stage is still MarketFunded
        assertEq(Market(marketAddress).outcome(), 2); // outcome hasn't been set

        // redeem winnings
        redeemWinning(0, 10*10**18, 0);
        keepReservesAndBalsInCheck();
        redeemWinning(1, 4*10**18, 0);
        keepReservesAndBalsInCheck();

        assertEq(uint(Market(marketAddress).stage()), 4); // MarketClosed
        assertEq(Market(marketAddress).outcome(), 0); // outcome has been set to favored outcome

     }

     // stake outcome fails
     function testFail_zeroBufferBlocksStakeOutcome() public {
        checkStateMarketExpiresWithNoBufferPeriod();
        simStakingRoundsBeforeEscalationLimit(2);
     }

     // set outcomme fails
     function testFail_zeroBufferBlocksSetOutcome() public {
        checkStateMarketExpiresWithNoBufferPeriod();   
        OracleMultiSig(oracle).addTxSetMarketOutcome(0, marketAddress);
        assertEq(Market(marketAddress).outcome(), 0);
     }

     /* 
     Tests for beffer period & escalation limit are zero.
     Note - Preference is given to buffer period, thus market resolves to favored outcome right after expiration
      */
 
     function checkStateMarketExpiresWithNoBufferPeriod0EscalationLimit() internal {
        // change oracle's donEscalationLimit to zero & create a new default market
        OracleMultiSig(oracle).addTxChangeDoNBufferBlocks(0);
        assertEq(OracleMultiSig(oracle).donBufferBlocks(), 0);
        OracleMultiSig(oracle).addTxChangeDonEscalationLimit(0);
        assertEq(OracleMultiSig(oracle).donEscalationLimit(), 0);

        createMarket(0x0101000100010001010101000101000001010001010100000101000001010101, 1*10**18);
        simTradesInFavorOfOutcome0();
        expireMarket();
     }

     function test_zeroBufferBlocks0EscalationLimitResolveToFavoredOutcome() public {
        checkStateMarketExpiresWithNoBufferPeriod0EscalationLimit();

        assertEq(uint(Market(marketAddress).stage()), 1); // stage is still MarketFunded
        assertEq(Market(marketAddress).outcome(), 2); // outcome hasn't been set

        // redeem winnings
        redeemWinning(0, 10*10**18, 0);
        keepReservesAndBalsInCheck();
        redeemWinning(1, 4*10**18, 0);
        keepReservesAndBalsInCheck();

        assertEq(uint(Market(marketAddress).stage()), 4); // MarketClosed
        assertEq(Market(marketAddress).outcome(), 0); // outcome has been set to favored outcome
     }

     function testFail_zeroBufferBlocks0EscalationLimitSetOutcome() public {
        checkStateMarketExpiresWithNoBufferPeriod0EscalationLimit();  
        OracleMultiSig(oracle).addTxSetMarketOutcome(0, marketAddress);
        assertEq(Market(marketAddress).outcome(), 0);
     }
        
} 