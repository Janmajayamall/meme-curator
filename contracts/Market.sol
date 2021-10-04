pragma solidity ^0.8.0;

import './OutcomeToken.sol';
import './libraries/SafeMath.sol';
import './MarketFactory.sol';

contract Market {
    using SafeMath for uint;

    enum Stages {
        MarketCreated,
        MarketFunded,
        MarketClosed
    }

    uint256 reserve0;
    uint256 reserve1;
    uint256 reserveC;

    address public immutable token0;
    address public immutable token1;
    address public immutable tokenC;

    address public immutable factory;
    address public immutable oracle;

    bytes32 public immutable identifier;
    address public creator;

    uint public outcome = 2;

    Stages public stage;

    constructor(){
        (factory, creator, identifier, tokenC, oracle) = MarketFactory(msg.sender).deployParams();
        token0 = address(new OutcomeToken());
        token1 = address(new OutcomeToken());
    }

    function getReserves() external view returns (uint _reserve0, uint _reserve1){
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    function tokensAddresses() external view returns (address _token0, address _token1){
        _token0 = token0;
        _token1 = token1;
    }

    function fund() external {
        require(stage == Stages.MarketCreated);

        uint balance = IERC20(tokenC).balanceOf(address(this));
        uint amount = balance.sub(reserveC);
        require(amount > 0, 'Funding amount zero');
        OutcomeToken(token0).issue(address(this), amount);
        OutcomeToken(token1).issue(address(this), amount);   
        reserve0 = reserve0.add(amount);
        reserve1 = reserve1.add(amount);
        reserveC = reserveC.add(amount);

        stage = Stages.MarketFunded;
    }
    
    function buy(uint amount0, uint amount1) external {
        require(stage == Stages.MarketFunded);

        uint balance = IERC20(tokenC).balanceOf(address(this));
        uint amount = balance.sub(reserveC);

        // buying all tokens
        OutcomeToken(token0).issue(address(this), amount);
        OutcomeToken(token1).issue(address(this), amount);

        // transfer
        if (amount0 > 0) OutcomeToken(token0).transfer(msg.sender, amount0);
        if (amount1 > 0) OutcomeToken(token1).transfer(msg.sender, amount1);

        uint rP = reserve0.mul(reserve1);
        uint _reserve0 = reserve0.add(amount).sub(amount0);
        uint _reserve1 = reserve1.add(amount).sub(amount1);
        require(rP == _reserve0.mul(_reserve1));

        reserve0 = _reserve0;
        reserve1 = _reserve1;
        reserveC = reserveC.add(amount);
    }   

    function sell(uint amount) external {
        require(stage == Stages.MarketFunded);

        IERC20(tokenC).transfer(msg.sender, amount);

        uint balance0 = OutcomeToken(token0).balanceOf(address(this));
        uint balance1 = OutcomeToken(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(reserve0);
        uint amount1 = balance1.sub(reserve1);

        uint rP = reserve0.mul(reserve1);
        uint _reserve0 = reserve0.add(amount0).sub(amount);
        uint _reserve1 = reserve1.add(amount1).sub(amount);
        require(rP == _reserve0.mul(_reserve1));

        reserve0 = _reserve0;
        reserve1 = _reserve1;
        reserveC = reserveC.sub(amount);
    }

    function redeemWinning(uint amount) external {
        require(stage == Stages.MarketClosed);

        IERC20(tokenC).transfer(msg.sender, amount);

        uint balance0 = OutcomeToken(token0).balanceOf(address(this));
        uint balance1 = OutcomeToken(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(reserve0);
        uint amount1 = balance1.sub(reserve1);

        uint winnings;
        if (outcome == 0){
            winnings = winnings.add(amount0);
        }else if(outcome == 1){
            winnings = winnings.add(amount1);
        }else if (outcome == 2){
            winnings = winnings.add(amount0.div(2));
            winnings = winnings.add(amount1.div(2));
        }

        require(amount == winnings);
    }

    function setOutcome(uint _outcome) external {
        require(msg.sender == oracle);
        require(outcome < 3);
        outcome = _outcome;
        stage = Stages.MarketClosed;
    }
}