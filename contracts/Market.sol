pragma solidity ^0.8.0;

import './OutcomeToken.sol';
import './libraries/SafeMath.sol';
import './MarketFactory.sol';

// add fee for market creator
// add fee for 

contract Market {
    using SafeMath for uint;

    enum Stages {
        MarketCreated,
        MarketFunded,
        MarketBuffer,
        MarketResolve,
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
    uint public immutable expireByBlock;
    uint public bufferEndsByBlock;
    uint public bufferBlocks;
    uint public escalationBufferBlocks;
    uint public donCountLimit;

    address public creator;

    uint public outcome = 2;
    Stages public stage;

    uint256 reserveDoN0;
    uint256 reserveDoN1;
    uint public lastOutcomeStaked;
    uint public lastOutcomeAmountStaked;
    uint public donCount;
    // 0 or 1 => staker => amount
    mapping(bool => mapping(address => uint256)) stakes;
    address arbitratorCaller;



    modifier isMarketStage(Stages _stage) {
        if (stage == Stages.MarketResolve){
            require(_stage == Stages.MarketResolve);
            _;
            return;
        }
        if (block.number >= expireByBlock){
            stage = Stages.MarketBuffer;
        }
        if (block.number >= bufferEndsByBlock){
            stage = Stages.MarketClosed;
        }
        require(stage == _stage);
        _;
    }

    // don period
    // implement bond 
    // implement bon
    //

    constructor(){
        uint expireAfterBlocks;
        (factory, creator, identifier, tokenC, oracle, expireAfterBlocks, bufferBlocks) = MarketFactory(msg.sender).deployParams();
        token0 = address(new OutcomeToken());
        token1 = address(new OutcomeToken());
        expireByBlock = block.number.add(expireAfterBlocks);
        bufferEndsByBlock = expireByBlock + bufferBlocks;
    }

    function getReserves() external view returns (uint _reserve0, uint _reserve1){
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    function tokensAddresses() external view returns (address _token0, address _token1){
        _token0 = token0;
        _token1 = token1;
    }

    function fund() external isMarketStage(Stages.MarketCreated) {
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
    
    function buy(uint amount0, uint amount1) external isMarketStage(Stages.MarketFunded) {
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

    function sell(uint amount) external isMarketStage(Stages.MarketFunded) {
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

    function redeemWinning(uint amount) external isMarketStage(Stages.MarketClosed) {

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

    function stakeOutcome(uint _for) external isMarketStage(Stages.MarketBuffer) {
        require (_for < 2);

        uint balance = IERC20(tokenC).balanceOf(address(this));
        uint amount = balance.sub(reserveDoN0.add(reserveDoN1));
        if (_for == 0) {
            stakes[false][msg.sender] = amount;
            reserveDoN0 = reserveDoN0.add(amount);
        }
        if (_for == 1) {
            stakes[true][msg.sender] = amount;
            reserveDoN1 = reserveDoN1.add(amount);
        }

        if (lastOutcomeAmountStaked != 0) require(lastOutcomeAmountStaked.mul(2) == amount);
        lastOutcomeAmountStaked = amount;
        lastOutcomeStaked = _for;
        donCount += 1;
        bufferEndsByBlock = escalationBufferBlocks + block.number;
    }

    function redeemStake(uint _for) external isMarketStage(Stages.MarketClosed) {
        // if arb not called, then
        //     amount is retieved

        // else
        //     amount is retieved
        //     if (amount == lastOutcomeAmountStaked) then
        //         send the money (arb caller lost)
        //     else
        //         don't send money

        // haven't taken into account that market isn't resolved
        require(outcome < 3 && _for < 2);
        uint amount;
        if (_for == 0) amount = stakes[false][msg.sender];
        if (_for == 1) amount = stakes[true][msg.sender];

        uint winnings;
        if (outcome == 0 && _for == 0) {
            if (amount == lastOutcomeAmountStaked) winnings = winnings.add(reserveDoN1);
            winnings = winnings.add(amount);
        } else if (outcome == 1 && _for == 0) {
            if (amount == lastOutcomeAmountStaked) winnings = winnings.add(reserveDoN0);
            winnings = winnings.add(amount);
        } else {
            winnings = amount;
        }

        IERC20(tokenC).transfer(msg.sender, winnings);
    }

    // function redeemWinningsArbCaller() {
    //     // only wins if lastOutcome stake isn't the final outcome
    // }

    function callArbitrator() external isMarketStage(Stages.MarketBuffer) {
        // get the amount   
        // transfer to oracle
        // check amount == fee amount
        // set market to resolve
    }

    function setOutcome(uint _outcome) external isMarketStage(Stages.MarketResolve) {
        require(msg.sender == oracle);
        require(outcome < 3);
        outcome = _outcome;
        stage = Stages.MarketClosed;
    }
}