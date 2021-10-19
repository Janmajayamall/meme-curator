// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMarket {

    enum Stages {
        MarketCreated,
        MarketFunded,
        MarketBuffer,
        MarketResolve,
        MarketClosed
    }

    struct Staking {
        uint amount0;
        uint amount1;
        address staker0;
        address staker1;
    }


    // function getReservesOTokens() external view returns (uint, uint);
    // function getAddressOfTokens() external view returns (address, address, address);
    // function staking() external view returns (uint, uint, address, address);
    // function getStake(address _of, uint _for) external view returns (uint);
    function getReservesTokenC() external view returns (uint);
    function tokenC() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function reserveC() external view returns (uint);
    function reserve0() external view returns (uint);
    function reserve1() external view returns (uint);
    function staking() external view returns (uint,uint,address,address);
    function stakes(uint, address) external view returns (uint);
    function outcome() external view returns (uint);
    function stage() external view returns (Stages);



    // function setOutcomeTokens(address _token0, address _token1) external;
    function fund() external;
    function buy(uint amount0, uint amount1, address to) external;   
    function sell(uint amount, address to) external;
    function redeemWinning(uint _for, address to) external;
    function stakeOutcome(uint _for, address to) external;
    function redeemStake(uint _for) external;
    function setOutcome(uint _outcome) external;

    event MarketCreated(
        address indexed market, 
        address indexed creator, 
        address indexed oracle, 
        bytes32 identifier,
        address tokenC
    );
    event MarketFunded(
        address indexed market, 
        uint reserve0, 
        uint reserve1, 
        uint reserveC,
        uint expireAtBlock,
        uint donBufferEndsAtBlock,
        uint donEscalationLimit,
        uint resolutionEndsAtBlock
    );
    event OutcomeBought(address indexed market, address indexed by, uint amountCIn, uint amount0Out, uint amount1Out, uint reserve0, uint reserve1);
    event OutcomeSold(address indexed market, address indexed by, uint amount0In, uint amount1In, uint amountCOut, uint reserve0, uint reserve1);
    event WinningRedeemed(address indexed market, address indexed by, uint _for, uint amountTIn, uint outcome);
    event OutcomeStaked(address indexed market, address indexed by, uint _for, uint amountCIn);
    event StakeRedeemed(address indexed market, address indexed by, uint _for, uint amountCOut);
    event OracleSetOutcome(address indexed market, uint outcome);
    event EscalationLimitReached(address indexed market, uint resolutionEndsAtBlock);
}
