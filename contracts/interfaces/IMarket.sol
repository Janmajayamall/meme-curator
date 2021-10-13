// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMarket {

    function getReservesTokenC() external view returns (uint, uint, uint);
    function getReservesOTokens() external view returns (uint, uint);
    function getAddressOfTokens() external view returns (address, address, address);
    function getStake(address _of, uint _for) external view returns (uint);
    function getStaking() external view returns (uint, uint, address, address);

    function fund() external;
    function buy(uint amount0, uint amount1, address to) external;   
    function sell(uint amount, address to) external;
    function redeemWinning(uint _for, address to) external;
    function stakeOutcome(uint _for, address to) external;
    function redeemStake(uint _for) external;
    function setOutcome(uint _outcome) external;

    event MarketFunded(address market, uint reserve0, uint reserve1, uint reserveC);
    event OutcomeBought(address market, address by, uint amountCIn, uint amount0Out, uint amount1Out, uint reserve0, uint reserve1);
    event OutcomeSold(address market, address by, uint amount0In, uint amount1In, uint amountCOut, uint reserve0, uint reserve1);
    event WinningRedeemed(address mmarket, address by, uint _for, uint amountTIn, uint outcome);
    event OutcomeStaked(address market, address by, uint _for, uint amountCIn);
    event StakeRedeemed(address market, address by, uint _for, uint amountCOut);
    event OracleSetOutcome(address market, uint outcome);
}
