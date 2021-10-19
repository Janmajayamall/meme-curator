// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import './../libraries/Math.sol';
import './../OracleMultiSig.sol';
import './../MemeToken.sol';
import './../MarketFactory.sol';
import './../MarketRouter.sol';
import './../libraries/Math.sol';
import './../OutcomeToken.sol';
import './../Market.sol';

contract Shared {

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
    bytes32 sharedIdentifier = 0x0401030400040101040403020201030003000000010202020104010201000103;

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
        MarketRouter(marketRouter).createMarket(address(this), oracle, sharedIdentifier, sharedFundingAmount);
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

    function getMarketReserves() internal returns (uint rC, uint r0, uint r1){
        rC = Market(marketAddress).reserveC() + Market(marketAddress).reserveDoN0() + Market(marketAddress).reserveDoN1();
        r0 = Market(marketAddress).reserve0();
        r1 = Market(marketAddress).reserve1();
    }

    function getAmounCToBuyTokens(uint a0, uint a1) internal returns (uint a){
        (uint rc, uint r0, uint r1) = getMarketReserves();
        a = Math.getAmountCToBuyTokens(a0, a1, r0, r1);
    }

    function getTokenAmountToBuyWithAmountC(uint fixedTokenAmount, uint fixedTokenIndex, uint a) internal returns (uint tokenAmount) {
        (uint rc, uint r0, uint r1) = getMarketReserves();
        tokenAmount = Math.getTokenAmountToBuyWithAmountC(fixedTokenAmount, fixedTokenIndex, r0, r1, a);
    }

    function getAmountCBySellTokens(uint a0, uint a1) internal returns (uint a){
        (uint rc, uint r0, uint r1) = getMarketReserves();
        a = Math.getAmountCBySellTokens(a0, a1, r0, r1);
    }

    function getTokenAmountToSellForAmountC(uint fixedTokenAmount, uint fixedTokenIndex, uint a) internal returns (uint tokenAmount) {
        (uint rc, uint r0, uint r1) = getMarketReserves();
        tokenAmount = Math.getTokenAmountToSellForAmountC(fixedTokenAmount, fixedTokenIndex, r0, r1, a);
    }

    function getTokenBalances(address _of) internal returns (uint balanceC, uint balance0, uint balance1) {
        balanceC = MemeToken(memeToken).balanceOf(_of);
        balance0 = OutcomeToken(Market(marketAddress).token0()).balanceOf(_of);
        balance1 = OutcomeToken(Market(marketAddress).token1()).balanceOf(_of);
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

    function advanceBlocksBy(uint by) virtual internal {
        (bool success, bytes memory data) = hevm.call(abi.encodeWithSignature("roll(uint256)", block.number+by));
    } 
}
