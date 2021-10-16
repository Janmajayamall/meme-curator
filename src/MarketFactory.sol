// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './libraries/TransferHelper.sol';
import './MarketDeployer.sol';
import './OutcomeToken.sol';
import './interfaces/IMarket.sol';

contract MarketFactory {
    // creator => oracle => identifier
    mapping(address => mapping(address => mapping(bytes32 => address))) public markets;
    address public deployer;

    constructor(){
        deployer = address(new MarketDeployer());
    }

    function createMarket(address _creator, address _oracle, bytes32 _identifier, uint _fundingAmount) external {
        require(markets[_creator][_oracle][_identifier] == address(0), 'Market Exists');

        // deploy
        (address marketAddress, address tokenC) = MarketDeployer(deployer).deploy(_creator, _oracle, _identifier);

        // set market tokens
        address token0 = address(new OutcomeToken(marketAddress));
        address token1 = address(new OutcomeToken(marketAddress));
        IMarket(marketAddress).setOutcomeTokens(token0, token1);
        // fund the market
        TransferHelper.safeTransferFrom(tokenC, msg.sender, marketAddress, _fundingAmount);
        Market(marketAddress).fund();
        
        markets[_creator][_oracle][_identifier] = marketAddress;
    }
}