// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Market.sol';
import './interfaces/IModerationCommitee.sol';


contract MarketFactory {

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

    // creator => oracle => identifier
    mapping(address => mapping(address => mapping(bytes32 => address))) markets;
    DeployParams public deployParams;

    function createMarket(address _creator, address _oracle, bytes32 _identifier) external {
        require(markets[_creator][_oracle][_identifier] == address(0), 'Market Exists');
        bool _isActive;
        uint _oracleFeeNumerator; 
        uint _oracleFeeDenominator; 
        uint _expireAfterBlocks; 
        uint _resolutionBufferBlocks; 
        uint _donBufferBlocks; 
        uint _donEscalationLimit;
        address _tokenC;
        (_isActive, _oracleFeeNumerator, _oracleFeeDenominator, _tokenC, _expireAfterBlocks, _resolutionBufferBlocks, _donBufferBlocks, _donEscalationLimit) = IModerationCommitte(_oracle).getMarketParams();
        require(_isActive);
        deployParams = DeployParams({factory: address(this), creator: _creator, oracle: _oracle, identifier: _identifier, oracleFeeNumerator: _oracleFeeNumerator, oracleFeeDenominator: _oracleFeeDenominator, tokenC: _tokenC, expireAfterBlocks: _expireAfterBlocks, donBufferBlocks: _donBufferBlocks, donEscalationLimit: _donEscalationLimit, resolutionBufferBlocks: _resolutionBufferBlocks});
        address marketAddress = address(new Market{salt: keccak256(abi.encode(_creator, _oracle, _identifier))}());
        delete deployParams;
        markets[_creator][_oracle][_identifier] = marketAddress;
    }
}