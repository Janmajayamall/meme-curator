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

    address public marketAddress;

    constructor(){
        deployer = address(new MarketDeployer());
    }

    function createMarket(address _creator, address _oracle, bytes32 _identifier, uint _fundingAmount) external {
        require(markets[_creator][_oracle][_identifier] == address(0), 'Market Exists');

        // deploy
        (address _marketAddress, address tokenC) = MarketDeployer(deployer).deploy(_creator, _oracle, _identifier);

        // set market tokens
        marketAddress = _marketAddress;
        address token0 = address(new OutcomeToken());
        address token1 = address(new OutcomeToken());
        delete marketAddress;
        IMarket(_marketAddress).setOutcomeTokens(token0, token1);
        // fund the market
        TransferHelper.safeTransferFrom(tokenC, msg.sender, _marketAddress, _fundingAmount);
        Market(_marketAddress).fund();
        
        markets[_creator][_oracle][_identifier] = _marketAddress;
    }
}