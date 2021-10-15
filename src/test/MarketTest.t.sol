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

contract MarketTestsShared is DSTest {

    struct OracleConfig {
        bool isActive;
        uint feeNum;
        uint feeDenom;
        address tokenC;
        uint expireAfterBlocks;
        uint donEscalationLimit;
        uint donBufferBlocks;
        uint resolutionBufferBlocks;
    }

    struct StakingInfo {
        uint lastOutcomeStaked;
        uint lastAmountStaked;
        uint[2] stakeAmounts;
    }

    address memeToken;
    address oracle;
    address marketFactory;
    address marketRouter;
    address marketAddress;

    OracleConfig sharedOracleConfig;
    StakingInfo simStakingInfo;
    uint sharedFundingAmount = 1*10**18;

    address hevm = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

    function commonSetup() internal {
        marketFactory = address(new MarketFactory());
        marketRouter = address(new MarketRouter(marketFactory));

        memeToken = address(new MemeToken());
        MemeToken(memeToken).mint(address(this), type(uint).max);

        address[] memory oracleOwners = new address[](1);
        oracleOwners[0] = address(this);
        oracle = address(new OracleMultiSig(oracleOwners, 1, 10));
        sharedOracleConfig = OracleConfig(true, 10, 100, memeToken, 10, 5, 10, 10);
        OracleMultiSig(oracle).addTxSetupOracle(
            sharedOracleConfig.isActive,
            sharedOracleConfig.feeNum,
            sharedOracleConfig.feeDenom,
            sharedOracleConfig.tokenC,
            sharedOracleConfig.expireAfterBlocks,
            sharedOracleConfig.donEscalationLimit,
            sharedOracleConfig.donBufferBlocks,
            sharedOracleConfig.resolutionBufferBlocks
        );
    }

    function createDefaultMarket() internal {
        MemeToken(memeToken).approve(marketFactory, sharedFundingAmount);
        bytes32 _identifier = 0x0401030400040101040403020201030003000000010202020104010201000103;
        MarketFactory(marketFactory).createMarket(address(this), oracle, _identifier, sharedFundingAmount);
        marketAddress = MarketRouter(marketRouter).getMarketAddress(address(this), oracle, _identifier);        
    }

    function getMarketContractInitBytecodeHash() internal returns (bytes32 initHash){
        bytes memory initCode = type(Market).creationCode;
        initHash = keccak256(initCode);
    }

    function redeemStake(uint _for, uint outcome, uint stakeAmount, uint expectedWinning) internal {
        uint tokenCBalanceBefore = MemeToken(memeToken).balanceOf(address(this));
        Market(marketAddress).redeemStake(_for);
        uint tokenCBalanceAfter = MemeToken(memeToken).balanceOf(address(this));

        if (_for == outcome){
            assertEq(tokenCBalanceAfter, tokenCBalanceBefore + stakeAmount + expectedWinning);
        }else if (outcome == 2){
            assertEq(tokenCBalanceAfter, tokenCBalanceBefore + stakeAmount);
        }else {
            assertEq(tokenCBalanceAfter, tokenCBalanceBefore);
        }
    }

    function redeemWinning(uint _for, uint tokenAmount, uint _outcome) internal {
        (, address token0, address token1) = Market(marketAddress).getAddressOfTokens();
        if (_for == 0){
            OutcomeToken(token0).transfer(marketAddress, tokenAmount);
        }else if (_for == 1){
            OutcomeToken(token1).transfer(marketAddress, tokenAmount);
        }
        uint tokenCBalanceBefore = MemeToken(memeToken).balanceOf(address(this));
        Market(marketAddress).redeemWinning(_for, address(this));
        uint tokenCBalanceAfter = MemeToken(memeToken).balanceOf(address(this));

        uint expectedWin;
        if (_outcome == 2){
            expectedWin = tokenAmount/2;
        }else if (_outcome == _for){
            expectedWin = tokenAmount;
        }

        assertEq(tokenCBalanceAfter, tokenCBalanceBefore+expectedWin);
    }

    function simTradesInFavorOfOutcome0() internal {
        uint a0 = 10*10**18;
        uint a1 = 0;
        uint a = Math.getAmountCToBuyTokens(a0, a1, sharedFundingAmount, sharedFundingAmount);
        MemeToken(memeToken).transfer(marketAddress, a);
        Market(marketAddress).buy(a0, a1, address(this));
        a0 = 0;
        a1 = 4*10**18;
        a = Math.getAmountCToBuyTokens(a0, a1, sharedFundingAmount+a-10*10**18, sharedFundingAmount+a);
        MemeToken(memeToken).transfer(marketAddress, a);
        Market(marketAddress).buy(a0, a1, address(this));
    }

    function simTradesInFavorOfOutcome1() internal {
        uint a1 = 10*10**18;
        uint a0 = 0;
        uint a = Math.getAmountCToBuyTokens(a0, a1, sharedFundingAmount, sharedFundingAmount);
        MemeToken(memeToken).transfer(marketAddress, a);
        Market(marketAddress).buy(a0, a1, address(this));
        a1 = 0;
        a0 = 4*10**18;
        a = Math.getAmountCToBuyTokens(a0, a1, sharedFundingAmount+a, sharedFundingAmount+a-10*10**18);
        MemeToken(memeToken).transfer(marketAddress, a);
        Market(marketAddress).buy(a0, a1, address(this));
    }

    function simStakingRoundsTillEscalationLimit(uint escalationLimit) internal {
        simStakingInfo.lastAmountStaked = 0;
        simStakingInfo.lastOutcomeStaked = 2;
        simStakingInfo.stakeAmounts[0] = 0;
        simStakingInfo.stakeAmounts[1] = 0;
        for (uint index = 0; index < escalationLimit; index++) {
            uint _amount = (2*10**18)*(2**index);
            uint _outcome = index % 2;
            MemeToken(memeToken).transfer(marketAddress, _amount); 
            Market(marketAddress).stakeOutcome(_outcome, address(this));
            simStakingInfo.lastOutcomeStaked = _outcome;
            simStakingInfo.lastAmountStaked = _amount;
            simStakingInfo.stakeAmounts[_outcome] += _amount;
        }
    }

    function simStakingRoundsBeforeEscalationLimit(uint escalationLimit) internal {
        simStakingInfo.lastAmountStaked = 0;
        simStakingInfo.lastOutcomeStaked = 2;
        simStakingInfo.stakeAmounts[0] = 0;
        simStakingInfo.stakeAmounts[1] = 0;
        for (uint index = 0; index < escalationLimit-1; index++) {
            uint _amount = (2*10**18)*(2**index);
            uint _outcome = index % 2;
            MemeToken(memeToken).transfer(marketAddress, _amount); 
            Market(marketAddress).stakeOutcome(_outcome, address(this));
            simStakingInfo.lastOutcomeStaked = _outcome;
            simStakingInfo.lastAmountStaked = _amount;
            simStakingInfo.stakeAmounts[_outcome] += _amount;
        }
    }

    function setUp() virtual public {
        commonSetup();
    }
}

contract MarketTest is MarketTestsShared {
    
    function setUp() override public {
        marketFactory = address(new MarketFactory());
        marketRouter = address(new MarketRouter(marketFactory));

        memeToken = address(new MemeToken());
        MemeToken(memeToken).mint(address(this), type(uint).max);

        address[] memory oracleOwners = new address[](1);
        oracleOwners[0] = address(this);
        oracle = address(new OracleMultiSig(oracleOwners, 1, 10));
        OracleMultiSig(oracle).addTxSetupOracle(true, 10, 100, memeToken, 10, 10, 10, 10);
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
    //     address marketAddress = MarketRouter(marketRouter).getMarketAddress(address(this), oracle, _identifier);

    //     // buy amount
    //     uint a0 = _a0;
    //     uint a1 = _a1;
    //     uint a = Math.getAmountCToBuyTokens(a0, a1, _fundingAmount, _fundingAmount);
    //     MemeToken(memeToken).transfer(marketAddress, a);
    //     (, address token0, address token1) = Market(marketAddress).getAddressOfTokens();
    //     uint token0BalanceBefore = OutcomeToken(token0).balanceOf(address(this));
    //     uint token1BalanceBefore = OutcomeToken(token1).balanceOf(address(this));
    //     Market(marketAddress).buy(a0, a1, address(this));
    //     assertEq(OutcomeToken(token0).balanceOf(address(this)), token0BalanceBefore+a0);
    //     assertEq(OutcomeToken(token1).balanceOf(address(this)), token1BalanceBefore+a1);
    // }

    // function test_marketSellPostFunding(bytes32 _identifier, uint112 _fundingAmount, uint112 _a0, uint112 _a1) public {
    //     uint minAmount = 10**18;
    //     if (_fundingAmount < minAmount || _a0 < minAmount || _a1 < minAmount) return;

    //     createMarket(_identifier, _fundingAmount);
    //     address marketAddress = MarketRouter(marketRouter).getMarketAddress(address(this), oracle, _identifier);

    //     // buy amount
    //     uint a0 = _a0;
    //     uint a1 = _a1;
    //     uint a = Math.getAmountCToBuyTokens(a0, a1, _fundingAmount, _fundingAmount);
    //     MemeToken(memeToken).transfer(marketAddress, a);
    //     Market(marketAddress).buy(a0, a1, address(this));

    //     // sell tokens
    //     uint sa = Math.getAmountCBySellTokens(a0, a1, _fundingAmount + a - a0, _fundingAmount + a - a1);
    //     (, address token0, address token1) = Market(marketAddress).getAddressOfTokens();
    //     OutcomeToken(token0).transfer(marketAddress, a0);
    //     OutcomeToken(token1).transfer(marketAddress, a1);
    //     uint memeBalanceBefore = MemeToken(memeToken).balanceOf(address(this));
    //     Market(marketAddress).sell(sa, address(this));
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

contract MarketBuffer is MarketTestsShared {
    function setUp() override public {
        commonSetup();
        emit log_named_uint("Balance of contract ", MemeToken(memeToken).balanceOf(address(this)));
        createDefaultMarket();
    }

    function expireMarket() virtual internal {
        (bool success, bytes memory data) = hevm.call(abi.encodeWithSignature("roll(uint256)", block.number+10));
    }

    function expireBufferPeriod() virtual internal {
        // expire market
        (bool success, bytes memory data) = hevm.call(abi.encodeWithSignature("roll(uint256)", block.number+10));
    }

    function test_stakeOutcome() public {
        expireMarket();
    
        assertEq(uint(Market(marketAddress).stage()), uint(1));

        // staking
        uint marketBalanceBefore = MemeToken(memeToken).balanceOf(marketAddress);
        MemeToken(memeToken).transfer(marketAddress, 2*10**18); // 1st stake
        Market(marketAddress).stakeOutcome(0, address(this));
        MemeToken(memeToken).transfer(marketAddress, 4*10**18); // 2nd stake
        Market(marketAddress).stakeOutcome(1, address(this));
        uint marketBalanceAfter = MemeToken(memeToken).balanceOf(marketAddress);
        assertEq(marketBalanceAfter, marketBalanceBefore+6*10**18);
        assertEq(2*10**18, Market(marketAddress).getStake(address(this), 0));
        assertEq(4*10**18, Market(marketAddress).getStake(address(this), 1));

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

    function testFailed_stakeOutcomePostBufferExpiryWithNoPriorStakes() public {
        expireMarket();

        // expire buffer period
        expireBufferPeriod();

        MemeToken(memeToken).transfer(marketAddress, 2*10**18); 
        Market(marketAddress).stakeOutcome(0, address(this)); 
    }

    function testFailed_stakeOutcomePostBufferExpiryWithPriorStakes() public {
        expireMarket();

        MemeToken(memeToken).transfer(marketAddress, 2*10**18); 
        Market(marketAddress).stakeOutcome(0, address(this));
        assertEq(uint(Market(marketAddress).stage()), uint(2));
        MemeToken(memeToken).transfer(marketAddress, 4*10**18);

        // expire buffer period
        expireBufferPeriod();

        MemeToken(memeToken).transfer(marketAddress, 2*10**18); 
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
    }

}

// contract MarketResolvePostEscalationLimit is MarketTestsShared, DSTest {
    
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

//         // carry few trades
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

//         // stake till escalation limit exceeds
//         MemeToken(memeToken).transfer(marketAddress, 2*10**18); 
//         Market(marketAddress).stakeOutcome(0, address(this));
//         assertEq(uint(Market(marketAddress).stage()), uint(2));
//         MemeToken(memeToken).transfer(marketAddress, 4*10**18); 
//         Market(marketAddress).stakeOutcome(1, address(this));
//         MemeToken(memeToken).transfer(marketAddress, 8*10**18); 
//         Market(marketAddress).stakeOutcome(0, address(this));  // escalation limit reached
//     }

//     function test_setOutcome(uint outcome) public {
//         if (outcome > 2) return;
    
//         assertEq(Market(marketAddress).outcome(), 2); // outcome hasn't been set
//         assertEq(uint(Market(marketAddress).stage()), 3); // stage is resolve

//         uint oracleBalanceBefore = MemeToken(memeToken).balanceOf(oracle);
//         OracleMultiSig(oracle).addTxSetMarketOutcome(outcome, marketAddress);
//         uint oracleBalanceAfter = MemeToken(memeToken).balanceOf(oracle);
//         uint losingStakeFee;
//         if (outcome == 0){
//             losingStakeFee = ((4*10**18)*10)/100;
//         }else if (outcome == 1){
//             losingStakeFee = ((10*10**18)*10)/100;
//         }
//         assertEq(oracleBalanceAfter, oracleBalanceBefore+losingStakeFee); // fees earned

//         assertEq(Market(marketAddress).outcome(), outcome);
//         assertEq(uint(Market(marketAddress).stage()), 4); // market closed

//         if (outcome == 0){
//             // redeem stakes
//             redeemStake(0, 0, 10*10**18, ((4*10**18)*90)/100);
//             redeemStake(1, 0, 4*10**18, 0);

//             // redeem winnings
//             redeemWinning(0, 10*10**18, 0);
//             redeemWinning(1, 4*10**18, 0);
//         }else if (outcome == 1){
//             // redeem stakes
//             redeemStake(1, 1, 4*10**18, ((10*10**18)*90)/100);
//             redeemStake(0, 1, 10*10**18, 0);

//             // redeem winnings
//             redeemWinning(1, 4*10**18, 1);
//             redeemWinning(0, 10*10**18, 1);
//         }else if (outcome == 2){
//             // redeem stakes
//             redeemStake(0, 2, 10*10**18, 0);
//             redeemStake(1, 2, 4*10**18, 0);

//             // redeem winnings
//             redeemWinning(0, 10*10**18, 2);
//             redeemWinning(1, 4*10**18, 2);
//         }
//     }

//     function testFail_setInvalidOutcome() public {
//         OracleMultiSig(oracle).addTxSetMarketOutcome(3, marketAddress);
//     }

//     function testFail_setOutcomePostResolutionPeriodExpires() public {
//         (bool success, bytes memory data) = hevm.call(abi.encodeWithSignature("roll(uint256)", block.number+10));
//         OracleMultiSig(oracle).addTxSetMarketOutcome(0, marketAddress);
//         assertEq(Market(marketAddress).outcome(), 0);   
//     }

//     function test_outcomeSetByExpiryToLastStake() public {
//         (bool success, bytes memory data) = hevm.call(abi.encodeWithSignature("roll(uint256)", block.number+10));

//         // redeem stakes
//         uint tokenCBalanceBefore = MemeToken(memeToken).balanceOf(address(this));
//         Market(marketAddress).redeemStake(0); // winning stake
//         uint tokenCBalanceAfter = MemeToken(memeToken).balanceOf(address(this));
//         assertEq(tokenCBalanceAfter, tokenCBalanceBefore + 10*10**18 + ((4*10**18)*90)/100);

//         tokenCBalanceBefore = tokenCBalanceAfter;
//         Market(marketAddress).redeemStake(1); // losing stake
//         tokenCBalanceAfter = MemeToken(memeToken).balanceOf(address(this));
//         assertEq(tokenCBalanceAfter, tokenCBalanceBefore);

//         // redeem winnings outcome 0
//         (, address token0, address token1) = Market(marketAddress).getAddressOfTokens();
//         tokenCBalanceBefore = MemeToken(memeToken).balanceOf(address(this));
//         OutcomeToken(token0).transfer(marketAddress, 10*10**18);
//         Market(marketAddress).redeemWinning(0, address(this));
//         tokenCBalanceAfter = MemeToken(memeToken).balanceOf(address(this));
//         assertEq(tokenCBalanceAfter, tokenCBalanceBefore+10*10**18);

//         // redeem winnings outcome 1
//         tokenCBalanceBefore = MemeToken(memeToken).balanceOf(address(this));
//         OutcomeToken(token1).transfer(marketAddress, 4*10**18);
//         Market(marketAddress).redeemWinning(1, address(this));
//         tokenCBalanceAfter = MemeToken(memeToken).balanceOf(address(this));
//         assertEq(tokenCBalanceAfter, tokenCBalanceBefore);
//     }

// }

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