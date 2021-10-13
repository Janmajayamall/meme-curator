import './../Market.sol';

contract ContractHelper {
    function getMarketContractInitBytecodeHash() external pure returns (bytes32 initHash){
        bytes memory initCode = type(Market).creationCode;
        initHash = keccak256(initCode);
    }

    function getAddress() external pure returns (address gg){
        bytes32 POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;
        address factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        address token1 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address token0 = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
        gg = address(bytes20(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }
}