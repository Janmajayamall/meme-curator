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

contract MarketTest is MarketTestsShared {
    
    function setUp() override public {
        commonSetup();
    }

    function createMarket(bytes32 _identifier, uint _fundingAmount) internal {
        MemeToken(memeToken).approve(marketFactory, _fundingAmount);
        MarketFactory(marketFactory).createMarket(address(this), oracle, _identifier, _fundingAmount);
        marketAddress = MarketRouter(marketRouter).getMarketAddress(address(this), oracle, _identifier);        
    }

    function test_marketCreationWithMarketFactory(bytes32 _identifier, uint _fundingAmount) public {
        uint minAmount = 10**18;
        if (_fundingAmount < minAmount) return;
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

    function test_marketBuyPostFunding(bytes32 _identifier, uint112 _fundingAmount, uint112 _a0, uint112 _a1) public {
        uint minAmount = 10**18;
        if (_fundingAmount < minAmount || _a0 < minAmount || _a1 < minAmount) return;

        createMarket(_identifier, _fundingAmount);
        address marketAddress = MarketRouter(marketRouter).getMarketAddress(address(this), oracle, _identifier);

        // buy amount
        uint a0 = _a0;
        uint a1 = _a1;
        uint a = Math.getAmountCToBuyTokens(a0, a1, _fundingAmount, _fundingAmount);
        MemeToken(memeToken).transfer(marketAddress, a);
        (, address token0, address token1) = Market(marketAddress).getAddressOfTokens();
        uint token0BalanceBefore = OutcomeToken(token0).balanceOf(address(this));
        uint token1BalanceBefore = OutcomeToken(token1).balanceOf(address(this));
        Market(marketAddress).buy(a0, a1, address(this));
        assertEq(OutcomeToken(token0).balanceOf(address(this)), token0BalanceBefore+a0);
        assertEq(OutcomeToken(token1).balanceOf(address(this)), token1BalanceBefore+a1);
    }

    function test_marketSellPostFunding(bytes32 _identifier, uint112 _fundingAmount, uint112 _a0, uint112 _a1) public {
        uint minAmount = 10**18;
        if (_fundingAmount < minAmount || _a0 < minAmount || _a1 < minAmount) return;

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
        (, address token0, address token1) = Market(marketAddress).getAddressOfTokens();
        OutcomeToken(token0).transfer(marketAddress, a0);
        OutcomeToken(token1).transfer(marketAddress, a1);
        uint memeBalanceBefore = MemeToken(memeToken).balanceOf(address(this));
        Market(marketAddress).sell(sa, address(this));
        uint memeBalanceAfter = MemeToken(memeToken).balanceOf(address(this));
        assertEq(memeBalanceBefore + sa, memeBalanceAfter);
    }

    // function testFailed_setOutcomeTokens(){}
    // function testFailed_fund(){}
    // function testFailed_stakeOutcome(){}
    // function testFailed_redeemWinning(){}
    // function testFailed_redeemStake(){}
    // function testFailed_setOutcome(){}

    // function testFailed_tradePostMarketExpiry(){}
}

// contract MarketResolvePostBufferExpiry is MarketTestsShared, DSTest {

//     address marketAddress;

//     function setUp() override public {
//         marketFactory = address(new MarketFactory());
//         marketRouter = address(new MarketRouter(marketFactory));

//         memeToken = address(new MemeToken());
//         MemeToken(memeToken).mint(address(this), type(uint).max);

//         address[] memory oracleOwners = new address[](1);
//         oracleOwners[0] = address(this);
//         oracle = address(new OracleMultiSig(oracleOwners, 1, 10));
//         OracleMultiSig(oracle).addTxSetupOracle(true, 10, 100, memeToken, 10, 3, 10, 10);

//         // create market
//         uint _fundingAmount = 1*10**18;
//         bytes32 _identifier = 0x0401030400040101040403020201030003000000010202020104010201000103;
//         MemeToken(memeToken).approve(marketFactory, _fundingAmount);
//         MarketFactory(marketFactory).createMarket(address(this), oracle, _identifier, _fundingAmount);
//         marketAddress = MarketRouter(marketRouter).getMarketAddress(address(this), oracle, _identifier);

//         // few trades
//         uint a0 = 10*10**18;
//         uint a1 = 0;
//         uint a = Math.getAmountCToBuyTokens(a0, a1, _fundingAmount, _fundingAmount);
//         MemeToken(memeToken).transfer(marketAddress, a);
//         Market(marketAddress).buy(a0, a1, address(this));
//         a0 = 0;
//         a1 = 4*10**18;
//         a = Math.getAmountCToBuyTokens(a0, a1, _fundingAmount, _fundingAmount);
//         MemeToken(memeToken).transfer(marketAddress, a);
//         Market(marketAddress).buy(a0, a1, address(this));

//         // expire market
//         (bool success, bytes memory data) = hevm.call(abi.encodeWithSignature("roll(uint256)", block.number+10));
//     }

//     function test_marketResolvedToLastStake() public {
//         // few staking rounds
//         MemeToken(memeToken).transfer(marketAddress, 2*10**18); 
//         Market(marketAddress).stakeOutcome(0, address(this));
//         assertEq(uint(Market(marketAddress).stage()), uint(2));
//         MemeToken(memeToken).transfer(marketAddress, 4*10**18); 
//         Market(marketAddress).stakeOutcome(1, address(this));

//         // expire buffer period
//         (bool success, bytes memory data) = hevm.call(abi.encodeWithSignature("roll(uint256)", block.number+10));

//         assertEq(uint(Market(marketAddress).stage()), 2);

//         // redeem stake - close & resolve the market
//         Market(marketAddress).redeemStake(1);
//         assertEq(uint(Market(marketAddress).stage()), 4); 

//         // outcome is 1 - last staked outcome
//         assertEq(Market(marketAddress).outcome(), 1);
//     }

//     function test_marketResolvedToFavoredOutcomeWithNoPriorStake() public {
        
//     }
// }

// // contract MarketClosed is Market {
// //     // resolve by resolution by oracle
// //     // resolve by expiry after oracle
// // }