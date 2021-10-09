// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Market.sol';

contract MarketDeployer{
      struct DeployParams {
        address factory;
        address creator;
        address oracle;
        bytes32 identifier;
        uint oracleFeeNumerator;
        uint oracleFeeDenominator;
        address tokenC;
        uint expireAfterBlocks;
        uint donBufferBlocks;   
        uint donEscalationLimit;
        uint resolutionBufferBlocks;
    }
    
    DeployParams public deployParams;
    address public immutable factory;

    constructor () {
        factory = msg.sender;
    }

    function deploy(address _creator, address _oracle, bytes32 _identifier, uint _oracleFeeNumerator,uint _oracleFeeDenominator, address _tokenC, uint _expireAfterBlocks, uint _resolutionBufferBlocks, uint _donBufferBlocks, uint _donEscalationLimit) public returns(address market){
        deployParams = DeployParams({factory: msg.sender, creator: _creator, oracle: _oracle, identifier: _identifier, oracleFeeNumerator: _oracleFeeNumerator, oracleFeeDenominator: _oracleFeeDenominator, tokenC: _tokenC, expireAfterBlocks: _expireAfterBlocks, donBufferBlocks: _donBufferBlocks, donEscalationLimit: _donEscalationLimit, resolutionBufferBlocks: _resolutionBufferBlocks});
        market = address(new Market{salt: keccak256(abi.encode(_creator, _oracle, _identifier))}());
        delete deployParams;
        require(factory == msg.sender);
    }
}