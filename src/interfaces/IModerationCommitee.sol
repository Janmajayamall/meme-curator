// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IModerationCommitte {
    struct MarketParams {
        bool isActive;
        address tokenC;
        uint[6] details;
    }

    struct Fee {
        uint numerator;
        uint denominator;
    }

    // function getFee() external view returns (uint, uint);
    // function getTokenC() external returns (address);
    // function getDoNEscalationLimit() external view returns (uint);
    // function getResolutionBuffer() external view returns (uint);
    // function getDoNBuffer() external view returns (uint);
    function getMarketParams() external view returns (bool, address, uint[6] memory);
}
