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
    }

    mapping(address => mapping(bytes32 => address)) markets;

    address public oracle;
    address public tokenC;
    DeployParams public deployParams;

    constructor(address _oracle, address _tokenC){
        oracle = _oracle;
        tokenC = _tokenC;
    }

    function createMarket(bytes32 identifier, address creator) external {
        require(markets[creator][identifier] == address(0), 'Market Exists');
        deployParams = DeployParams({factory: address(this), tokenC: tokenC, oracle: oracle, creator: creator, identifier: identifier});
        address marketAddress = address(new Market{salt: keccak256(abi.encode(creator, identifier))}());
        delete deployParams;
        markets[creator][identifier] = marketAddress;
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
    }
}