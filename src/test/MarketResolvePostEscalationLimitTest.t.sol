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

contract MarketResolvePostEscalationLimitTest is MarketTestsShared {

    function setUp() override public {
        commonSetup();
        createDefaultMarket();

        // carry few trades
        simTradesInFavorOfOutcome0();

        // expire market
        expireMarket();

        // stake till escalation limit exceeds
        simStakingRoundsTillEscalationLimit(sharedOracleConfig.donEscalationLimit);
    }

    function test_setOutcome(uint outcome) public {
        // if (outcome > 2) return;
        outcome = 1;
        assertEq(Market(marketAddress).outcome(), 2); // outcome hasn't been set
        assertEq(uint(Market(marketAddress).stage()), 3); // stage is resolve

        uint oracleBalanceBefore = MemeToken(memeToken).balanceOf(oracle);
        OracleMultiSig(oracle).addTxSetMarketOutcome(outcome, marketAddress);
        uint oracleBalanceAfter = MemeToken(memeToken).balanceOf(oracle);
        uint oracleFee;
        if (outcome != 2){
            oracleFee = (simStakingInfo.stakeAmounts[1-simStakingInfo.lastOutcomeStaked]*sharedOracleConfig.feeNum)/sharedOracleConfig.feeDenom;
        }
        assertEq(oracleBalanceAfter, oracleBalanceBefore+oracleFee); // fees earned

        assertEq(Market(marketAddress).outcome(), outcome);
        assertEq(uint(Market(marketAddress).stage()), 4); // market closed

        // redeem stake
        if (outcome == 0){
            // redeem stakes
            redeemStake(0, 0, simStakingInfo.stakeAmounts[0], ((simStakingInfo.stakeAmounts[1])*sharedOracleConfig.feeNum)/sharedOracleConfig.feeDenom);
            redeemStake(1, 0, simStakingInfo.stakeAmounts[1], 0);

            // redeem winnings
            redeemWinning(0, 10*10**18, 0);
            redeemWinning(1, 4*10**18, 0);
        }else if (outcome == 1){
            // redeem stakes
            redeemStake(1, 1, simStakingInfo.stakeAmounts[1], ((simStakingInfo.stakeAmounts[0])*sharedOracleConfig.feeNum)/sharedOracleConfig.feeDenom);
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

    function testFail_setInvalidOutcome() public {
        OracleMultiSig(oracle).addTxSetMarketOutcome(3, marketAddress);
    }

    function testFail_setOutcomePostResolutionPeriodExpires() public {
        (bool success, bytes memory data) = hevm.call(abi.encodeWithSignature("roll(uint256)", block.number+10));
        OracleMultiSig(oracle).addTxSetMarketOutcome(0, marketAddress);
        assertEq(Market(marketAddress).outcome(), 0);   
    }

    function test_outcomeSetToLastStakedPostResolutionPeriodExpires() public {
        (bool success, bytes memory data) = hevm.call(abi.encodeWithSignature("roll(uint256)", block.number+10));

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

}
