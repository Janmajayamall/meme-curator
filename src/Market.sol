// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './OutcomeToken.sol';
import './interfaces/IMarketFactory.sol';
import './interfaces/IMarket.sol';
import './interfaces/IModerationCommitee.sol';
import './interfaces/IOutcomeToken.sol';
import './interfaces/IERC20.sol';

contract Market {

    struct Staking {
        uint256 lastAmountStaked;
        address staker0;
        address staker1;
        uint8 lastOutcomeStaked;
    }

   enum Stages {
        MarketCreated,
        MarketFunded,
        MarketBuffer,
        MarketResolve,
        MarketClosed
    }

    struct MarketDetails {
        uint32 expireAtBlock;
        uint32 donBufferEndsAtBlock;
        uint32 resolutionEndsAtBlock;
        uint32 expireBufferBlocks;
        uint32 donBufferBlocks; 
        uint32 resolutionBufferBlocks;

        uint16 donEscalationCount;
        uint16 donEscalationLimit;

        uint8 oracleFeeNumerator;
        uint8 oracleFeeDenominator;
        uint8 outcome;
        uint8 stage;
    }

    uint256 private reserve0;
    uint256 private reserve1;
    uint256 private reserveC;
    

    address immutable private token0;
    address immutable private token1;
    address immutable private tokenC;

    bytes32 immutable identifier;
    address immutable creator;
    address immutable oracle;

    /* 
    Staking Info
    */
    uint256 private reserveDoN0;
    uint256 private reserveDoN1;
    Staking private staking;
    // bytes32 (i.e. keccak(en(address,key))) => amount staked
    mapping(bytes32 => uint256) stakes;

    MarketDetails marketDetails;

    // modifier isMarketBuffer(){
    //     Stages _stage = stage;

    //     // if stage value is MarketFunded & market time expired & initial (set in  constructor) don buffer time hasn't expired, then change state to MarketBuffer
    //     if (_stage == Stages.MarketFunded && block.number >= expireAtBlock && block.number < donBufferEndsAtBlock){
    //         _stage = Stages.MarketBuffer;
    //         stage = _stage;
    //         donBufferEndsAtBlock = block.number + donBufferBlocks;
    //     }

    //     // only when stage is MarketBuffer && escalation limit hasn't been reached && buffer period hasn't expired
    //     require (_stage == Stages.MarketBuffer && donEscalationLimit > donEscalationCount && block.number < donBufferEndsAtBlock, "FALSE MB");
    //     _;
    // }

    // modifier isMarketResolve(){
    //     Stages _stage = stage;

    //     if(_stage != Stages.MarketResolve && _stage != Stages.MarketCreated){
    //         // if market expired and don escalation limit is zero, then market directly goes to MarketResolve (skipping MarketBuffer)
    //         // Note if donEscalationLimit == 0 && donBufferBlocks == 0 then market closes after expiry, thus no Market Resolve
    //         if (block.number >= expireAtBlock && donEscalationLimit == 0 && donBufferBlocks != 0){
    //             _stage = Stages.MarketResolve;
    //         }
    //     }

    //     // stage should be MarketResolve & resolution time shouldn't have expired
    //     require (_stage == Stages.MarketResolve && block.number < resolutionEndsAtBlock, "FALSE MR");
    //     _;
    // }

    // modifier isMarketClosed() {
    //     Stages _stage = stage;

    //     uint _donEscalationLimit = donEscalationLimit;
    //     uint _resolutionEndsAtBlock = resolutionEndsAtBlock;

    //     // when donBuffer && escalationLimit == 0, preference is given to donBuffer, that means market closes after expiration & does not waits for resolution
    //     // when escalationLimit == 0 & donBuffer != 0 then donBuffer is ignored and market transitions to resolve stage right after expiration
    //     // when donBuffer == 0 & escalationLimit != 0 then market closes right after expiration
    //     if (_stage != Stages.MarketClosed && _stage != Stages.MarketCreated){
    //         if ((_stage != Stages.MarketResolve && block.number >= donBufferEndsAtBlock && (donBufferBlocks == 0 || _donEscalationLimit != 0))
    //             || (block.number >= _resolutionEndsAtBlock && _stage == Stages.MarketResolve)
    //             || (block.number >= _resolutionEndsAtBlock && _donEscalationLimit == 0) 
    //         ){
    //             setOutcomeByExpiry();
    //             _stage = Stages.MarketClosed;
    //             stage = Stages.MarketClosed;
    //         }
    //     }

    //     require (_stage == Stages.MarketClosed, "FALSE MC");
    //     _;
    // }

    constructor(){
        address _oracle;
        (creator, _oracle, identifier) = IMarketFactory(msg.sender).deployParams();

        // retrieve market configurtion from oracle
        MarketDetails memory _details;
        bool isActive;
        (tokenC, isActive, _details.oracleFeeDenominator, _details.oracleFeeDenominator, _details.donEscalationLimit, _details.expireBufferBlocks, _details.donBufferBlocks, _details.resolutionBufferBlocks) = IModerationCommitte(_oracle).getMarketParams();
        require(isActive == true);
        require(_details.oracleFeeNumerator <= _details.oracleFeeDenominator);
        marketDetails = _details;
        oracle = _oracle;
        token0 = address(new OutcomeToken()); // significant gas cost
        token1 = address(new OutcomeToken());
    }

    function totalReservesTokenC() internal view returns (uint reserves){
        reserves = reserveC+reserveDoN0+reserveDoN1;
    }

    function isMarketFunded() internal view returns (bool) {
        MarketDetails memory _details = marketDetails;
        if (_details.stage == uint8(Stages.MarketFunded) && block.number < _details.expireAtBlock) return true;
        return false;
    }

    function isMarketClosed() internal returns (bool, uint8){
        MarketDetails memory _details = marketDetails;    
        if (_details.stage != uint8(Stages.MarketClosed) && _details.stage != uint8(Stages.MarketCreated)){
            if(
                (_details.stage != uint8(Stages.MarketResolve) && block.number >= _details.donBufferEndsAtBlock && (_details.donBufferBlocks == 0 || _details.donEscalationLimit != 0))
                || (block.number >=  _details.resolutionEndsAtBlock && (_details.stage == uint8(Stages.MarketResolve) || _details.donEscalationLimit == 0))
                )
            {
                // Set outcome by expiry  
                Staking memory _staking = staking;
                if (_staking.staker0 == address(0) && _staking.staker1 == address(0)){
                    uint _reserve0 = reserve0;
                    uint _reserve1 = reserve1;
                    if (_reserve0 < _reserve1){
                        _details.outcome = 0;
                    }else if (_reserve1 < _reserve0){
                        _details.outcome = 1;
                    }else {
                        _details.outcome = 2;
                    }
                }else{
                    _details.outcome = _staking.lastOutcomeStaked;
                }
                _details.stage = uint8(Stages.MarketClosed);
                marketDetails = _details;
                return (true, _details.outcome); 
            }
           return (false, 2);
        }
        return (true, _details.outcome);
    }

    // function setOutcomeByExpiry() internal {           
    //     // set the outcome as the last staked outcome, if any & close the market
    //     if (lastOutcomeStaked == 0){
    //         outcome = 0;
    //     }else if (lastOutcomeStaked == 1){
    //         outcome = 1;
    //     }else {
    //         // not outcome was staked, thus resolve the outcome to higher probability
    //         // the one with lesser reserve has higher probability
    //         if (reserve0 < reserve1){
    //             outcome = 0;
    //         }else if (reserve1 < reserve0){
    //             outcome = 1;
    //         }else {
    //             outcome = 2;
    //         }
    //     }
    // }

    function fund() external {
        MarketDetails memory _details = marketDetails;
        require(_details.stage == uint8(Stages.MarketCreated));

        uint amount = IERC20(tokenC).balanceOf(address(this)); // tokenC reserve is 0 at this point
        
        IOutcomeToken(token0).issue(address(this), amount);
        IOutcomeToken(token1).issue(address(this), amount);   

        reserve0 += amount;
        reserve1 += amount;
        reserveC += amount;

        _details.stage = uint8(Stages.MarketFunded);
        _details.expireAtBlock = uint32(block.number) + _details.expireBufferBlocks;
        _details.donBufferEndsAtBlock = _details.expireAtBlock + _details.donBufferBlocks; // pre-set buffer expiry for first buffer period
        _details.resolutionEndsAtBlock = uint32(block.number) + _details.resolutionBufferBlocks; // pre-set resolution expiry, in case donEscalationLimit == 0 && donBufferBlocks > 0
        marketDetails = _details;
        
        // stage = Stages.MarketFunded;
        // uint _expireBufferBlocks = expireBufferBlocks;
        // expireAtBlock = block.number + _expireBufferBlocks; 
        // donBufferEndsAtBlock = block.number + _expireBufferBlocks + donBufferBlocks; // pre-set buffer period expiry
        // resolutionEndsAtBlock = block.number + _expireBufferBlocks + resolutionBufferBlocks; // pre-set resolution expiry, incase donEscalationLimit == 0
        
        require(amount > 0, 'AMOUNT 0');
    }
    
    function buy(uint amount0, uint amount1, address to) external {
        require(isMarketFunded());

        address _token0 = token0;
        address _token1 = token1;
        uint _reserve0 = reserve0;
        uint _reserve1 = reserve1;

        uint reserveTokenC = totalReservesTokenC();
        uint balance = IERC20(tokenC).balanceOf(address(this));
        uint amount = balance - reserveTokenC;

        // buying all tokens
        IOutcomeToken(_token0).issue(address(this), amount);
        IOutcomeToken(_token1).issue(address(this), amount);

        // transfer
        if (amount0 > 0) IOutcomeToken(_token0).transfer(to, amount0);
        if (amount1 > 0) IOutcomeToken(_token1).transfer(to, amount1);

        uint _reserve0New = (_reserve0 + amount) - amount0;
        uint _reserve1New = (_reserve1 + amount) - amount1;
        require((_reserve0*_reserve1) <= (_reserve0New*_reserve1New), "ERR - INV");

        reserve0 = _reserve0New;
        reserve1 = _reserve1New;
        reserveC += amount;

        // emit OutcomeBought(address(this), to, amount, amount0, amount1, _reserve0New, _reserve1New);
    }   

    function sell(uint amount, address to) external {
        require(isMarketFunded());

        address _tokenC = tokenC;
        uint _reserve0 = reserve0;
        uint _reserve1 = reserve1;

        IERC20(_tokenC).transfer(to, amount);

        uint balance0 = IOutcomeToken(token0).balanceOf(address(this));
        uint balance1 = IOutcomeToken(token1).balanceOf(address(this));
        uint amount0 = balance0 - _reserve0;
        uint amount1 = balance1 - _reserve1;

        // burn outcome tokens
        IOutcomeToken(token0).transfer(address(0), amount);
        IOutcomeToken(token1).transfer(address(0), amount);

        uint _reserve0New = (_reserve0 + amount0) - amount;
        uint _reserve1New = (_reserve1 + amount1) - amount;
        require((_reserve0*_reserve1) <= (_reserve0New*_reserve1New), "ERR - INV");

        reserve0 = _reserve0New;
        reserve1 = _reserve1New;
        reserveC -= amount;

        // emit OutcomeSold(address(this), to, amount0, amount1, amount, _reserve0New, _reserve1New);
    }

    function redeemWinning(uint _for, address to) external {
        (bool valid, uint8 outcome) = isMarketClosed();
        require(valid);

        uint amount;
        if (_for == 0){
            address _token0 = token0;
            uint balance = IOutcomeToken(_token0).balanceOf(address(this));
            amount = balance - reserve0;
            IOutcomeToken(_token0).transfer(address(0), amount);
        }else if (_for == 1){
            address _token1 = token1;
            uint balance = IOutcomeToken(_token1).balanceOf(address(this));
            amount = balance - reserve1;
            IOutcomeToken(_token1).transfer(address(0), amount);
        }

        if (outcome == 2){
            amount = amount/2;                
        }else if (outcome != _for){
            amount = 0;
        }
        IERC20(tokenC).transfer(to, amount);

        reserveC -= amount;

        require(_for < 2);

        // emit WinningRedeemed(address(this), to, _for, amount, _outcome);
    }

    function stakeOutcome(uint _for, address to) external {
        require(_for < 2);

        MarketDetails memory _details = marketDetails;
        if (_details.stage == uint8(Stages.MarketFunded) && block.number >= _details.expireAtBlock){
            _details.stage = uint8(Stages.MarketBuffer);
        }
        require(
            _details.stage == uint8(Stages.MarketBuffer) 
            && _details.donEscalationCount < _details.donEscalationLimit
            && block.number < _details.donBufferEndsAtBlock
        );

        uint reserveTokenC = totalReservesTokenC();
        uint balance = IERC20(tokenC).balanceOf(address(this));
        uint amount = balance - reserveTokenC;

        Staking memory _staking = staking;

        bytes32 key = keccak256(abi.encode(to, _for));
        stakes[key] += amount;
        if (_for == 0) {
            reserveDoN0 += amount;
            _staking.staker0 = to;
            _staking.lastOutcomeStaked = 0;
        }
        if (_for == 1) {
            reserveDoN1 += amount;
            _staking.staker1 = to;
            _staking.lastOutcomeStaked = 1;
        } 

        require(amount >= (_staking.lastAmountStaked * 2), "DBL");
        _staking.lastAmountStaked = amount;
        staking = _staking;

        if (_details.donEscalationCount + 1 < _details.donEscalationLimit){
            _details.donBufferEndsAtBlock = uint32(block.number) + _details.donBufferBlocks;
        }else{
            _details.resolutionEndsAtBlock = uint32(block.number) + _details.resolutionBufferBlocks;
            _details.stage = uint8(Stages.MarketResolve);
        }
        _details.donEscalationCount += 1;
        marketDetails = _details;
    }

    function redeemStake(uint _for) external {
        require(_for < 2);

        (bool valid, uint8 outcome) = isMarketClosed();
        require(valid);
        
        uint _reserveDoN0 = reserveDoN0;
        uint _reserveDoN1 = reserveDoN1;

        bytes32 key = keccak256(abi.encode(address(this), _for));
        uint amount = stakes[key];
        stakes[key] = 0;

        if (outcome == 2){    
            if (_for == 0) _reserveDoN0 -= amount;
            if (_for == 1) _reserveDoN1 -= amount;
        }else if (outcome == _for){
            Staking memory _staking = staking;
            if (outcome == 0) {
                _reserveDoN0 -= amount;
                if (_staking.staker0 == msg.sender || _staking.staker0 == address(0)){
                    amount += _reserveDoN1;
                    _reserveDoN1 = 0;
                }
            }else if (outcome == 1) {
                _reserveDoN1 -= amount;
                if (_staking.staker1 == msg.sender || _staking.staker1 == address(0)){
                    amount += _reserveDoN0;
                    _reserveDoN0 = 0;
                }
            }
        }else {
            amount = 0;
        }

        IERC20(tokenC).transfer(msg.sender, amount);

        reserveDoN0 = _reserveDoN0;
        reserveDoN1 = _reserveDoN1;
    }

    function setOutcome(uint8 outcome) external {
        require(outcome < 3);

        MarketDetails memory _details = marketDetails;
        if (_details.stage == uint8(Stages.MarketFunded) 
            && _details.donEscalationLimit == 0
            && _details.donBufferBlocks != 0){
            // donEscalationLimit == 0, indicates direct transition to MarketResolve after Market expiry
            // But if donBufferPeriod == 0 as well, then transition to MarketClosed after Market expiry
            _details.stage = uint8(Stages.MarketResolve);
        }
        require(_details.stage == uint8(Stages.MarketResolve) && block.number < _details.resolutionEndsAtBlock);
        
        address _oracle = oracle;
        uint oracleFeeNumerator = _details.oracleFeeNumerator;
        uint oracleFeeDenominator = _details.oracleFeeDenominator;

        if (outcome != 2 && oracleFeeNumerator != 0){
            uint fee;
            uint _reserveDoN1 = reserveDoN1;
            uint _reserveDoN0 = reserveDoN0;
            if (outcome == 0 && _reserveDoN1 != 0) {
                fee = (_reserveDoN1*oracleFeeNumerator)/oracleFeeDenominator;
                reserveDoN1 -= fee;
            }
            if (outcome == 1 && _reserveDoN0 != 0) {
                fee = (_reserveDoN0*oracleFeeNumerator)/oracleFeeDenominator;
                reserveDoN0 -= fee;
            }
            IERC20(tokenC).transfer(_oracle, fee);
        }
        
        _details.outcome = outcome;
        _details.stage = uint8(Stages.MarketClosed);
        marketDetails = _details;

        require(msg.sender == _oracle);
    }

    function claimReserve() external { 
        (bool valid,) = isMarketClosed();
        require(valid);
        address _creator = creator;
        require(msg.sender == _creator);
        uint _reserve0 = reserve0;
        uint _reserve1 = reserve1;
        IOutcomeToken(token0).transfer(_creator, _reserve0);
        IOutcomeToken(token1).transfer(_creator, _reserve1);
        reserve0 = 0;
        reserve1 = 0;
    }
}


/* 
1. Reduce market contract size
2. Adjust the rest according to new market.sol
3. Test gas cost of functions
4. writr sub grahs */