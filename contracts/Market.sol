pragma solidity ^0.8.0;

import './OutcomeToken.sol';
import './libraries/SafeMath.sol';
import './MarketFactory.sol';

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
    uint public immutable oracleFee;

    bytes32 public immutable identifier;
    uint public immutable expireAtBlock;

    address public creator;

    uint public outcome = 2;
    Stages public stage;

    // DON related
    uint donBufferEndsAtBlock;
    uint donBufferBlocks; 
    uint donEscalationLimit;
    uint256 reserveDoN0;
    uint256 reserveDoN1;
    uint public lastOutcomeStaked = 2;
    uint public lastOutcomeAmountStaked;
    uint public donEscalationCount;
    uint public donEscalationLimit;
    // 0 or 1 => staker => amount
    mapping(bool => mapping(address => uint256)) stakes;

    // final resolution related
    uint  resolutionBufferBlocks;
    uint resolutionEndsAtBlock;

    // modifier isMarketStage(Stages _stage) {
    //     if (stage == Stages.MarketResolve){
    //         if (block.number >= resolutionEndsAtBlock){
    //             // resolve the market to lasrt outcome
    //             stage = Stages.MarketClosed;
    //             require(_stage == Stages.MarketClosed);
    //             _;
    //             return;
    //         }else {
    //             require(_stage == Stages.MarketResolve);
    //             _;
    //             return;
    //         }
           
    //     }
    //     if (block.number >= expireAtBlock){
    //         stage = Stages.MarketBuffer;
    //     }
    //     if (block.number >= donBufferEndsAtBlock){
    //         stage = Stages.MarketClosed;
    //     }
    //     if (donEscalationCount > donEscalationLimit){
    //         stage = Stages.MarketResolve;
    //         resolutionEndsAtBlock = block.number + resolutionBufferBlocks;
    //     }
    //     require(stage == _stage);
    //     _;
    // }

    modifier isMarketCreated() {
        require (stage == Stages.MarketCreated);
    }

    modifier isMarketFunded(){
        require (stage == Stages.MarketFunded);

        if (block.number >= expireAtBlock){
            stage = Stages.MarketBuffer;
            donBufferEndsAtBlock = block.number + donBufferBlocks;
        }

        require (stage == Stages.MarketFunded);
        _;
    }

    modifier isMarketBuffer(){
        require (stage == Stages.MarketBuffer);

        if (block.number < donBufferEndsAtBlock && donEscalationLimit <= donEscalationCount){
            // change to market resolve & set block number for resolution expiry
            resolutionEndsAtBlock = block.number + resolutionBufferBlocks;
            stage = Stages.MarketResolve;
        }else if (block.number >= donBufferEndsAtBlock){
            setOutcomeByExpiry();
        }

        require (stage == Stages.MarketBuffer);
        _;
    }

    modifier isMarketResolve(){
        require (stage == Stages.MarketResolve);

        if (block.number >= resolutionEndsAtBlock){
            // close the market & set outcome to last staked outcome
            setOutcomeByExpiry();
        }

        require (stage == Stages.MarketBuffer);
        _;
    }

    modifier isMarketClosed() {
        require (stage == Stages.MarketClosed);
    }

    constructor(){
        uint expireAfterBlocks;
        (factory, creator, oracle, identifier, oracleFee, tokenC, expireAfterBlocks, donBufferBlocks, donEscalationLimit, resolutionBufferBlocks) = MarketFactory(msg.sender).deployParams();
        token0 = address(new OutcomeToken());
        token1 = address(new OutcomeToken());
        expireAtBlock = block.number.add(expireAfterBlocks);
    }

    function getReserves() external view returns (uint _reserve0, uint _reserve1){
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    function tokensAddresses() external view returns (address _token0, address _token1){
        _token0 = token0;
        _token1 = token1;
    }

    function setOutcomeByExpiry() private {
        // set the outcome as the last staked outcome, if any & close the market
        if (lastOutcomeStaked == 0){
            outcome = 0;
        }else if (lastOutcomeStaked == 1){
            outcome = 1;
        }else {
            // not outcome was staked, thus resolve the outcome to higher probability
            // the one with lesser reserve has higher probability
            if (reserve0 < reserve1){
                outcome = 0;
            }else if (reserve1 < reserve0){
                outcome = 1;
            }else {
                outcome = 2;
            }
        }
        stage = Stages.MarketClosed;
    }

    function fund() external isMarketCreated {
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
    
    function buy(uint amount0, uint amount1) external isMarketFunded {
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

    function sell(uint amount) external isMarketFunded {
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

    function redeemWinning(uint amount) external isMarketClosed {

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

    function stakeOutcome(uint _for) external isMarketBuffer {
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

    function redeemStake(uint _for) external isMarketClosed {
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

    function setOutcome(uint _outcome) external isMarketResolve {
        require(msg.sender == oracle);
        require(outcome < 3);
        outcome = _outcome;
        stage = Stages.MarketClosed;
    }
}