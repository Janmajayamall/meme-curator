pragma solidity ^0.0.8;

interface IModerationCommitte {
    // 1. get fee 
    // 2. get collateral token address
    // 3. get escalation limit
    // 4. resolution time
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

    function getFee() view returns (uint);
    function getTokenC() view returns (address);
    function getDoNEscalationLimit() view returns (uint);
    function getResolutionBuffer() view returns (uint);
    function getDoNBuffer() view returns (uint);
    function getMarketParams() view returns (uint, uint, address, uint, uint, uint, uint);
}
