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

    function getMarketParams() external view returns (bool, address, uint[6] memory);
}
