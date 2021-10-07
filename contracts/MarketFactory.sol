pragma solidity ^0.8.0;

import './Market.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import './interfaces/IModerationCommitee.sol';


contract MarketFactory is Ownable {

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

    constructor(uint _expireAfterBlocks, uint _bufferBlocks){
        require(_expireAfterBlocks > 0 && _bufferBlocks > 0);
        expireAfterBlocks = _expireAfterBlocks;
        bufferBlocks = _bufferBlocks;
    }

    function createMarket(address _creator, address _oracle, bytes32 _identifier) external {
        require(markets[_creator][_oracle][_identifier] == address(0), 'Market Exists');

        uint _oracleFeeNumerator; _oracleFeeDenominator; _expireAfterBlocks; _resolutionBufferBlocks; _donBufferBlocks; _donEscalationLimit;
        address _tokenC;
        (_oracleFeeNumerator, _oracleFeeDenominator, _tokenC, _expireAfterBlocks, _resolutionBufferBlocks, _donBufferBlocks, _donEscalationLimit) = IModerationCommitte(_oracle).getMarketParams();
        deployParams = DeployParams({factory: address(this), creator: _creator, oracle: _oracle, identifier: _identifier, oracleFeeNumerator: _oracleFeeNumerator, oracleFeeDenominator: _oracleFeeDenominator, token: _tokenC, expireAfterBlocks: _expireAfterBlocks, donBufferBlocks: _donBufferBlocks, donEscalationLimit: _donEscalationLimit, resolutionBufferBlocks: _resolutionBufferBlocks});
        address marketAddress = address(new Market{salt: keccak256(abi.encode())}());
        delete deployParams;
        markets[_creator][_oracle][_identifier] = marketAddress;
    }
}