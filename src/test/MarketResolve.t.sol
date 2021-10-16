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
import "./MarketTestsShared.t.sol";

contract MarketResolve is MarketTestsShared {

    function setUp() override public {
        commonSetup();
        createDefaultMarket();
    }

    function checkStateMarketResolvePostEscalation() internal {
        simTradesInFavorOfOutcome0();
        expireMarket();
        simStakingRoundsTillEscalationLimit(sharedOracleConfig.donEscalationLimit);
    }

    /* 
    Tests for when market is awaiting resolution after hitting escalation limit
     */
    function test_setOutcome(uint outcome) public {
        if (outcome > 2) return;

        checkStateMarketResolvePostEscalation();
        
        assertEq(Market(marketAddress).outcome(), 2); // outcome hasn't been set
        assertEq(uint(Market(marketAddress).stage()), 3); // stage is resolve

        uint oracleBalanceBefore = MemeToken(memeToken).balanceOf(oracle);
        OracleMultiSig(oracle).addTxSetMarketOutcome(outcome, marketAddress);
        uint oracleBalanceAfter = MemeToken(memeToken).balanceOf(oracle);
        uint oracleFee;
        if (outcome != 2){
            oracleFee = (simStakingInfo.stakeAmounts[1-outcome]*sharedOracleConfig.feeNum)/sharedOracleConfig.feeDenom;
        }
        assertEq(oracleBalanceAfter, oracleBalanceBefore+oracleFee); // fees earned

        assertEq(Market(marketAddress).outcome(), outcome);
        assertEq(uint(Market(marketAddress).stage()), 4); // market closed

        // redeem stake
        if (outcome == 0){
            // redeem stakes
            redeemStake(0, 0, simStakingInfo.stakeAmounts[0], ((simStakingInfo.stakeAmounts[1])*(sharedOracleConfig.feeDenom-sharedOracleConfig.feeNum))/sharedOracleConfig.feeDenom);
            redeemStake(1, 0, simStakingInfo.stakeAmounts[1], 0);

            // redeem winnings
            redeemWinning(0, 10*10**18, 0);
            redeemWinning(1, 4*10**18, 0);
        }else if (outcome == 1){
            // redeem stakes
            redeemStake(1, 1, simStakingInfo.stakeAmounts[1], ((simStakingInfo.stakeAmounts[0])*(sharedOracleConfig.feeDenom-sharedOracleConfig.feeNum))/sharedOracleConfig.feeDenom);
            redeemStake(0, 1, simStakingInfo.stakeAmounts[0], 0);

            // redeem winnings
            redeemWinning(1, 4*10**18, 1);
            redeemWinning(0, 10*10**18, 1);
        }else if (outcome == 2){
            // redeem stakes
            redeemStake(0, 2, simStakingInfo.stakeAmounts[0], 0);
            redeemStake(1, 2, simStakingInfo.stakeAmounts[1], 0);

            // redeem winnings
            redeemWinning(0, 10*10**18, 2);
            redeemWinning(1, 4*10**18, 2);
        }
    }

    function test_setOutcomeToOutcomeWithZeroStakes() public {
        simTradesInFavorOfOutcome0();
        expireMarket();
        
        // reach escalation limit
        uint totalStaked = 0;
        for (uint256 index = 0; index < sharedOracleConfig.donEscalationLimit; index++) {
            MemeToken(memeToken).transfer(marketAddress, (2*10**18)*(2**index)); 
            totalStaked += (2*10**18)*(2**index);
            Market(marketAddress).stakeOutcome(0, address(this));
        }   

        // set outcome to 1
        uint oracleBalanceBefore = MemeToken(memeToken).balanceOf(oracle);
        OracleMultiSig(oracle).addTxSetMarketOutcome(1, marketAddress);
        uint oracleBalanceAfter = MemeToken(memeToken).balanceOf(oracle);
        uint oracleFee = (totalStaked*sharedOracleConfig.feeNum)/sharedOracleConfig.feeDenom;
        assertEq(oracleBalanceAfter, oracleBalanceBefore+oracleFee); // fees earned

        assertEq(Market(marketAddress).outcome(), 1);
        assertEq(uint(Market(marketAddress).stage()), 4); // market closed

        redeemStake(1, 1, 0, ((totalStaked)*(sharedOracleConfig.feeDenom-sharedOracleConfig.feeNum))/sharedOracleConfig.feeDenom);
        // redeemStake(0, 1, totalStaked, 0);
    }

    function testFail_setInvalidOutcome(uint outcome) public {
        if (outcome < 3) return;
        checkStateMarketResolvePostEscalation();
        OracleMultiSig(oracle).addTxSetMarketOutcome(outcome, marketAddress);
    }

    // should fail
    function testFail_buyOutcome() public {
        checkStateMarketResolvePostEscalation();
        oneOffBuy(2*10**18, 0);   
    }

    // should fail 
    function testFail_sellOutcome() public {
        checkStateMarketResolvePostEscalation();
        oneOffSell(2*10**18, 0);   
    }

    // should fail
    function testFail_redeemStake() public {
        checkStateMarketResolvePostEscalation();
        Market(marketAddress).redeemStake(0);
    }

    // should fail
    function testFail_redeemWinning() public {
        checkStateMarketResolvePostEscalation();
        (, address token0, address token1) = Market(marketAddress).getAddressOfTokens();
        OutcomeToken(token0).transfer(marketAddress, OutcomeToken(token0).balanceOf(address(this)));
        Market(marketAddress).redeemWinning(0, address(this));
    }

    /* 
    Tests for when resolution period expires & oracle hasn't set the outcome
     */
    function testFail_setOutcomePostResolutionPeriodExpires() public {
        checkStateMarketResolvePostEscalation();
        expireResolutionPeriod();
        OracleMultiSig(oracle).addTxSetMarketOutcome(0, marketAddress);
        assertEq(Market(marketAddress).outcome(), 0);   
    }

    function test_outcomeSetToLastStakedPostResolutionPeriodExpires() public {
        checkStateMarketResolvePostEscalation();
        expireResolutionPeriod();

        // redeem stakes
        redeemStake(
            simStakingInfo.lastOutcomeStaked, 
            simStakingInfo.lastOutcomeStaked, 
            simStakingInfo.stakeAmounts[simStakingInfo.lastOutcomeStaked], 
            simStakingInfo.stakeAmounts[1-simStakingInfo.lastOutcomeStaked]
        ); // winning stake
        redeemStake(
            1-simStakingInfo.lastOutcomeStaked, 
            simStakingInfo.lastOutcomeStaked, 
            simStakingInfo.stakeAmounts[1-simStakingInfo.lastOutcomeStaked], 
            0
        );

        // redeem winnings
        if (simStakingInfo.lastOutcomeStaked == 0){
            redeemWinning(0, 10*10**18, 0);
            redeemWinning(1, 4*10**18, 0);
        }else if (simStakingInfo.lastOutcomeStaked == 1){
            redeemWinning(0, 10*10**18, 1);
            redeemWinning(1, 4*10**18, 1);
        }
    }

    /* 
    Tests for when escalation limit is set zero by oracle, thus market transitions to MarketResolve right after MarketExpiry
     */
    function checkStateMarketResolveWithZeroEscalationLimit() internal {
        // change oracle's donEscalationLimit to zero & create a new default market
        OracleMultiSig(oracle).addTxChangeDonEscalationLimit(0);
        assertEq(OracleMultiSig(oracle).donEscalationLimit(), 0);

        createMarket(0x0101000100010001010101000101000001010001010100000101000001010101, 1*10**18);
        simTradesInFavorOfOutcome0();
        expireMarket();
    }

    function test_zeroEscalationLimitSetOutcome(uint _outcome) public {
        uint outcome = _outcome % 3;
        checkStateMarketResolveWithZeroEscalationLimit();

        assertEq(Market(marketAddress).outcome(), 2); // outcome hasn't been set
        assertEq(uint(Market(marketAddress).stage()), 1); // stage is still MarketFunded

        uint oracleBalanceBefore = MemeToken(memeToken).balanceOf(oracle);
        OracleMultiSig(oracle).addTxSetMarketOutcome(outcome, marketAddress);
        uint oracleBalanceAfter = MemeToken(memeToken).balanceOf(oracle);
        assertEq(oracleBalanceAfter, oracleBalanceBefore); // fees earned should be zero since not staking

        assertEq(Market(marketAddress).outcome(), outcome);
        assertEq(uint(Market(marketAddress).stage()), 4); // market closed

        // redeem winnings
        if (outcome == 0){
            // redeem winnings
            redeemWinning(0, 10*10**18, 0);
            redeemWinning(1, 4*10**18, 0);
        }else if (outcome == 1){
            // redeem winnings
            redeemWinning(1, 4*10**18, 1);
            redeemWinning(0, 10*10**18, 1);
        }else if (outcome == 2){
            // redeem winnings
            redeemWinning(0, 10*10**18, 2);
            redeemWinning(1, 4*10**18, 2);
        }
    }
       
    // should fail
    function testFail_zeroEscalationLimitStakeOutcome() public {
        checkStateMarketResolveWithZeroEscalationLimit();
        simStakingRoundsBeforeEscalationLimit(2);
    }

    // should fail
    function testFail_zeroEscalationLimitRedeemWinning() public {
        checkStateMarketResolveWithZeroEscalationLimit();
        redeemWinning(0, 10*10**18, 0);
    }

    function testFail_zeroEscalationLimitPostResolutionPeriodExpires() public {
        checkStateMarketResolveWithZeroEscalationLimit();
        expireResolutionPeriod();
        OracleMultiSig(oracle).addTxSetMarketOutcome(0, marketAddress);
        assertEq(Market(marketAddress).outcome(), 0);
    }

    // post resolution buffer market resolves to favored
    function test_zeroEscalationLimitOutcomeSetToFavoredPostResolutionPeriodExpires() public {
        checkStateMarketResolveWithZeroEscalationLimit();

        expireResolutionPeriod();

        assertEq(Market(marketAddress).outcome(), 2);
        assertEq(uint(Market(marketAddress).stage()), 1); // market closed

        redeemWinning(0, 10*10**18, 0);
        redeemWinning(1, 4*10**18, 0);

        assertEq(Market(marketAddress).outcome(), 0);
        assertEq(uint(Market(marketAddress).stage()), 4); // market closed
    }

}
