// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './OutcomeToken.sol';
import './libraries/SafeMath.sol';
import './MarketFactory.sol';
import './MarketDeployer.sol';
import 'hardhat/console.sol';

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
    bytes32 public immutable identifier;
    uint public expireAtBlock;
    uint public expireBufferBlocks;
    address public creator;


    uint public outcome = 2;
    Stages public stage;

    // DON related
    uint256 public reserveDoN0;
    uint256 public reserveDoN1;
    uint public lastOutcomeStaked = 2;
    uint public lastAmountStaked0;
    uint public lastAmountStaked1;
    uint public donEscalationCount;
    uint public donEscalationLimit;
    uint public donBufferEndsAtBlock;
    uint public donBufferBlocks; 
    // (0) or (1) outcome index -> staker's address => amount
    mapping(address => uint256)[2] stakes;

    // final resolution related
    address oracle;
    uint public resolutionBufferBlocks;
    uint public resolutionEndsAtBlock;
    uint public immutable oracleFeeNumerator;
    uint public immutable oracleFeeDenominator;

    modifier isMarketCreated() {
        require (stage == Stages.MarketCreated);
        _;
    }

    modifier isMarketFunded(){
        // market is only funded till block number < expireAtBlock
        require (stage == Stages.MarketFunded && block.number < expireAtBlock);
        _;
    }

    modifier isMarketBuffer(){
        Stages _stage = stage;

        // if stage value is MarketFunded & market time expired & initial (set in  constructor) don buffer time hasn't expired, then change state to MarketBuffer
        if (_stage == Stages.MarketFunded && block.number >= expireAtBlock && block.number < donBufferEndsAtBlock){
            _stage = Stages.MarketBuffer;
            stage = _stage;
            donBufferEndsAtBlock = block.number + donBufferBlocks;
        }

        // only when stage is MarketBuffer && escalation limit hasn't been reached && buffer period hasn't expired
        require (_stage == Stages.MarketBuffer && donEscalationLimit > donEscalationCount && block.number < donBufferEndsAtBlock);
        _;
    }

    modifier isMarketResolve(){
        // stage should be MarketResolve & resolution time shouldn't have expired
        require (stage == Stages.MarketResolve && block.number < resolutionEndsAtBlock);
        _;
    }

    modifier isMarketClosed() {
        Stages _stage = stage;

        // if stage is MarketBuffer & donBuffer expired OR if stage is MarketResolve & resolution time expired
        if ((_stage != Stages.MarketResolve && block.number >= donBufferEndsAtBlock)
            || (_stage == Stages.MarketResolve && block.number >= resolutionEndsAtBlock)){
            setOutcomeByExpiry();
            _stage = Stages.MarketClosed;
            stage = Stages.MarketClosed;
        }

        require (_stage == Stages.MarketClosed);
        _;
    }

    constructor(){
        (factory, creator, oracle, identifier, oracleFeeNumerator, oracleFeeDenominator, tokenC, expireBufferBlocks, donBufferBlocks, donEscalationLimit, resolutionBufferBlocks) = MarketDeployer(msg.sender).deployParams();
        token0 = address(new OutcomeToken());
        token1 = address(new OutcomeToken());
    }

    function getReservesTokenC() public view returns (uint _reserveC, uint _reserveDoN0, uint _reserveDoN1){
        _reserveC = reserveC;
        _reserveDoN0 = reserveDoN0;
        _reserveDoN1 = reserveDoN1;
    }

    function getReservesOTokens() public view returns (uint _reserve0, uint _reserve1){
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    function getAddressOTokens() public view returns (address _token0, address _token1){
        _token0 = token0;
        _token1 = token1;
    }

    function getOutcomeStakes() public view returns (uint[2] memory _stakesArr){
        _stakesArr[0] = lastAmountStaked0;
        _stakesArr[1] = lastAmountStaked1;
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
    }

    function fund() external isMarketCreated {
        uint balance = IERC20(tokenC).balanceOf(address(this));
        (uint _reserveC, uint _reserveDoN0, uint _reserveDoN1) = getReservesTokenC();
        uint amount = balance - (_reserveC + _reserveDoN0 + _reserveDoN1);
        
        OutcomeToken(token0).issue(address(this), amount);
        OutcomeToken(token1).issue(address(this), amount);   

        reserve0 += amount;
        reserve1 += amount;
        reserveC += amount;
        stage = Stages.MarketFunded;
        uint _expireBufferBlocks = expireBufferBlocks;
        expireAtBlock = block.number + _expireBufferBlocks;
        donBufferEndsAtBlock = block.number + _expireBufferBlocks + donBufferBlocks;
        
        require(amount > 0, 'Funding amount zero');
    }
    
    function buy(uint amount0, uint amount1, address to) external isMarketFunded {
        address _token0 = token0;
        address _token1 = token1;
        (uint _reserveC, uint _reserveDoN0, uint _reserveDoN1) = getReservesTokenC();
        (uint _reserve0, uint _reserve1) = getReservesOTokens();

        uint balance = IERC20(tokenC).balanceOf(address(this));
        uint amount = balance - (_reserveC + _reserveDoN0 + _reserveDoN1);

        // buying all tokens
        OutcomeToken(_token0).issue(address(this), amount);
        OutcomeToken(_token1).issue(address(this), amount);

        // transfer
        if (amount0 > 0) OutcomeToken(_token0).transfer(to, amount0);
        if (amount1 > 0) OutcomeToken(_token1).transfer(to, amount1);

        uint _reserve0New = (_reserve0 + amount) - amount0;
        uint _reserve1New = (_reserve1 + amount) - amount1;
        require(_reserve0.mul(_reserve1) <= _reserve0New.mul(_reserve1New));

        reserve0 = _reserve0New;
        reserve1 = _reserve1New;
        reserveC += amount;
    }   

    function sell(uint amount, address to) external isMarketFunded {
        address _tokenC = tokenC;
        (uint _reserve0, uint _reserve1) = getReservesOTokens();

        IERC20(_tokenC).transfer(to, amount);

        uint balance0 = OutcomeToken(token0).balanceOf(address(this));
        uint balance1 = OutcomeToken(token1).balanceOf(address(this));
        uint amount0 = balance0 - _reserve0;
        uint amount1 = balance1 - _reserve1;

        uint _reserve0New = (_reserve0 + amount0) - amount;
        uint _reserve1New = (_reserve1 + amount1) - amount;
        require(_reserve0.mul(_reserve1) == _reserve0New.mul(_reserve1New));

        reserve0 = _reserve0New;
        reserve1 = _reserve1New;
        reserveC -= amount;
    }

    function redeemWinning(uint _for, address to) external isMarketClosed {
        uint amount;
        if (_for == 0){
            uint balance = OutcomeToken(token0).balanceOf(address(this));
            amount = balance - reserve0;
        }else if (_for == 1){
            uint balance = OutcomeToken(token1).balanceOf(address(this));
            amount = balance - reserve1;
        }

        uint _outcome = outcome;
        if (_outcome == _for){
            IERC20(tokenC).transfer(to, amount);
        }else {
            IERC20(tokenC).transfer(to, amount.div(2));
        }

        require(_for < 2);
    }

    function stakeOutcome(uint _for, address to) external isMarketBuffer {
        (uint _reserveC, uint _reserveDoN0, uint _reserveDoN1) = getReservesTokenC(); 
        uint _lastAmountStaked0 = lastAmountStaked0;
        uint _lastAmountStaked1 = lastAmountStaked1;

        uint balance = IERC20(tokenC).balanceOf(address(this));
        uint amount = balance - (_reserveDoN0 + _reserveDoN1 + _reserveC);

        stakes[_for][to] += amount;
        if (_for == 0) {
            reserveDoN0 += amount;
            lastAmountStaked0 = amount;
        }
        if (_for == 1) {
            reserveDoN1 += amount;
            lastAmountStaked1 = amount;
        } 
        lastOutcomeStaked = _for;
        donEscalationCount += 1;
        donBufferEndsAtBlock = donBufferBlocks + block.number;

        // update stage to MarketResolve, if don limit exceeded
        if (donEscalationLimit <= donEscalationCount){
            // change to market resolve & set block number for resolution expiry
            resolutionEndsAtBlock = block.number + resolutionBufferBlocks;
            stage = Stages.MarketResolve;
        }

        require(_lastAmountStaked1.mul(2) <= amount);
        require(_lastAmountStaked0.mul(2) <= amount);
        require(amount != 0);
        require(_for < 2);
    }

    function redeemStake(uint _for) external isMarketClosed {
        uint _outcome = outcome;
        uint _reserveDoN0 = reserveDoN0;
        uint _reserveDoN1 = reserveDoN1;

        uint amount;
        if (_outcome == 2){
            amount += stakes[_for][msg.sender];
            stakes[_for][msg.sender] = 0;
            if (_for == 0) _reserveDoN0 -= amount;
            if (_for == 1) _reserveDoN1 -= amount;
        }else if (_outcome < 2) {
            amount = stakes[_outcome][msg.sender];
            stakes[_outcome][msg.sender] = 0;
            if (_outcome == 0) {
                _reserveDoN0 -= amount;
            }else if (_outcome == 1) {
                _reserveDoN1 -= amount;
            }
            if (amount == lastAmountStaked0){
                amount += _reserveDoN1;
                _reserveDoN1 = 0;
            }else if (amount == lastAmountStaked1){
                amount += _reserveDoN0;
                _reserveDoN0 = 0;
            }
        }

        IERC20(tokenC).transfer(msg.sender, amount);

        reserveDoN0 = _reserveDoN0;
        reserveDoN1 = _reserveDoN1;
    }

    function setOutcome(uint _outcome) external isMarketResolve {
        require(_outcome < 3);
        
        uint _oracleFeeNumerator = oracleFeeNumerator;
        uint _oracleFeeDenominator = oracleFeeDenominator;
        address _oracle = oracle;

        if (_outcome != 2 && oracleFeeNumerator != 0 && oracleFeeDenominator >= oracleFeeNumerator){
            uint fee;
            uint _reserveDoN1 = reserveDoN1;
            uint _reserveDoN0 = reserveDoN0;
            if (_outcome == 0 && _reserveDoN1 != 0) {
                fee = _reserveDoN1.mul(_oracleFeeNumerator).div(_oracleFeeDenominator);
                reserveDoN1 -= fee;
            }
            if (_outcome == 1 && _reserveDoN0 != 0) {
                fee = _reserveDoN0.mul(_oracleFeeNumerator).div(_oracleFeeDenominator);
                reserveDoN0 -= fee;
            }
            IERC20(tokenC).transfer(_oracle, fee);
        }
        
        outcome = _outcome;
        stage = Stages.MarketClosed;
        require(msg.sender == _oracle);
    }

    function trimStake(address to) external isMarketClosed {
        uint _outcome = outcome;
        if (_outcome == 0 && lastAmountStaked0 == 0){
            IERC20(tokenC).transfer(to, reserveDoN1);
            reserveDoN1 = 0;
        }else if (_outcome == 1 && lastAmountStaked1 == 0){
            IERC20(tokenC).transfer(to, reserveDoN0);
            reserveDoN0 = 0;
        }
    }
}
