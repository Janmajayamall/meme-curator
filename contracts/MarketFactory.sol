// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './libraries/TransferHelper.sol';
import './MarketDeployer.sol';

contract MarketFactory {
    // creator => oracle => identifier
    mapping(address => mapping(address => mapping(bytes32 => address))) public markets;
    address public deployer;

    // // events
    // event MarketCreated(address indexed market, address indexed creator, address indexed oracle, bytes32 indexed identifier);
    // event MarketDetails(address indexed market);

    constructor(){
        deployer = address(new MarketDeployer());
    }

    function createMarket(address _creator, address _oracle, bytes32 _identifier, uint _fundingAmount) external {
        require(markets[_creator][_oracle][_identifier] == address(0), 'Market Exists');

        // deploy
        address marketAddress = MarketDeployer(deployer).deploy(_creator, _oracle, _identifier);

        // fund market
        // TransferHelper.safeTransferFrom(_tokenC, msg.sender, marketAddress, _fundingAmount);
        // Market(marketAddress).fund();
        
        markets[_creator][_oracle][_identifier] = marketAddress;
    }
}