// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './OutcomeToken.sol';
import './MarketFactory.sol';
import './interfaces/IMarket.sol';
import './interfaces/IModerationCommitee.sol';

contract Market is IMarket {

    uint256 reserve0;
    uint256 reserve1;
    uint256 reserveC;

    address token0;
    address token1;
    address tokenC;

    address factory;
    bytes32 identifier;
    uint expireAtBlock;
    uint expireBufferBlocks;
    address creator;

    uint public outcome = 2;
    Stages public stage;

    // DON related
    uint256 reserveDoN0;
    uint256 reserveDoN1;
    uint lastOutcomeStaked = 2;
    Staking public override staking;
    uint donEscalationCount;
    uint donEscalationLimit;
    uint donBufferEndsAtBlock;
    uint donBufferBlocks; 
    // (0) or (1) outcome index -> staker's address => amount
    mapping(address => uint256)[2] stakes;

    // final resolution related
    address oracle;
    uint resolutionBufferBlocks;
    uint resolutionEndsAtBlock;
    uint oracleFeeNumerator;
    uint oracleFeeDenominator;


    modifier isMarketCreated() {
        require (stage == Stages.MarketCreated);
        _;
    }

    modifier isMarketFunded(){
        // market is only funded till block number < expireAtBlock
        require (stage == Stages.MarketFunded && block.number < expireAtBlock, "FALSE MF");
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
        require (_stage == Stages.MarketBuffer && donEscalationLimit > donEscalationCount && block.number < donBufferEndsAtBlock, "FALSE MB");
        _;
    }

    modifier isMarketResolve(){
        Stages _stage = stage;

        if(_stage != Stages.MarketResolve && _stage != Stages.MarketCreated){
            // if market expired and don escalation limit is zero, then market directly goes to MarketResolve (skipping MarketBuffer)
            // Note if donEscalationLimit == 0 && donBufferBlocks == 0 then market closes after expiry, thus no Market Resolve
            if (block.number >= expireAtBlock && donEscalationLimit == 0 && donBufferBlocks != 0){
                _stage = Stages.MarketResolve;
            }
        }

        // stage should be MarketResolve & resolution time shouldn't have expired
        require (_stage == Stages.MarketResolve && block.number < resolutionEndsAtBlock, "FALSE MR");
        _;
    }

    modifier isMarketClosed() {
        Stages _stage = stage;

        uint _donEscalationLimit = donEscalationLimit;
        uint _resolutionEndsAtBlock = resolutionEndsAtBlock;

        // when donBuffer && escalationLimit == 0, preference is given to donBuffer, that means market closes after expiration & does not waits for resolution
        // when escalationLimit == 0 & donBuffer != 0 then donBuffer is ignored and market transitions to resolve stage right after expiration
        // when donBuffer == 0 & escalationLimit != 0 then market closes right after expiration
        if (_stage != Stages.MarketClosed && _stage != Stages.MarketCreated){
            if ((_stage != Stages.MarketResolve && block.number >= donBufferEndsAtBlock && (donBufferBlocks == 0 || _donEscalationLimit != 0))
                || (block.number >= _resolutionEndsAtBlock && _stage == Stages.MarketResolve)
                || (block.number >= _resolutionEndsAtBlock && _donEscalationLimit == 0) 
            ){
                setOutcomeByExpiry();
                _stage = Stages.MarketClosed;
                stage = Stages.MarketClosed;
            }
        }

        require (_stage == Stages.MarketClosed, "FALSE MC");
        _;
    }

    constructor(){
        (address _creator, address _oracle, bytes32 _identifier) = MarketFactory(msg.sender).deployParams();
        (bool _isActive, address _tokenC, uint[6] memory details) = IModerationCommitte(_oracle).getMarketParams();
        require(_isActive == true, "ORACLE INACTIVE");
        require(details[0] <= details[1], "INVALID FEE");

        oracleFeeNumerator = details[0];
        oracleFeeDenominator = details[1];
        expireBufferBlocks = details[2];
        donBufferBlocks = details[3];
        donEscalationLimit = details[4];
        resolutionBufferBlocks = details[5];
        creator = _creator;
        oracle = _oracle;
        identifier = _identifier;
        tokenC = _tokenC;
        token0 = address(new OutcomeToken()); // significant gas cost
        token1 = address(new OutcomeToken());

        emit MarketCreated(address(this), _creator, _oracle, _identifier, _tokenC);
    }

    function getReservesTokenC() internal view returns (uint reserves){
        reserves = reserveC+reserveDoN0+reserveDoN1;
    }

    function getReservesOTokens() public view override returns (uint _reserve0, uint _reserve1){
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    function getAddressOfTokens() public view override returns (address _tokenC, address _token0, address _token1){
        _tokenC = tokenC;
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
    }

    function fund() external override isMarketCreated {
        uint amount = IERC20(tokenC).balanceOf(address(this)); // tokenC reserve is 0 at this point
        
        OutcomeToken(token0).issue(address(this), amount);
        OutcomeToken(token1).issue(address(this), amount);   

        reserve0 += amount;
        reserve1 += amount;
        reserveC += amount;
        stage = Stages.MarketFunded;
        uint _expireBufferBlocks = expireBufferBlocks;
        expireAtBlock = block.number + _expireBufferBlocks; 
        donBufferEndsAtBlock = block.number + _expireBufferBlocks + donBufferBlocks; // pre-set buffer period expiry
        resolutionEndsAtBlock = block.number + _expireBufferBlocks + resolutionBufferBlocks; // pre-set resolution expiry, incase donEscalationLimit == 0
        
        require(amount > 0, 'AMOUNT 0');

        emit MarketFunded(
            address(this), 
            reserve0, 
            reserve1, 
            reserveC,
            expireAtBlock,
            donBufferEndsAtBlock,
            donEscalationLimit,
            resolutionEndsAtBlock
        );
    }
    
    function buy(uint amount0, uint amount1, address to) external override isMarketFunded {
        address _token0 = token0;
        address _token1 = token1;
        (uint _reserve0, uint _reserve1) = getReservesOTokens();

        uint reserveTokenC = getReservesTokenC();
        uint balance = IERC20(tokenC).balanceOf(address(this));
        uint amount = balance - reserveTokenC;

        // buying all tokens
        OutcomeToken(_token0).issue(address(this), amount);
        OutcomeToken(_token1).issue(address(this), amount);

        // transfer
        if (amount0 > 0) OutcomeToken(_token0).transfer(to, amount0);
        if (amount1 > 0) OutcomeToken(_token1).transfer(to, amount1);

        uint _reserve0New = (_reserve0 + amount) - amount0;
        uint _reserve1New = (_reserve1 + amount) - amount1;
        require((_reserve0*_reserve1) <= (_reserve0New*_reserve1New), "ERR - INV");

        reserve0 = _reserve0New;
        reserve1 = _reserve1New;
        reserveC += amount;

        emit OutcomeBought(address(this), to, amount, amount0, amount1, _reserve0New, _reserve1New);
    }   

    function sell(uint amount, address to) external override isMarketFunded {
        address _tokenC = tokenC;
        (uint _reserve0, uint _reserve1) = getReservesOTokens();

        IERC20(_tokenC).transfer(to, amount);

        uint balance0 = OutcomeToken(token0).balanceOf(address(this));
        uint balance1 = OutcomeToken(token1).balanceOf(address(this));
        uint amount0 = balance0 - _reserve0;
        uint amount1 = balance1 - _reserve1;

        // burn outcome tokens
        OutcomeToken(token0).revoke(address(this), amount);
        OutcomeToken(token1).revoke(address(this), amount);

        uint _reserve0New = (_reserve0 + amount0) - amount;
        uint _reserve1New = (_reserve1 + amount1) - amount;
        require((_reserve0*_reserve1) <= (_reserve0New*_reserve1New), "ERR - INV");

        reserve0 = _reserve0New;
        reserve1 = _reserve1New;
        reserveC -= amount;

        emit OutcomeSold(address(this), to, amount0, amount1, amount, _reserve0New, _reserve1New);
    }

    function redeemWinning(uint _for, address to) external override isMarketClosed {
        uint amount;
        if (_for == 0){
            address _token0 = token0;
            uint balance = OutcomeToken(_token0).balanceOf(address(this));
            amount = balance - reserve0;
            OutcomeToken(_token0).revoke(address(this), amount);
        }else if (_for == 1){
            address _token1 = token1;
            uint balance = OutcomeToken(_token1).balanceOf(address(this));
            amount = balance - reserve1;
            OutcomeToken(_token1).revoke(address(this), amount);
        }

        uint _outcome = outcome;
        if (_outcome == 2){
            amount = amount/2;                
        }else if (_outcome != _for){
            amount = 0;
        }
        IERC20(tokenC).transfer(to, amount);

        reserveC -= amount;

        require(_for < 2);

        emit WinningRedeemed(address(this), to, _for, amount, _outcome);
    }

    function stakeOutcome(uint _for, address to) external override isMarketBuffer {
        require(_for < 2);
        
        Staking memory _staking = staking;
        uint _lastAmountStaked0 = _staking.amount0;
        uint _lastAmountStaked1 = _staking.amount1;

        uint reserveTokenC = getReservesTokenC(); 
        uint balance = IERC20(tokenC).balanceOf(address(this));
        uint amount = balance - reserveTokenC;

        stakes[_for][to] += amount;
        if (_for == 0) {
            reserveDoN0 += amount;
            _staking.amount0 = amount;
            _staking.staker0 = to;
        }
        if (_for == 1) {
            reserveDoN1 += amount;
            _staking.amount1 = amount;
            _staking.staker1 = to;
        } 

        lastOutcomeStaked = _for;
        donEscalationCount += 1;
        donBufferEndsAtBlock = donBufferBlocks + block.number;
        staking = _staking;
        
        // update stage to MarketResolve, if don limit exceeded
        if (donEscalationLimit <= donEscalationCount){
            // change to market resolve & set block number for resolution expiry
            resolutionEndsAtBlock = block.number + resolutionBufferBlocks;
            stage = Stages.MarketResolve;
            emit EscalationLimitReached(address(this), resolutionEndsAtBlock);
        }

        require((_lastAmountStaked1*2) <= amount, "DBL STAKE");
        require((_lastAmountStaked0*2) <= amount, "DBL STAKE");
        require(amount != 0, "INVALID STAKE");

        emit OutcomeStaked(address(this), to, _for, amount);
    }

    function redeemStake(uint _for) external override isMarketClosed {
        uint _outcome = outcome;
        uint _reserveDoN0 = reserveDoN0;
        uint _reserveDoN1 = reserveDoN1;

        uint amount;
        if (_outcome == 2){
            amount += stakes[_for][msg.sender];
            stakes[_for][msg.sender] = 0;
            if (_for == 0) _reserveDoN0 -= amount;
            if (_for == 1) _reserveDoN1 -= amount;
        }else {
            Staking memory _staking = staking;
            amount = stakes[_outcome][msg.sender];
            stakes[_outcome][msg.sender] = 0;
            if (_outcome == 0) {
                _reserveDoN0 -= amount;
                if (_staking.staker0 == msg.sender || _staking.staker0 == address(0)){
                    amount += _reserveDoN1;
                    _reserveDoN1 = 0;
                }
            }else if (_outcome == 1) {
                _reserveDoN1 -= amount;
                if (_staking.staker1 == msg.sender || _staking.staker1 == address(0)){
                    amount += _reserveDoN0;
                    _reserveDoN0 = 0;
                }
            }
        }

        IERC20(tokenC).transfer(msg.sender, amount);

        reserveDoN0 = _reserveDoN0;
        reserveDoN1 = _reserveDoN1;

        emit StakeRedeemed(address(this), msg.sender, _for, amount);
    }

    function setOutcome(uint _outcome) external override isMarketResolve {
        require(_outcome < 3);
        
        uint _oracleFeeNumerator = oracleFeeNumerator;
        uint _oracleFeeDenominator = oracleFeeDenominator;
        address _oracle = oracle;

        if (_outcome != 2 && oracleFeeNumerator != 0 && oracleFeeDenominator >= oracleFeeNumerator){
            uint fee;
            uint _reserveDoN1 = reserveDoN1;
            uint _reserveDoN0 = reserveDoN0;
            if (_outcome == 0 && _reserveDoN1 != 0) {
                fee = (_reserveDoN1*_oracleFeeNumerator)/_oracleFeeDenominator;
                reserveDoN1 -= fee;
            }
            if (_outcome == 1 && _reserveDoN0 != 0) {
                fee = (_reserveDoN0*_oracleFeeNumerator)/_oracleFeeDenominator;
                reserveDoN0 -= fee;
            }
            IERC20(tokenC).transfer(_oracle, fee);
        }
        
        outcome = _outcome;
        stage = Stages.MarketClosed;
        require(msg.sender == _oracle);

        emit OracleSetOutcome(address(this), _outcome);
    }

    function claimReserve() external isMarketClosed {
        address _creator = creator;
        require(msg.sender == _creator);
        uint _reserve0 = reserve0;
        uint _reserve1 = reserve1;
        TransferHelper.safeTransfer(token0, _creator, _reserve0);
        TransferHelper.safeTransfer(token1, _creator, _reserve1);
        reserve0 = 0;
        reserve1 = 0;
    }
}

