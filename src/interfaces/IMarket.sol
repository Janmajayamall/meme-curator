// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMarket {

    struct Staking {
        uint256 lastAmountStaked;
        address staker0;
        address staker1;
        uint8 lastOutcomeStaked;
    }

   enum Stages {
        MarketCreated,
        MarketFunded,
        MarketBuffer,
        MarketResolve,
        MarketClosed
    }

    struct MarketDetails {
        uint32 expireAtBlock;
        uint32 donBufferEndsAtBlock;
        uint32 resolutionEndsAtBlock;
        uint32 expireBufferBlocks;
        uint32 donBufferBlocks; 
        uint32 resolutionBufferBlocks;

        uint16 donEscalationCount;
        uint16 donEscalationLimit;

        uint8 oracleFeeNumerator;
        uint8 oracleFeeDenominator;
        uint8 outcome;
        uint8 stage;
    }

    function getMarketInfo() external view returns(string memory, address, address);
    function getTokenAddresses() external view returns (address,address,address);
    function getOutcomeReserves() external view returns (uint,uint);
    function getTokenCReserves() external view returns (uint,uint,uint);
    function getMarketDetails() external view returns (uint[12] memory);
    function getStaking() external view returns(uint,address,address,uint8);
    function getStake(uint _for, address _of) external view returns(uint);


    function fund() external;
    function buy(uint amount0, uint amount1, address to) external;   
    function sell(uint amount, address to) external;
    function redeemWinning(uint _for, address to) external;
    function stakeOutcome(uint _for, address to) external;
    function redeemStake(uint _for) external;
    function setOutcome(uint8 _outcome) external;
    function claimReserve() external;

    event OutcomeTraded(address indexed market, address indexed by);
    event OutcomeStaked(address indexed market, address indexed by);
    event OutcomeSet(address indexed market);
    event WinningRedeemed(address indexed market, address indexed by);
    event StakedRedeemed(address indexed market, address indexed by);
}
