// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Market.sol';
import './interfaces/IModerationCommitee.sol';
import './libraries/TransferHelper.sol';
import './MarketDeployer.sol';

contract MarketFactory {
    // creator => oracle => identifier
    mapping(address => mapping(address => mapping(bytes32 => address))) markets;
    address public immutable deployer;

    constructor(){
        deployer = address(new MarketDeployer());
    }

    function createMarket(address _creator, address _oracle, bytes32 _identifier, uint _fundingAmount) external {
        require(markets[_creator][_oracle][_identifier] == address(0), 'Market Exists');

        // deploy
        (bool _isActive,uint _oracleFeeNumerator,uint _oracleFeeDenominator, address _tokenC, uint _expireAfterBlocks, uint _resolutionBufferBlocks, uint _donBufferBlocks, uint _donEscalationLimit) = IModerationCommitte(_oracle).getMarketParams();
        require(_isActive);
        address marketAddress = MarketDeployer(deployer).deploy(_creator, _oracle, _identifier, _oracleFeeNumerator, _oracleFeeDenominator, _tokenC, _expireAfterBlocks, _resolutionBufferBlocks, _donBufferBlocks, _donEscalationLimit);

        // fund market
        TransferHelper.safeTransfer(_tokenC, marketAddress, _fundingAmount);
        Market(marketAddress).fund();
        
        markets[_creator][_oracle][_identifier] = marketAddress;
    }
}