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

contract MarketTest is DSTest {

    address memeToken;
    address oracle;
    address marketFactory;
    address marketRouter;

    address hevm = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

    function setUp() virtual public {
        marketFactory = address(new MarketFactory());
        marketRouter = address(new MarketRouter(marketFactory));

        memeToken = address(new MemeToken());
        MemeToken(memeToken).mint(address(this), type(uint).max);

        address[] memory oracleOwners = new address[](1);
        oracleOwners[0] = address(this);
        oracle = address(new OracleMultiSig(oracleOwners, 1, 10));
        OracleMultiSig(oracle).addTxSetupOracle(true, 10, 100, memeToken, 10, 10, 10, 10);
    }

    function getMarketContractInitBytecodeHash() external pure returns (bytes32 initHash){
        bytes memory initCode = type(Market).creationCode;
        initHash = keccak256(initCode);
    }

    function createMarket(bytes32 _identifier, uint _fundingAmount) internal {
        MemeToken(memeToken).approve(marketFactory, _fundingAmount);
        MarketFactory(marketFactory).createMarket(address(this), oracle, _identifier, _fundingAmount);
    }

    // function test_marketCreationWithMarketFactory(bytes32 _identifier, uint _fundingAmount) public {
    //     uint minAmount = 10**18;
    //     if (_fundingAmount < minAmount) return;
    //     createMarket(_identifier, _fundingAmount);

    //     // check market exists
    //     address _marktAddress = MarketRouter(marketRouter).getMarketAddress(address(this), oracle, _identifier);
    //     assertEq(_marktAddress, MarketFactory(marketFactory).markets(address(this), oracle, _identifier));

    //     // check market has been funded & tokenC balance == _fundingAmount
    //     assertEq(uint(Market(_marktAddress).stage()), uint(1));
    //     assertEq(MemeToken(memeToken).balanceOf(_marktAddress), _fundingAmount);

    //     // check outcome token balances == _fundingAmount
    //     (, address token0, address token1) = Market(_marktAddress).getAddressOfTokens();
    //     assertEq(OutcomeToken(token0).balanceOf(_marktAddress), _fundingAmount);
    //     assertEq(OutcomeToken(token1).balanceOf(_marktAddress), _fundingAmount);
    // }

    // function test_marketBuyPostFunding(bytes32 _identifier, uint112 _fundingAmount, uint112 _a0, uint112 _a1) public {
    //     uint minAmount = 10**18;
    //     if (_fundingAmount < minAmount || _a0 < minAmount || _a1 < minAmount) return;

    //     createMarket(_identifier, _fundingAmount);
    //     address _marketAddress = MarketRouter(marketRouter).getMarketAddress(address(this), oracle, _identifier);

    //     // buy amount
    //     uint a0 = _a0;
    //     uint a1 = _a1;
    //     uint a = Math.getAmountCToBuyTokens(a0, a1, _fundingAmount, _fundingAmount);
    //     MemeToken(memeToken).transfer(_marketAddress, a);
    //     (, address token0, address token1) = Market(_marketAddress).getAddressOfTokens();
    //     uint token0BalanceBefore = OutcomeToken(token0).balanceOf(address(this));
    //     uint token1BalanceBefore = OutcomeToken(token1).balanceOf(address(this));
    //     Market(_marketAddress).buy(a0, a1, address(this));
    //     assertEq(OutcomeToken(token0).balanceOf(address(this)), token0BalanceBefore+a0);
    //     assertEq(OutcomeToken(token1).balanceOf(address(this)), token1BalanceBefore+a1);
    // }

    // function test_marketSellPostFunding(bytes32 _identifier, uint112 _fundingAmount, uint112 _a0, uint112 _a1) public {
    //     uint minAmount = 10**18;
    //     if (_fundingAmount < minAmount || _a0 < minAmount || _a1 < minAmount) return;

    //     createMarket(_identifier, _fundingAmount);
    //     address _marketAddress = MarketRouter(marketRouter).getMarketAddress(address(this), oracle, _identifier);

    //     // buy amount
    //     uint a0 = _a0;
    //     uint a1 = _a1;
    //     uint a = Math.getAmountCToBuyTokens(a0, a1, _fundingAmount, _fundingAmount);
    //     MemeToken(memeToken).transfer(_marketAddress, a);
    //     Market(_marketAddress).buy(a0, a1, address(this));

    //     // sell tokens
    //     uint sa = Math.getAmountCBySellTokens(a0, a1, _fundingAmount + a - a0, _fundingAmount + a - a1);
    //     (, address token0, address token1) = Market(_marketAddress).getAddressOfTokens();
    //     OutcomeToken(token0).transfer(_marketAddress, a0);
    //     OutcomeToken(token1).transfer(_marketAddress, a1);
    //     uint memeBalanceBefore = MemeToken(memeToken).balanceOf(address(this));
    //     Market(_marketAddress).sell(sa, address(this));
    //     uint memeBalanceAfter = MemeToken(memeToken).balanceOf(address(this));
    //     assertEq(memeBalanceBefore + sa, memeBalanceAfter);
    // }

    // function testFailed_setOutcomeTokens(){}
    // function testFailed_fund(){}
    // function testFailed_stakeOutcome(){}
    // function testFailed_redeemWinning(){}
    // function testFailed_redeemStake(){}
    // function testFailed_setOutcome(){}

    // function testFailed_tradePostMarketExpiry(){}
}

contract MarketBufferPostExpiration is MarketTest {

    address _marketAddress;

    function setUp() override public {
        marketFactory = address(new MarketFactory());
        marketRouter = address(new MarketRouter(marketFactory));

        memeToken = address(new MemeToken());
        MemeToken(memeToken).mint(address(this), type(uint).max);

        address[] memory oracleOwners = new address[](1);
        oracleOwners[0] = address(this);
        oracle = address(new OracleMultiSig(oracleOwners, 1, 10));
        OracleMultiSig(oracle).addTxSetupOracle(true, 10, 100, memeToken, 10, 3, 10, 10);

        // create market
        uint _fundingAmount = 1*10**18;
        bytes32 _identifier = 0x0401030400040101040403020201030003000000010202020104010201000103;
        MemeToken(memeToken).approve(marketFactory, _fundingAmount);
        MarketFactory(marketFactory).createMarket(address(this), oracle, _identifier, _fundingAmount);
        _marketAddress = MarketRouter(marketRouter).getMarketAddress(address(this), oracle, _identifier);

        // expire market
        (bool success, bytes memory data) = hevm.call(abi.encodeWithSignature("roll(uint256)", block.number+10));
        require(success, "block didn't roll");

    }

    function test_stakeOutcome() public {
    
        assertEq(uint(Market(_marketAddress).stage()), uint(1));

        // staking
        uint marketBalanceBefore = MemeToken(memeToken).balanceOf(_marketAddress);
        MemeToken(memeToken).transfer(_marketAddress, 2*10**18); // 1st stake
        Market(_marketAddress).stakeOutcome(0, address(this));
        MemeToken(memeToken).transfer(_marketAddress, 4*10**18); // 2nd stake
        Market(_marketAddress).stakeOutcome(1, address(this));
        uint marketBalanceAfter = MemeToken(memeToken).balanceOf(_marketAddress);
        assertEq(marketBalanceAfter, marketBalanceBefore+6*10**18);
        assertEq(2*10**18, Market(_marketAddress).getStake(address(this), 0));
        assertEq(4*10**18, Market(_marketAddress).getStake(address(this), 1));

        assertEq(uint(Market(_marketAddress).stage()), uint(2));
    }

    function testFailed_stakeOutcomeZeroStake() public {
        Market(_marketAddress).stakeOutcome(0, address(this));
        assertEq(uint(Market(_marketAddress).stage()), uint(1));
    }

    function testFailed_stakeOutcomeInvalidOutome() public {
        Market(_marketAddress).stakeOutcome(2, address(this));
    }

    function testFailed_stakeOutcomeInvalidSubsequentAmount() public {
        MemeToken(memeToken).transfer(_marketAddress, 2*10**18); // 1st stake
        Market(_marketAddress).stakeOutcome(0, address(this));

        MemeToken(memeToken).transfer(_marketAddress, 3*10**18); // 2nd stake invalid
        Market(_marketAddress).stakeOutcome(0, address(this));
    }

    function test_stakeOutcomeTillEscalationLimit() public {
        assertEq(uint(Market(_marketAddress).stage()), uint(1));

        // 5 valid stakes
        MemeToken(memeToken).transfer(_marketAddress, 2*10**18); 
        Market(_marketAddress).stakeOutcome(0, address(this));
        assertEq(uint(Market(_marketAddress).stage()), uint(2));
        MemeToken(memeToken).transfer(_marketAddress, 4*10**18); 
        Market(_marketAddress).stakeOutcome(1, address(this));
        MemeToken(memeToken).transfer(_marketAddress, 8*10**18); 
        Market(_marketAddress).stakeOutcome(0, address(this));  // escalation limit reached

        assertEq(uint(Market(_marketAddress).stage()), uint(3)); // market stage is now MarketResolution
    }
}
