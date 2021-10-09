// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './libraries/TransferHelper.sol';
import './Market.sol';
import './libraries/Math.sol';

contract MarketRouter {
    using SafeMath for uint;

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
        address tokenC = Market(market).tokenC();
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
        address tokenC = Market(market).tokenC();
        (uint r0, uint r1) = Market(market).getReservesOTokens();

        uint a0 = amountOutToken0Min;
        uint a1 = amountOutToken1Min;
        uint a = amountInC;
        if (fixedTokenIndex != 0){
            a0 = ((r0*a) + (r1*a) + a**2 - ((r0*a1) + (a*a1)))/(r1 + a1 - a);
        }else{
            a1 = ((r1*a) + (r0*a) + a**2 - ((r1*a0) + (a*a0)))/(r0 + a0 - a);
        }
        require(a0 >= amountOutToken0Min && a1 >= amountOutToken1Min);

        TransferHelper.safeTransferFrom(tokenC, msg.sender, market, amountInC);
        Market(market).buy(a0, a1, msg.sender);
    }

    /// @notice Sell exact amountInToken0 & amountInToken1 for collateral tokens >= amountOutTokenCMin
    function sellExactTokensForMinCTokens(uint amountInToken0, uint amountInToken1, uint amountOutTokenCMin, address creator, address oracle, bytes32 identifier) external {
        address market =  getMarketAddress(creator, oracle, identifier);
        (address token0, address token1) = Market(market).getAddressOTokens();
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
        (address token0, address token1) = Market(market).getAddressOTokens();
        (uint r0, uint r1) = Market(market).getReservesOTokens();

        uint a0 = amountInToken0Max;
        uint a1 = amountInToken1Max;
        uint a = amountOutTokenC;
        if (fixedTokenIndex != 0){
            a0 = ((r1*a) + (a*a1) + (a*r0) - ((r0*a1)+(a**2)))/(r1+a1-a);
        }else {
            a1 = ((r0*a) + (a*a0) + (a*r1) - ((r1*a0)+(a**2)))/(r0+a0-a);
        }
        require(a0 <= amountInToken0Max && a1 <= amountInToken1Max);
        
        TransferHelper.safeTransferFrom(token0, msg.sender, market, a0);
        TransferHelper.safeTransferFrom(token1, msg.sender, market, a1);
        Market(market).sell(amountOutTokenC, msg.sender);
    }

    /// @notice Stake amountIn for outcome _for 
    function stakeForOutcome(uint _for, uint amountIn, address creator, address oracle, bytes32 identifier) external {
        require(_for < 2);
        address market =  getMarketAddress(creator, oracle, identifier);
        address tokenC = Market(market).tokenC();
        uint[2] memory stakes = Market(market).getOutcomeStakes();
        require(stakes[_for]*2 == amountIn);
        TransferHelper.safeTransferFrom(tokenC, msg.sender, market, amountIn);
        Market(market).stakeOutcome(_for, msg.sender);
    }
}

// finish state transistions
// write router funtions for staking
// develop the mmultisig
// staart testing
// fill up the collaboration form