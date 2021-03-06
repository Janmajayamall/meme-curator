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
import "./MarketTestShared.t.sol";

contract MarketTestStageFunded is MarketTestShared {
    
    function setUp() override public {
        commonSetup();
    }

    struct DeployParams {
        address creator;
        address oracle;
        string identifier;
    }
    DeployParams public deployParams;

    function test_marketCreation() public  {
        deployParams = DeployParams({creator: address(this), oracle: oracle, identifier:sharedIdentifier});
        address marketAddress = address(new Market());
    }

    function testFail_marketCreationInactiveOracle() public  {
        address[] memory oracleOwners = new address[](1);
        oracleOwners[0] = address(this);
        address tempOracle = address(new OracleMultiSig(oracleOwners, 1, 10, address(this)));
        OracleMultiSig(tempOracle).addTxSetupOracle(
            sharedOracleConfig.tokenC,
            false,
            sharedOracleConfig.feeNumerator,
            sharedOracleConfig.feeDenominator,
            sharedOracleConfig.donEscalationLimit,
            sharedOracleConfig.expireBufferBlocks,
            sharedOracleConfig.donBufferBlocks,
            sharedOracleConfig.resolutionBufferBlocks
        );

        deployParams = DeployParams({creator: address(this), oracle: tempOracle, identifier:sharedIdentifier});
        address marketAddress = address(new Market());
    }

    function testFail_marketCreationWithInvalidOracleFee() public {
        address[] memory oracleOwners = new address[](1);
        oracleOwners[0] = address(this);
        address tempOracle = address(new OracleMultiSig(oracleOwners, 1, 10, address(this)));
        OracleMultiSig(tempOracle).addTxSetupOracle(
            sharedOracleConfig.tokenC,
            sharedOracleConfig.isActive,
            100,
            99,
            sharedOracleConfig.donEscalationLimit,
            sharedOracleConfig.expireBufferBlocks,
            sharedOracleConfig.donBufferBlocks,
            sharedOracleConfig.resolutionBufferBlocks
        );

        deployParams = DeployParams({creator: address(this), oracle: tempOracle, identifier:sharedIdentifier});
        address marketAddress = address(new Market());
    }


    function test_marketCreationWithMarketFactory() public {
        MarketFactory(marketFactory).createMarket(address(this), oracle, sharedIdentifier);
        address expectedAddress = getExpectedMarketAddress(sharedIdentifier);
        emit log_named_address("addressss", expectedAddress);

        uint size;
        assembly {
            size := extcodesize(expectedAddress)
        }

        assertGt(size,0);

        // // check market has been funded & tokenC balance == _fundingAmount
        // assertEq(getMarketStage(expectedAddress), uint(1));
        // assertEq(MemeToken(memeToken).balanceOf(expectedAddress), _fundingAmount);

        // // check outcome token balances == _fundingAmount
        // (,address token0, address token1) = Market(expectedAddress).getTokenAddresses();
        // assertEq(OutcomeToken(token0).balanceOf(expectedAddress), _fundingAmount);
        // assertEq(OutcomeToken(token1).balanceOf(expectedAddress), _fundingAmount);
        // assertTrue(false);

    }

    function testFail_marketCreationWithMarketFactoryTwice() public {
        MarketFactory(marketFactory).createMarket(address(this), oracle, sharedIdentifier);
        MarketFactory(marketFactory).createMarket(address(this), oracle, sharedIdentifier);
    }


    function test_marketCreationWithMarketRouter(uint120 _fundingAmount) public {
        if (_fundingAmount  == 0) return;
        MemeToken(memeToken).approve(marketRouter, uint256(_fundingAmount)+1*10**18);
        MarketRouter(marketRouter).createAndPlaceBetOnMarket(address(this), oracle, "http://www.google.com/", _fundingAmount, 1*10**18, 1);
        // check market exists
        address expectedAddress = getExpectedMarketAddress("http://www.google.com/");

        // check market has been funded & tokenC balance == _fundingAmount
        assertEq(getMarketStage(expectedAddress), uint(1));
        assertEq(MemeToken(memeToken).balanceOf(expectedAddress), uint(_fundingAmount)+1*10**18);

        // check outcome token balances == _fundingAmount
        (,address token0, address token1) = Market(expectedAddress).getTokenAddresses();
        assertEq(OutcomeToken(token0).balanceOf(expectedAddress), uint(_fundingAmount)+1*10**18);
        assertEq(OutcomeToken(token1).balanceOf(expectedAddress), _fundingAmount);
    }

    function testFail_marketCreationWithMarketRouterTwice() public {
        MemeToken(memeToken).approve(marketRouter, 4*10**18);
        MarketRouter(marketRouter).createAndPlaceBetOnMarket(address(this), oracle, sharedIdentifier, 1*10**18, 1*10**18, 1);
        MarketRouter(marketRouter).createAndPlaceBetOnMarket(address(this), oracle, sharedIdentifier, 1*10**18, 1*10**18, 1); // this should fail
    }

    function test_marketBuyPostFunding(bytes32 _identifier, uint120 _fundingAmount, uint120 _a0, uint120 _a1) public {
        if (_fundingAmount == 0) return;
        createMarket("dwada", _fundingAmount);
        // buy amount
        uint a0 = uint(_a0);
        uint a1 = uint(_a1);
        uint a = Math.getAmountCToBuyTokens(a0, a1, _fundingAmount, _fundingAmount);
        MemeToken(memeToken).transfer(marketAddress, a);
        (,address token0, address token1) = Market(marketAddress).getTokenAddresses();
        uint token0BalanceBefore = OutcomeToken(token0).balanceOf(address(this));
        uint token1BalanceBefore = OutcomeToken(token1).balanceOf(address(this));
        Market(marketAddress).buy(a0, a1, address(this));
        assertEq(OutcomeToken(token0).balanceOf(address(this)), token0BalanceBefore+a0);
        assertEq(OutcomeToken(token1).balanceOf(address(this)), token1BalanceBefore+a1);
        keepReservesAndBalsInCheck();
    }

    function test_marketSellPostFunding(uint120 _fundingAmount, uint120 _a0, uint120 _a1) public {
        if (_fundingAmount == 0) return;
        createMarket("dwadadadadadadadadada", _fundingAmount);

        // buy amount
        uint a0 = _a0;
        uint a1 = _a1;
        uint a = Math.getAmountCToBuyTokens(a0, a1, _fundingAmount, _fundingAmount);
        MemeToken(memeToken).transfer(marketAddress, a);
        Market(marketAddress).buy(a0, a1, address(this));
        keepReservesAndBalsInCheck();
        emit log_named_uint(" a0 ", a0);
        emit log_named_uint(" a1 ", a1);
        emit log_named_uint(" a ", a);
        emit log_named_uint("_fuding", _fundingAmount);
        emit log_named_uint("r0", _fundingAmount + a - a0);
        emit log_named_uint("r1", _fundingAmount + a - a1);
        // sell tokens
        uint sa = Math.getAmountCBySellTokens(a0, a1, _fundingAmount + a - a0, _fundingAmount + a - a1);
        (,address token0, address token1) = Market(marketAddress).getTokenAddresses();
        OutcomeToken(token0).transfer(marketAddress, a0);
        OutcomeToken(token1).transfer(marketAddress, a1);
        uint memeBalanceBefore = MemeToken(memeToken).balanceOf(address(this));
        Market(marketAddress).sell(sa, address(this));
        uint memeBalanceAfter = MemeToken(memeToken).balanceOf(address(this));
        assertEq(memeBalanceBefore + sa, memeBalanceAfter);
        keepReservesAndBalsInCheck();
    }

    function testFail_fund() public {
        createDefaultMarket();

        simTradesInFavorOfOutcome0();

        MemeToken(memeToken).transfer(marketAddress, 10*10**18);
        Market(marketAddress).fund();
    }

    function testFail_stakeOutcome() public {
        createDefaultMarket();
        simTradesInFavorOfOutcome0();
        simStakingRoundsBeforeEscalationLimit(sharedOracleConfig.donEscalationLimit);
    }

    function testFail_redeemWinning() public {
        createDefaultMarket();
        simTradesInFavorOfOutcome0();
        redeemWinning(0, 10*10**18, 0);
    }

    function testFail_redeemStake() public {
        createDefaultMarket();
        simTradesInFavorOfOutcome0();
        redeemStake(0, 0, 10*10**18, 0);
    }

    function testFail_setOutcome() public {
        createDefaultMarket();
        simTradesInFavorOfOutcome0();

        OracleMultiSig(oracle).addTxSetMarketOutcome(0, marketAddress);
        assertEq(getMarketOutcome(marketAddress), 0);
    }

    function testFail_tradePostMarketExpiry() public {
        createDefaultMarket();
        simTradesInFavorOfOutcome0();

        expireMarket();

        (uint r0, uint r1) = Market(marketAddress).getOutcomeReserves();
        uint a = Math.getAmountCToBuyTokens(10*10**18, 0, r0, r1);
        MemeToken( memeToken).transfer(marketAddress, a);
        Market(marketAddress).buy(10*10**18, 0, address(this));
    }
}
