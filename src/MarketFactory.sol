// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './libraries/TransferHelper.sol';
import './OutcomeToken.sol';
import './interfaces/IMarket.sol';
import './Market.sol';

contract MarketFactory {

      struct DeployParams {
        address creator;
        address oracle;
        bytes32 identifier;
    }

    DeployParams public deployParams;

    function createMarket(address _creator, address _oracle, bytes32 _identifier) external {
        deployParams = DeployParams({creator: _creator, oracle: _oracle, identifier: _identifier});
        new Market{salt: keccak256(abi.encode(_creator, _oracle, _identifier))}();
        delete deployParams;
    }
}