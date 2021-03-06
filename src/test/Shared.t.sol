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
        address tokenC;
        bool isActive;
        uint8 feeNumerator;
        uint8 feeDenominator;
        uint16 donEscalationLimit;
        uint32 expireBufferBlocks;
        uint32 donBufferBlocks;
        uint32 resolutionBufferBlocks;
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
    string sharedIdentifier = "http://www.google.com/";

    address hevm = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

    function commonSetup() internal {
        marketFactory = address(new MarketFactory());
        marketRouter = address(new MarketRouter(marketFactory));

        memeToken = address(new MemeToken());
        MemeToken(memeToken).mint(address(this), type(uint).max);

        address[] memory oracleOwners = new address[](1);
        oracleOwners[0] = address(this);
        oracle = address(new OracleMultiSig(oracleOwners, 1, 10, address(this)));
        sharedOracleConfig = OracleConfig(
            memeToken,
            true, 
            10, 
            100, 
            5, 
            10, 
            10, 
            10);
        OracleMultiSig(oracle).addTxSetupOracle(
            sharedOracleConfig.tokenC,
            sharedOracleConfig.isActive,
            sharedOracleConfig.feeNumerator,
            sharedOracleConfig.feeDenominator,
            sharedOracleConfig.donEscalationLimit,
            sharedOracleConfig.expireBufferBlocks,
            sharedOracleConfig.donBufferBlocks,
            sharedOracleConfig.resolutionBufferBlocks
        );   
    }

    function createDefaultMarket() internal {
        string memory _identifier = "dawdadxcftvygbhunj";
        MarketFactory(marketFactory).createMarket(address(this), oracle, _identifier);
        marketAddress = getExpectedMarketAddress(_identifier);
        MemeToken(memeToken).transfer(marketAddress, sharedFundingAmount);
        Market(marketAddress).fund();
    }

    function createMarket(string memory _identifier, uint _fundingAmount) internal {
        MarketFactory(marketFactory).createMarket(address(this), oracle, _identifier);
        marketAddress = getExpectedMarketAddress(_identifier);
        MemeToken(memeToken).transfer(marketAddress, _fundingAmount);
        Market(marketAddress).fund();
    }

    function getMarketContractInitBytecodeHash() internal returns (bytes32 initHash){
        bytes memory initCode = type(Market).creationCode;
        initHash = keccak256(initCode);
    }

    function getExpectedMarketAddress(string memory identifier) internal returns (address market) {
        market = address(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                marketFactory,
                keccak256(abi.encode(address(this), oracle, identifier)),
                getMarketContractInitBytecodeHash()
        )))));
    }

    function getMarketReserves() internal returns (uint rC, uint r0, uint r1){
        (uint reserveC, uint reserveDoN0, uint reserveDoN1) = Market(marketAddress).getTokenCReserves();
        rC = reserveC + reserveDoN0 + reserveDoN1;
        (r0, r1) = Market(marketAddress).getOutcomeReserves();
    }

    function getAmounCToBuyTokens(uint a0, uint a1) internal returns (uint a){
        (,uint r0, uint r1) = getMarketReserves();
        a = Math.getAmountCToBuyTokens(a0, a1, r0, r1);
    }

    function getTokenAmountToBuyWithAmountC(uint fixedTokenAmount, uint fixedTokenIndex, uint a) internal returns (uint tokenAmount) {
        (,uint r0, uint r1) = getMarketReserves();
        tokenAmount = Math.getTokenAmountToBuyWithAmountC(fixedTokenAmount, fixedTokenIndex, r0, r1, a);
    }

    function getAmountCBySellTokens(uint a0, uint a1) internal returns (uint a){
        (,uint r0, uint r1) = getMarketReserves();
        a = Math.getAmountCBySellTokens(a0, a1, r0, r1);
    }

    function getTokenAmountToSellForAmountC(uint fixedTokenAmount, uint fixedTokenIndex, uint a) internal returns (uint tokenAmount) {
        (,uint r0, uint r1) = getMarketReserves();
        tokenAmount = Math.getTokenAmountToSellForAmountC(fixedTokenAmount, fixedTokenIndex, r0, r1, a);
    }

    function getMarketStage(address _marketAddress) internal view returns (uint8 stage) {
        uint[12] memory details = Market(_marketAddress).getMarketDetails();
        return uint8(details[11]);
    }

    function getMarketOutcome(address _marketAddress) internal view returns (uint8 outcome) {
        uint[12] memory details = Market(_marketAddress).getMarketDetails();
        return uint8(details[10]);
    }

    function getStakeAmount(address _marketAddress, uint _for, address _of) internal returns (uint){
        return Market(marketAddress).getStake(_for, _of);
    }

    function getTokenBalances(address _of) internal returns (uint balanceC, uint balance0, uint balance1) {
        (,address token0, address token1) = Market(marketAddress).getTokenAddresses();
        balanceC = MemeToken(memeToken).balanceOf(_of);
        balance0 = OutcomeToken(token0).balanceOf(_of);
        balance1 = OutcomeToken(token1).balanceOf(_of);
    }

    function expireMarket() virtual internal {
        hevm.call(abi.encodeWithSignature("roll(uint256)", block.number+sharedOracleConfig.expireBufferBlocks));
        // require(success);
    }

    function expireBufferPeriod() virtual internal {
        // expire market
        hevm.call(abi.encodeWithSignature("roll(uint256)", block.number+sharedOracleConfig.donBufferBlocks));
        // require(success);
    }

    function expireResolutionPeriod() virtual internal {
        // expire resolution period
        hevm.call(abi.encodeWithSignature("roll(uint256)", block.number+sharedOracleConfig.resolutionBufferBlocks));
    }

    function advanceBlocksBy(uint by) virtual internal {
        hevm.call(abi.encodeWithSignature("roll(uint256)", block.number+by));
    } 
}
