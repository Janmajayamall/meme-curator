pragma solidity ^0.8.0;

contract MarketRouter {
    address public immutable factory;

    bytes32 private constant MARKET_INIT_CODE_HASH = 0x21291291029121ac21029102100291029102901291092012910921090921099a; 

    constructor(address _factory) {
        factory = _factory;
    }

    function getMarketAddress(bytes32 identifier, address creator) public view returns (address marketAddress) {
        marketAddress = address(bytes20(keccak256(abi.encodePacked(
                '0xff',
                factory,
                keccak256(abi.encode(identifier, creator)),
                MARKET_INIT_CODE_HASH
            ))));
    }


    // buy tokens with maxInput or minOutput
    // sell tokens with maxOutput or minInput
    // redeem winnings
    // submit signed txs
    // generate market address

    // creates new prediction market with signed txs & places a bet on behalf of the creator ()
    // 

}