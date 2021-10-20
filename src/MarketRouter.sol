// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './libraries/TransferHelper.sol';
import './interfaces/IMarket.sol';
import './libraries/Math.sol';
import './interfaces/IMarketFactory.sol';


contract MarketRouter {
    address public factory;

    bytes32 constant internal MARKET_INIT_CODE_HASH = 0x454cbbfae5bc62bb41d20167c90688f6db3104c7d82ae13e0e5978c1ad981a7d;

    constructor(address _factory) {
        factory = _factory;
    }

    /// @notice Contract address of a prediction market
    function getMarketAddress(address creator, address oracle, bytes32 identifier) public view returns (address marketAddress) {
        marketAddress = address(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encode(creator, oracle, identifier)),
                MARKET_INIT_CODE_HASH
            )))));
    }

    /// @notice Creates a new market
    function createMarket(address _creator, address _oracle, bytes32 _identifier, uint amount) external {
        address expectedAddress = getMarketAddress(_creator, _oracle, _identifier);
        uint size;
        assembly {
            size := extcodesize(expectedAddress)
        }
        require(size == 0, "Market exists");
        IMarketFactory(factory).createMarket(_creator, _oracle, _identifier);

        address tokenC = IMarket(expectedAddress).tokenC();

        // // fund
        TransferHelper.safeTransferFrom(tokenC, msg.sender, expectedAddress, amount);
        IMarket(expectedAddress).fund();
    }

    /// @notice Buy exact amountOfToken0 & amountOfToken1 with collteral tokens <= amountInCMax
    function buyExactTokensForMaxCTokens(uint amountOutToken0, uint amountOutToken1, uint amountInCMax, address creator, address oracle, bytes32 identifier) external {
        address market =  getMarketAddress(creator, oracle, identifier);
        address tokenC = IMarket(market).tokenC();
        uint _reserve0 = IMarket(market).reserve0();
        uint _reserve1 = IMarket(market).reserve1();
        uint amountIn = Math.getAmountCToBuyTokens(amountOutToken0, amountOutToken1, _reserve0, _reserve1);
        require(amountInCMax >= amountIn, "TRADE: INVALID");
        TransferHelper.safeTransferFrom(tokenC, msg.sender, market, amountIn);
        IMarket(market).buy(amountOutToken0, amountOutToken1, msg.sender);
    }

    /// @notice Buy minimum amountOfToken0 & amountOfToken1 with collteral tokens == amountInC. 
    /// fixedTokenIndex - index to token of which amount does not change in reaction to prices 
    function buyMinTokensForExactCTokens(uint amountOutToken0Min, uint amountOutToken1Min, uint amountInC, uint fixedTokenIndex, address creator, address oracle, bytes32 identifier) external {
        require(fixedTokenIndex < 2);

        address market =  getMarketAddress(creator, oracle, identifier);
        address tokenC = IMarket(market).tokenC();
        uint _reserve0 = IMarket(market).reserve0();
        uint _reserve1 = IMarket(market).reserve1();

        uint amountOutToken0 = amountOutToken0Min;
        uint amountOutToken1 = amountOutToken1Min;
        if (fixedTokenIndex == 0){
            amountOutToken1 = Math.getTokenAmountToBuyWithAmountC(amountOutToken0, fixedTokenIndex, _reserve0, _reserve1, amountInC);
        }else {
            amountOutToken0 = Math.getTokenAmountToBuyWithAmountC(amountOutToken1, fixedTokenIndex, _reserve0, _reserve1, amountInC);
        }
        require(amountOutToken0 >= amountOutToken0Min && amountOutToken1 >= amountOutToken1Min);

        TransferHelper.safeTransferFrom(tokenC, msg.sender, market, amountInC);
        IMarket(market).buy(amountOutToken0, amountOutToken1, msg.sender);
    }

    /// @notice Sell exact amountInToken0 & amountInToken1 for collateral tokens >= amountOutTokenCMin
    function sellExactTokensForMinCTokens(uint amountInToken0, uint amountInToken1, uint amountOutTokenCMin, address creator, address oracle, bytes32 identifier) external {
        address market =  getMarketAddress(creator, oracle, identifier);
        address token0 = IMarket(market).token0();
        address token1 = IMarket(market).token1();
        uint _reserve0 = IMarket(market).reserve0();
        uint _reserve1 = IMarket(market).reserve1();

        uint amountOutTokenC = Math.getAmountCBySellTokens(amountInToken0, amountInToken1, _reserve0, _reserve1);
        require(amountOutTokenC >= amountOutTokenCMin, "TRADE: INVALID");

        TransferHelper.safeTransferFrom(token0, msg.sender, market, amountInToken0);
        TransferHelper.safeTransferFrom(token1, msg.sender, market, amountInToken1);
        IMarket(market).sell(amountOutTokenC, msg.sender);
    }

    /// @notice Sell maximum of amountInToken0Max & amountInToken1Max for collateral tokens == amountOutTokenC
    /// fixedTokenIndex - index of token of which amount does not change in reaction to prices
    function sellMaxTokensForExactCTokens(uint amountInToken0Max, uint amountInToken1Max, uint amountOutTokenC, uint fixedTokenIndex, address creator, address oracle, bytes32 identifier) external {
        require(fixedTokenIndex < 2);

        address market =  getMarketAddress(creator, oracle, identifier);
        uint _reserve0 = IMarket(market).reserve0();
        uint _reserve1 = IMarket(market).reserve1();

        uint amountInToken0 = amountInToken0Max;
        uint amountInToken1 = amountInToken1Max;

        if (fixedTokenIndex == 0){
            amountInToken1 = Math.getTokenAmountToSellForAmountC(amountInToken0, fixedTokenIndex, _reserve0, _reserve1, amountOutTokenC);
        }else {
            amountInToken0 = Math.getTokenAmountToSellForAmountC(amountInToken1, fixedTokenIndex, _reserve0, _reserve1, amountOutTokenC);
        }
        require(amountInToken0 <= amountInToken0Max && amountInToken1 <= amountInToken1Max, "TRADE: INVALID");

        address token0 = IMarket(market).token0();
        address token1 = IMarket(market).token1();
        
        TransferHelper.safeTransferFrom(token0, msg.sender, market, amountInToken0);
        TransferHelper.safeTransferFrom(token1, msg.sender, market, amountInToken1);
        IMarket(market).sell(amountOutTokenC, msg.sender);
    }

    /// @notice Stake amountIn for outcome _for 
    function stakeForOutcome(uint _for, uint amountIn, address creator, address oracle, bytes32 identifier) external {
        require(_for < 2);
        address market = getMarketAddress(creator, oracle, identifier);
        address tokenC = IMarket(market).tokenC();
        (uint amount0,  uint amount1, ,) = IMarket(market).staking();
        require(amount0*2 <= amountIn, "ERR: DOUBLE");
        require(amount1*2 <= amountIn, "ERR: DOUBLE");
        TransferHelper.safeTransferFrom(tokenC, msg.sender, market, amountIn);
        IMarket(market).stakeOutcome(_for, msg.sender);
    }

    /// @notice Redeem winning for outcome
    function redeemWinning(uint _for, uint amountInToken, address creator, address oracle, bytes32 identifier) external {
        address market = getMarketAddress(creator, oracle, identifier);
        address tokenAdd;
        if (_for == 0) tokenAdd = IMarket(market).token0();
        if (_for == 1) tokenAdd = IMarket(market).token1();
        TransferHelper.safeTransferFrom(tokenAdd, msg.sender, market, amountInToken);
        IMarket(market).redeemWinning(_for, msg.sender);
    }
}
