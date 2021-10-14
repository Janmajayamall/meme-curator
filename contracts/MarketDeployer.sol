// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Market.sol';
import './interfaces/IModerationCommitee.sol';
import './OutcomeToken.sol';


contract MarketDeployer{
    struct DeployParams {
        address factory;
        address creator;
        address oracle;
        bytes32 identifier;
        address tokenC;
        bool isOracleActive;
    }

    DeployParams public deployParams;
    uint[6] public marketConfigs;
    address immutable factory;

    constructor () {
        factory = msg.sender;
    }

    function deploy(address _creator, address _oracle, bytes32 _identifier) external returns(address market, address tokenC){
        require(factory == msg.sender);
        (bool _isActive, address _tokenC, uint[6] memory _details) = IModerationCommitte(_oracle).getMarketParams();
        deployParams = DeployParams({factory: msg.sender, creator: _creator, oracle: _oracle, identifier: _identifier, tokenC: _tokenC, isOracleActive: _isActive});
        marketConfigs = _details;
        market = address(new Market{salt: keccak256(abi.encode(_creator, _oracle, _identifier))}());
        tokenC = _tokenC;
        delete deployParams;
        delete marketConfigs;
    }

    function getMarketConfigs() external view returns (uint[6] memory){
        return marketConfigs;
    }
}