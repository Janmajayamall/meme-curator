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

contract MarketBuffer is MarketTestsShared {
    function setUp() override public {
        commonSetup();
        emit log_named_uint("Balance of contract ", MemeToken(memeToken).balanceOf(address(this)));
        createDefaultMarket();
    }

    function test_stakeOutcome() public {
        expireMarket();
    
        assertEq(uint(Market(marketAddress).stage()), uint(1));

        // staking
        uint marketBalanceBefore = MemeToken(memeToken).balanceOf(marketAddress);
        simStakingRoundsBeforeEscalationLimit(sharedOracleConfig.donEscalationLimit);
        uint marketBalanceAfter = MemeToken(memeToken).balanceOf(marketAddress);
        assertEq(marketBalanceAfter, marketBalanceBefore+simStakingInfo.stakeAmounts[0]+simStakingInfo.stakeAmounts[1]);
        assertEq(simStakingInfo.stakeAmounts[0], Market(marketAddress).getStake(address(this), 0));
        assertEq(simStakingInfo.stakeAmounts[1], Market(marketAddress).getStake(address(this), 1));

        assertEq(uint(Market(marketAddress).stage()), uint(2));
    }

    function testFailed_stakeOutcomeZeroStakeAmount() public {
        expireMarket();
        Market(marketAddress).stakeOutcome(0, address(this));
        assertEq(uint(Market(marketAddress).stage()), uint(1));
    }

    function testFailed_stakeOutcomeInvalidOutcome() public {
        expireMarket();
        Market(marketAddress).stakeOutcome(2, address(this));
    }

    function testFailed_stakeOutcomeInvalidSubsequentAmount() public {
        expireMarket();

        MemeToken(memeToken).transfer(marketAddress, 2*10**18); // 1st stake
        Market(marketAddress).stakeOutcome(0, address(this));

        MemeToken(memeToken).transfer(marketAddress, 3*10**18); // 2nd stake invalid
        Market(marketAddress).stakeOutcome(0, address(this));
    }

    function test_stakeOutcomeTillEscalationLimit() public {
        expireMarket();

        assertEq(uint(Market(marketAddress).stage()), uint(1));

        // 3 valid stakes
        simStakingRoundsTillEscalationLimit(sharedOracleConfig.donEscalationLimit);

        assertEq(uint(Market(marketAddress).stage()), uint(3)); // market stage is now MarketResolution
    }

    function testFail_stakeOutcomePostExceedingEscalationLimit() public {
        expireMarket();
        assertEq(uint(Market(marketAddress).stage()), uint(1));

        // hit escalation limit
        simStakingRoundsTillEscalationLimit(sharedOracleConfig.donEscalationLimit);

        // should fail since market is in stage Market Resolve
        MemeToken(memeToken).transfer(marketAddress, simStakingInfo.lastAmountStaked*2); 
        Market(marketAddress).stakeOutcome(0, address(this)); 
    }

    function testFailed_stakeOutcomePostBufferExpiryWithNoPriorStakes() public {
        // tilt odds in favour of outcome 0
        simTradesInFavorOfOutcome0();
        expireMarket();
        // expire buffer period
        expireBufferPeriod();

        MemeToken(memeToken).transfer(marketAddress, 2*10**18); 
        Market(marketAddress).stakeOutcome(0, address(this)); 
    }

    function testFailed_stakeOutcomePostBufferExpiryWithPriorStakes() public {
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
        redeemWinning(1, 4*10**18, 0);

        // market resolved to outcome 0 & market stage is 0 
        assertEq(uint(Market(marketAddress).stage()), 4); 
        assertEq(Market(marketAddress).outcome(), 0); 
    }

    function test_outcomeSetToLastStakedOutcomePostBufferExpiry() public {
        simTradesInFavorOfOutcome0();
        expireMarket();

        // few staking rounds
        simStakingRoundsBeforeEscalationLimit(sharedOracleConfig.donEscalationLimit);

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

        // market resolved 
        assertEq(uint(Market(marketAddress).stage()), 4); 
        assertEq(Market(marketAddress).outcome(), simStakingInfo.lastOutcomeStaked); 
    }

}