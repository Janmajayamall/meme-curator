// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Market.sol';
import './interfaces/IModerationCommitee.sol';

contract MarketDeployer{
      struct DeployParams {
        address factory;
        address creator;
        address oracle;
        bytes32 identifier;
        address tokenC;
    }

    DeployParams public deployParams;
    uint[6] public marketConfigs;
    address immutable factory;

    constructor () {
        factory = msg.sender;
    }

    function deploy(address _creator, address _oracle, bytes32 _identifier) public returns(address market){
        (bool _isActive, address _tokenC, uint[6] memory _details) = IModerationCommitte(_oracle).getMarketParams();
        require(_isActive, "ORACLE INACTIVE");
        deployParams = DeployParams({factory: msg.sender, creator: _creator, oracle: _oracle, identifier: _identifier, tokenC: _tokenC});
        marketConfigs = _details;
        market = address(new Market{salt: keccak256(abi.encode(_creator, _oracle, _identifier))}());
        delete deployParams;
        delete marketConfigs;
        require(factory == msg.sender);
    }

    function getMarketConfigs() external returns (uint[6] memory){
        return marketConfigs;
    }
}