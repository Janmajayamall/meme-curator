// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Market.sol';
import './interfaces/IMarketFactory.sol';

contract MarketFactory is IMarketFactory {

    struct DeployParams {
        address creator;
        address oracle;
        bytes32 identifier;
    }

    DeployParams public override deployParams;

    event MarketCreated(address indexed market);

    function createMarket(address _creator, address _oracle, bytes32 _identifier) override external {
        deployParams = DeployParams({creator: _creator, oracle: _oracle, identifier: _identifier});
        address marketAddress = address(new Market{salt: keccak256(abi.encode(_creator, _oracle, _identifier))}());
        delete deployParams;
        emit MarketCreated(marketAddress);
    }
}