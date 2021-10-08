pragma solidity ^0.8.0;

interface IModerationCommitte {
    struct MarketParams {
        uint feeNumerator;
        uint feeDenominator;
        address tokenC;
        uint expireAfterBlocks;
        uint resolutionBufferBlocks;
        uint donBufferBlocks;
        uint donEscalationLimit;
    }

    struct Fee {
        uint numerator;
        uint denominator;
    }

    function getFee() external view returns (uint);
    function getTokenC() external returns (address);
    function getDoNEscalationLimit() external view returns (uint);
    function getResolutionBuffer() external view returns (uint);
    function getDoNBuffer() external view returns (uint);
    function getMarketParams() external view returns (uint, uint, address, uint, uint, uint, uint);
}
