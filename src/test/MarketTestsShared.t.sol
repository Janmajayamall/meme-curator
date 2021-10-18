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
import './../Market.sol';

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
        MemeToken(memeToken).approve(marketRouter, sharedFundingAmount);
        bytes32 _identifier = 0x0401030400040101040403020201030003000000010202020104010201000103;
        MarketRouter(marketRouter).createMarket(address(this), oracle, _identifier, sharedFundingAmount);
        marketAddress = getExpectedMarketAddress(_identifier);
    }

    function createMarket(bytes32 _identifier, uint _fundingAmount) internal {
        MemeToken(memeToken).approve(marketRouter, _fundingAmount);
        MarketRouter(marketRouter).createMarket(address(this), oracle, _identifier, _fundingAmount);
        marketAddress = getExpectedMarketAddress(_identifier);
    }

    function getMarketContractInitBytecodeHash() internal returns (bytes32 initHash){
        bytes memory initCode = type(Market).creationCode;
        initHash = keccak256(initCode);
    }

    function getExpectedMarketAddress(bytes32 identifier) internal returns (address market) {
        market = address(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                marketFactory,
                keccak256(abi.encode(address(this), oracle, identifier)),
                getMarketContractInitBytecodeHash()
        )))));
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
        emit log_named_address("marketAddress", marketAddress);
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

    function oneOffBuy(uint amount0, uint amount1) internal {
        (uint r0, uint r1) = Market(marketAddress).getReservesOTokens();
        uint amount = Math.getAmountCToBuyTokens(amount0, amount1, r0, r1);
        MemeToken(memeToken).transfer(marketAddress, amount);
        Market(marketAddress).buy(amount0, amount1, address(this));
    }

    function oneOffSell(uint amount0, uint amount1) internal{
        (uint r0, uint r1) = Market(marketAddress).getReservesOTokens();
        uint amount = Math.getAmountCBySellTokens(amount0, amount1, r0, r1);
        (, address token0, address token1) = Market(marketAddress).getAddressOfTokens();
        OutcomeToken(token0).transfer(marketAddress, amount0);
        OutcomeToken(token1).transfer(marketAddress, amount1);
        Market(marketAddress).sell(amount, address(this));
    }

    function keepReservesAndBalsInCheck() internal {
        (uint reserve0, uint reserve1) = Market(marketAddress).getReservesOTokens();
        uint reserveC = Market(marketAddress).getReservesTokenC();

        (address tokenC, address token0, address token1) = Market(marketAddress).getAddressOfTokens();
        assertEq(reserveC, MemeToken(tokenC).balanceOf(marketAddress));
        assertEq(reserve0, OutcomeToken(token0).balanceOf(marketAddress));
        assertEq(reserve1, OutcomeToken(token1).balanceOf(marketAddress));
    } 

    function expireMarket() virtual internal {
        (bool success, bytes memory data) = hevm.call(abi.encodeWithSignature("roll(uint256)", block.number+sharedOracleConfig.expireAfterBlocks));
        // require(success);
    }

    function expireBufferPeriod() virtual internal {
        // expire market
        (bool success, bytes memory data) = hevm.call(abi.encodeWithSignature("roll(uint256)", block.number+sharedOracleConfig.donBufferBlocks));
        // require(success);
    }

    function expireResolutionPeriod() virtual internal {
        // expire resolution period
        (bool success, bytes memory data) = hevm.call(abi.encodeWithSignature("roll(uint256)", block.number+sharedOracleConfig.resolutionBufferBlocks));
    }

    function setUp() virtual public {
        commonSetup();
    }

    function test_dawda() public {
        // bytes memory initCode = type(Market).creationCode;
        // initHash = keccak256(initCode);
        emit log_named_bytes32("INIT HASHCODE", getMarketContractInitBytecodeHash());
        // require(false);
        MemeToken(memeToken).approve(marketRouter, 10*10**18);
        MarketRouter(marketRouter).createMarket(address(this), oracle, 0x0401030400040101040403020201030003000000010202020104010201000103, 10*10**18);
        // MarketRouter(marketRouter).createMarket(address(this), oracle, 0x0401030400040101040403020201030003000000010202020104010201000103);
        // // require(false);
    }
}
