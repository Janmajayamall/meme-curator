// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './libraries/TransferHelper.sol';
import './Market.sol';
import './libraries/Math.sol';
import './MarketFactory.sol';
import 'hardhat/console.sol';


contract MarketRouter {
    using SafeMath for uint;

    address public factory;
    address public deployer;

    bytes32 constant internal MARKET_INIT_CODE_HASH = 0x192b03ee3761d4bcbfd9c811071350c58d37627c2b9f9fce1faa827f2573e24b;

    constructor(address _factory) {
        factory = _factory;
        deployer = MarketFactory(factory).deployer();
    }

    /// @notice Contract address of a prediction market
    function getMarketAddress(address creator, address oracle, bytes32 identifier) public view returns (address marketAddress) {
        marketAddress = address(uint160(uint256((keccak256(abi.encodePacked(
                hex'ff',
                deployer,
                keccak256(abi.encode(creator, oracle, identifier)),
                MARKET_INIT_CODE_HASH
            ))))));
    }

    /// @notice Buy exact amountOfToken0 & amountOfToken1 with collteral tokens <= amountInCMax
    function buyExactTokensForMaxCTokens(uint amountOutToken0, uint amountOutToken1, uint amountInCMax, address creator, address oracle, bytes32 identifier) external {
        address market =  getMarketAddress(creator, oracle, identifier);
        (address tokenC, ,) = Market(market).getAddressOfTokens();
        (uint _reserve0, uint _reserve1) = Market(market).getReservesOTokens();
        uint amountIn = Math.getAmountCToBuyTokens(amountOutToken0, amountOutToken1, _reserve0, _reserve1);
        require(amountInCMax >= amountIn);
        TransferHelper.safeTransferFrom(tokenC, msg.sender, market, amountIn);
        Market(market).buy(amountOutToken0, amountOutToken1, msg.sender);
    }

    /// @notice Buy minimum amountOfToken0 & amountOfToken1 with collteral tokens == amountInC. 
    /// fixedTokenIndex - index to token of which amount does not change in reaction to prices 
    function buyMinTokensForExactCTokens(uint amountOutToken0Min, uint amountOutToken1Min, uint amountInC, uint fixedTokenIndex, address creator, address oracle, bytes32 identifier) external {
        require(fixedTokenIndex < 2);

        address market =  getMarketAddress(creator, oracle, identifier);
        (address tokenC, ,) = Market(market).getAddressOfTokens();
        (uint _reserve0, uint _reserve1) = Market(market).getReservesOTokens();

        uint amountOutToken0 = amountOutToken0Min;
        uint amountOutToken1 = amountOutToken1Min;
        if (fixedTokenIndex == 0){
            amountOutToken1 = Math.getTokenAmountToBuyWithAmountC(amountOutToken0, fixedTokenIndex, _reserve0, _reserve1, amountInC);
        }else {
            amountOutToken0 = Math.getTokenAmountToBuyWithAmountC(amountOutToken1, fixedTokenIndex, _reserve0, _reserve1, amountInC);
        }
        require(amountOutToken0 >= amountOutToken0Min && amountOutToken1 >= amountOutToken1Min);

        TransferHelper.safeTransferFrom(tokenC, msg.sender, market, amountInC);
        Market(market).buy(amountOutToken0, amountOutToken1, msg.sender);
    }

    /// @notice Sell exact amountInToken0 & amountInToken1 for collateral tokens >= amountOutTokenCMin
    function sellExactTokensForMinCTokens(uint amountInToken0, uint amountInToken1, uint amountOutTokenCMin, address creator, address oracle, bytes32 identifier) external {
        address market =  getMarketAddress(creator, oracle, identifier);
        (, address token0, address token1) = Market(market).getAddressOfTokens();
        (uint _reserve0, uint _reserve1) = Market(market).getReservesOTokens();

        uint amountOutTokenC = Math.getAmountCBySellTokens(amountInToken0, amountInToken1, _reserve0, _reserve1);
        require(amountOutTokenC >= amountOutTokenCMin);

        TransferHelper.safeTransfer(token0, market, amountInToken0);
        TransferHelper.safeTransfer(token1, market, amountInToken1);
        Market(market).sell(amountOutTokenC, msg.sender);
    }

    /// @notice Sell maximum of amountInToken0Max & amountInToken1Max for collateral tokens == amountOutTokenC
    /// fixedTokenIndex - index of token of which amount does not change in reaction to prices
    function sellMaxTokensForExactCTokens(uint amountInToken0Max, uint amountInToken1Max, uint amountOutTokenC, uint fixedTokenIndex, address creator, address oracle, bytes32 identifier) external {
        require(fixedTokenIndex < 2);

        address market =  getMarketAddress(creator, oracle, identifier);
        (, address token0, address token1) = Market(market).getAddressOfTokens();
        (uint _reserve0, uint _reserve1) = Market(market).getReservesOTokens();

        uint amountInToken0 = amountInToken0Max;
        uint amountInToken1 = amountInToken1Max;

        if (fixedTokenIndex == 0){
            // amountInToken1 = Math.getTokenAmountToSellForAmountC(amountInToken0, fixedTokenIndex, _reserve0, _reserve1, amountOutTokenC);
        }else {
            // amountInToken0 = Math.getTokenAmountToSellForAmountC(amountInToken1, fixedTokenIndex, _reserve0, _reserve1, amountOutTokenC);
        }
        require(amountInToken0 <= amountInToken0Max && amountInToken1 <= amountInToken1Max);
        
        TransferHelper.safeTransferFrom(token0, msg.sender, market, amountInToken0);
        TransferHelper.safeTransferFrom(token1, msg.sender, market, amountInToken1);
        Market(market).sell(amountOutTokenC, msg.sender);
    }

    /// @notice Stake amountIn for outcome _for 
    function stakeForOutcome(uint _for, uint amountIn, address creator, address oracle, bytes32 identifier) external {
        require(_for < 2);
        address market =  getMarketAddress(creator, oracle, identifier);
        (address tokenC, , ) = Market(market).getAddressOfTokens();
        (uint amount0,  uint amount1, ,) = Market(market).staking();
        require(amount0*2 <= amountIn);
        require(amount1*2 <= amountIn);
        TransferHelper.safeTransferFrom(tokenC, msg.sender, market, amountIn);
        Market(market).stakeOutcome(_for, msg.sender);
    }
}

// finish state transistions
// write router funtions for staking
// develop the mmultisig
// staart testing
// fill up the collaboration form