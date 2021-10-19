// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMarketFactory {
    function createMarket(address _creator, address _oracle, bytes32 _identifier) external;
    function deployParams() external returns (address,address,bytes32);
}