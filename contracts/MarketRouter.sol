pragma solidity ^0.8.0;

import './libraries/TransferHelper.sol';
import './Market.sol';
import './libraries/Math.sol';

contract MarketRouter {
    address public immutable factory;

    bytes32 private constant MARKET_INIT_CODE_HASH = 0x21291291029121ac21029102100291029102901291092012910921090921099a; 

    constructor(address _factory) {
        factory = _factory;
    }

    /// @notice Contract address of a prediction market
    function getMarketAddress(address creator, address oracle, bytes32 identifier) public view returns (address marketAddress) {
        marketAddress = address(bytes20(keccak256(abi.encodePacked(
                '0xff',
                factory,
                keccak256(abi.encode(creator, oracle, identifier)),
                MARKET_INIT_CODE_HASH
            ))));
    }

    /// @notice Buy exact amountOfToken0 & amountOfToken1 with collteral tokens <= amountInCMax
    function buyExactTokensForMaxCTokens(uint amountOutToken0, uint amountOutToken1, uint amountInCMax, address creator, address oracle, bytes32 identifier) external {
        address market =  getMarketAddress(creator, oracle, identifier);
        address tokenC = Market(market).tokeC();
        (uint _reserve0, uint _reserve1) = Market(market).getReservesOTokens();

        // Calculating the tokenC amount needed for buying exact tokens
        // Note Solved using formula - r0*r1 = (r0 + amount - a1) * (r1 + amount -a2)
        // Since r0, r1, a1, a2 are given -> rP = (x + amount) * (y + amount)
        // Thus, quadratic roots are real & -ve. Plus, one solution val will be +ve & another -ve because amount is always > 0
        int rP = int(_reserve1 * _reserve1);
        int x = int(_reserve0 - amountOutToken0);
        int y = int(_reserve1 - amountOutToken1);
        int b = x + y;
        int c = (x*y)-rP;
        (int val1, int val2) = Math.quadraticEq(1, b, c);
        uint amount;
        if (val1 > 0){
            amount = uint(val1);
        }else{
            amount = uint(val2);
        }
        require(amountInCMax >= amount);

        TransferHelper.safeTransferFrom(tokenC, msg.sender, market, amount);
        Market(market).buy(amountOutToken0, amountOutToken1, msg.sender);
    }

    /// @notice Buy minimum amountOfToken0 & amountOfToken1 with collteral tokens == amountInC. 
    /// preference indicates token to which to allot extra savings
    function buyMinTokensForExactCTokens(uint amountOutToken0Min, uint amountOutToken1Min, uint amountInC, uint preference, address creator, address oracle, bytes32 identifier){
        require(preference < 2);

        address market =  getMarketAddress(creator, oracle, identifier);
        address tokenC = Market(market).tokeC();
        (uint _reserve0, uint _reserve1) = Market(market).getReservesOTokens();

        // Calculating amountOut for preference token while amountOut for other token stays same
        // given amountInC as collateral.
        // rP = (r0 + amountInC - amountOutToken0) * (r1 + amountInC - amountOutToken1), where
        // r0, r1, amountInC, (amountOutToken0 || amountOutToken1) are known
        uint amountOutToken0;
        uint amountOutToken1;
        if (preference == 0){
            amountOutToken0 = (_reserve0 + amountInC) - ((_reserve0 * _reserve1)/((_reserve1 + amountInC)-amountOutToken1Min));
            amountOutToken1 = amountOutToken1Min;
        }else {
            amountOutToken1 = (_reserve1 + amountInC) - ((_reserve0 * _reserve1)/((_reserve0 + amountInC)-amountOutToken0Min));
            amountOutToken0 = amountOutToken0Min;
        }
        require(amountOutToken0 >= amountOutToken0Min && amountOutToken1 >= amountOutToken1Min);

        TransferHelper.safeTransferFrom(tokenC, msg.sender, market, amountInC);
        Market(market).buy(amountOutToken0, amountOutToken1, to);
    }

    /// @notice Sell exact amountInToken0 & amountInToken1 for collateral tokens >= amountOutTokenCMin
    function sellExactTokensForMinCTokens(uint amountInToken0, uint amountInToken1, uint amountOutTokenCMin, address creator, address oracle, bytes32 identifier){
        address market =  getMarketAddress(creator, oracle, identifier);
        (address _token0, address _token1) = Market(market).getAddressOTokens();
        (uint _reserve0, uint _reserve1) = Market(market).getReservesOTokens();

        // Calculating tokenC amount in exchange of selling exact token0 & token1 amount
        // Note Solved using formula - r0*r1 = (r0 + a1 - amount) * (r1 + a2 - amount)
        // Since r0, r1, a1, a2 are given -> rP = (x - amount) * (y - amount)
        // Thus, quadratic roots are real & +ve. Both solution vals are +ve, 
        // but choose the one that is smaller than x & y (the larger solution simply inverts the multiplication values)
        int rP = int(_reserve1 * _reserve1);
        int x = int(_reserve0 + amountOutToken0);
        int y = int(_reserve1 + amountOutToken1);
        int b = (-1 * (x + y));
        int c = (x*y)-rP;
        (int val1, int val2) = Math.quadraticEq(1, b, c);
        uint amountOutTokenC;
        if (val1 <= x && val1 <= y){
            amountOutTokenC = uint(val1);
        }else if (val2 <= x && val2 <= y){
            amountOutTokenC = uint(val2);
        }
        require(amountOutTokenC >= amountOutTokenCMin);

        TransferHelper.safeTransfer(_token0, market, amountInToken0);
        TransferHelper.safeTransfer(_token1, market, amountInToken1);
    }

    /// @notice Sell maximum of amountInToken0Max & amountInToken1Max for collateral tokens == amountOutTokenC
    /// preference indicates which token accounts for slippage, if any.
    function sellMaxTokensForExactTokens(uint amountInToken0Max, uint amountInToken1Max, uint amountOutTokenC, uint preference, address creator, address oracle, bytes32 identifier){
        require(preference < 2);

        address market =  getMarketAddress(creator, oracle, identifier);
        (address _token0, address _token1) = Market(market).getAddressOTokens();
        (uint _reserve0, uint _reserve1) = Market(market).getReservesOTokens();

        // Calculating amountInToken0 or amountInToken1 (depending on preference) to sell for ammountOutTokenC
        // rP = (r0 + a0 - amount) * (r1 + a1 - amount), where
        // r0, amount, rP, (a0 || a1) are known
        uint amountInToken0;
        uint amountInToken1;
        if (preference == 0){
            amountInToken0 = ((_reserve0 * _reserve1)/((_reserve1 + amountInToken1Max)-amountOutTokenC)) - _reserve0 + amountOutTokenC;
            amountInToken1 = ammountInToken1Max;
        }else {
            amountInToken1 = ((_reserve0 * _reserve1)/((_reserve0 + amountInToken0Max)-amountOutTokenC)) - _reserve1 + amountOutTokenC;
            amountInToken0 = ammountInToken0Max;
        }
        require(amountInToken0 >= ammountIn);
        
        TransferHelper.safeTransfer(_token0, market, amountInToken0);
        TransferHelper.safeTransfer(_token1, market, amountInToken1);
    }
}