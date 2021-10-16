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

contract MarketFundedTest is MarketTestsShared {
    
    function setUp() override public {
        commonSetup();
    }


    function test_marketCreationWithMarketFactory(bytes32 _identifier, uint120 _fundingAmount) public {
        if (_fundingAmount  == 0) return;
        createMarket(_identifier, _fundingAmount);

        // check market exists
        address _marktAddress = MarketRouter(marketRouter).getMarketAddress(address(this), oracle, _identifier);
        assertEq(_marktAddress, MarketFactory(marketFactory).markets(address(this), oracle, _identifier));

        // check market has been funded & tokenC balance == _fundingAmount
        assertEq(uint(Market(_marktAddress).stage()), uint(1));
        assertEq(MemeToken(memeToken).balanceOf(_marktAddress), _fundingAmount);

        // check outcome token balances == _fundingAmount
        (, address token0, address token1) = Market(_marktAddress).getAddressOfTokens();
        assertEq(OutcomeToken(token0).balanceOf(_marktAddress), _fundingAmount);
        assertEq(OutcomeToken(token1).balanceOf(_marktAddress), _fundingAmount);
    }

    function test_marketBuyPostFunding(bytes32 _identifier, uint120 _fundingAmount, uint120 _a0, uint120 _a1) public {
        if (_fundingAmount == 0) return;
        createMarket(_identifier, _fundingAmount);
        // buy amount
        uint a0 = uint(_a0);
        uint a1 = uint(_a1);
        uint a = Math.getAmountCToBuyTokens(a0, a1, _fundingAmount, _fundingAmount);
        MemeToken(memeToken).transfer(marketAddress, a);
        (, address token0, address token1) = Market(marketAddress).getAddressOfTokens();
        uint token0BalanceBefore = OutcomeToken(token0).balanceOf(address(this));
        uint token1BalanceBefore = OutcomeToken(token1).balanceOf(address(this));
        Market(marketAddress).buy(a0, a1, address(this));
        assertEq(OutcomeToken(token0).balanceOf(address(this)), token0BalanceBefore+a0);
        assertEq(OutcomeToken(token1).balanceOf(address(this)), token1BalanceBefore+a1);
    }

    function test_marketSellPostFunding(bytes32 _identifier, uint120 _fundingAmount, uint120 _a0, uint120 _a1) public {
        if (_fundingAmount == 0) return;
        createMarket(_identifier, _fundingAmount);
        address marketAddress = MarketRouter(marketRouter).getMarketAddress(address(this), oracle, _identifier);
        // buy amount
        uint a0 = _a0;
        uint a1 = _a1;
        uint a = Math.getAmountCToBuyTokens(a0, a1, _fundingAmount, _fundingAmount);
        MemeToken(memeToken).transfer(marketAddress, a);
        Market(marketAddress).buy(a0, a1, address(this));

        // sell tokens
        uint sa = Math.getAmountCBySellTokens(a0, a1, _fundingAmount + a - a0, _fundingAmount + a - a1);
        emit log_named_uint("Amount received ", sa);
        (, address token0, address token1) = Market(marketAddress).getAddressOfTokens();
        OutcomeToken(token0).transfer(marketAddress, a0);
        OutcomeToken(token1).transfer(marketAddress, a1);
        uint memeBalanceBefore = MemeToken(memeToken).balanceOf(address(this));
        Market(marketAddress).sell(sa, address(this));
        uint memeBalanceAfter = MemeToken(memeToken).balanceOf(address(this));
        assertEq(memeBalanceBefore + sa, memeBalanceAfter);
    }

    function testFail_fund() public {
        createDefaultMarket();

        simTradesInFavorOfOutcome0();

        MemeToken(memeToken).transfer(marketAddress, 10*10**18);
        Market(marketAddress).fund();
    }

    function testFail_setOutcomeTokens() public {
        createDefaultMarket();
        (, address _token0, address _token1) = Market(marketAddress).getAddressOfTokens();
        Market(marketAddress).setOutcomeTokens(_token0, _token1);
    }

    function testFailed_stakeOutcome() public {
        createDefaultMarket();
        simTradesInFavorOfOutcome0();
        simStakingRoundsBeforeEscalationLimit(sharedOracleConfig.donEscalationLimit);
    }

    function testFailed_redeemWinning() public {
        createDefaultMarket();
        simTradesInFavorOfOutcome0();
        redeemWinning(0, 10*10**18, 0);
    }
    function testFailed_redeemStake() public {
        createDefaultMarket();
        simTradesInFavorOfOutcome0();
        redeemStake(0, 0, 10*10**18, 0);
    }

    function testFailed_setOutcome() public {
        createDefaultMarket();
        simTradesInFavorOfOutcome0();

        OracleMultiSig(oracle).addTxSetMarketOutcome(0, marketAddress);
        assertEq(Market(marketAddress).outcome(), 0);
    }

    function testFailed_tradePostMarketExpiry() public {
        createDefaultMarket();
        simTradesInFavorOfOutcome0();

        expireMarket();

        (uint r0, uint r1) = Market(marketAddress).getReservesOTokens();
        uint a = Math.getAmountCToBuyTokens(10*10**18, 0, r0, r1);
        MemeToken(memeToken).transfer(marketAddress, a);
        Market(marketAddress).buy(10*10**18, 0, address(this));
    }
}
