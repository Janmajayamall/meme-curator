pragma solidity ^0.8.0;

import './Market.sol';
import "@openzeppelin/contracts/access/Ownable.sol";


contract MarketFactory is Ownable {
    struct DeployParams {
        address factory;
        address creator;
        bytes32 identifier;
        address tokenC;
        address oracle;
        uint expireAfterBlocks;
        uint bufferBlocks;
    }

    // creator => identifier => tokenC
    mapping(address => mapping(bytes32 => mapping(address => address))) markets;

    uint public expireAfterBlocks;
    uint public bufferBlocks;
    DeployParams public deployParams;

    constructor(uint _expireAfterBlocks, uint _bufferBlocks){
        require(_expireAfterBlocks > 0 && _bufferBlocks > 0);
        expireAfterBlocks = _expireAfterBlocks;
        bufferBlocks = _bufferBlocks;
    }

    function createMarket(bytes32 _identifier, address _creator, address _oracle, address _tokenC) external {
        require(markets[_creator][_identifier][_tokenC] == address(0), 'Market Exists');
        deployParams = DeployParams({factory: address(this), tokenC: _tokenC, oracle: _oracle, creator: _creator, identifier: _identifier, expireAfterBlocks: expireAfterBlocks, bufferBlocks: bufferBlocks});
        address marketAddress = address(new Market{salt: keccak256(abi.encode(_creator, _identifier, _tokenC))}());
        delete deployParams;
        markets[_creator][_identifier][_tokenC] = marketAddress;
    }

    function setExpireAfterBlock(uint _expireAfterBlocks) external onlyOwner {
        require(_expireAfterBlocks > 0);
        expireAfterBlocks = _expireAfterBlocks;
    }
}