// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './../libraries/Math.sol';
import 'hardhat/console.sol';

contract MathTest {

    uint public reserve0;
    uint public reserve1;

    uint public balance0;
    uint public balance1;

    function fund(uint amount) external {
        reserve0 += amount;
        reserve1 += amount;
    }

    /* 
    Log functions
     */
    function logReserves() internal view {
        console.log("Reserves before r0 - %s, r1 -  %s & rP - %s ", reserve0, reserve1, reserve0*reserve1);
    }

    function logAmounts(uint a0, uint a1, uint a) internal view {
    console.log("Amounts a0 - %s, a1 -  %s, a - %s", a0, a1, a);
    }

    function buy(uint a0, uint a1, uint a) external {
        console.log("\n Buy starts **************************");
        logAmounts(a0, a1, a);
        logReserves();
        require(
            (reserve0 * reserve1) <= (reserve0 + a - a0) * (reserve1 + a - a1), 
            "INVALID INPUTS"
        );
        reserve0 = reserve0 + a - a0;
        reserve1 = reserve1 + a - a1;
        balance0 += a0;
        balance1 += a1;
        logReserves();
        console.log("Buy ends ************************** \n");
    }

    function sell(uint a0, uint a1, uint a) external {
        console.log("\n Sell starts **************************");
        logAmounts(a0, a1, a);
        logReserves();
        require(
            (reserve0 * reserve1) <= (reserve0 + a0 - a) * (reserve1 + a1 - a),
            "INVALID INPUTS"
        );
        reserve0 = reserve0 + a0 - a;
        reserve1 = reserve1 + a1 - a;
        balance0 -= a0;
        balance1 -= a1;
        logReserves();
        console.log("\n Sell ends **************************");
    }

    function getReserves() external view returns (uint, uint){
        return (reserve0, reserve1);
    }

    function getBalances() external view returns (uint, uint){
        return (balance0, balance1);
    }

    function getAmountCToBuyTokens(uint a0, uint a1, uint r0, uint r1) external pure returns (uint) {
        uint amount = Math.getAmountCToBuyTokens(a0, a1, r0, r1);
        return amount;
    }

    function getTokenAmountToBuyWithAmountC(uint fixedTokenAmount, uint fixedTokenIndex, uint r0, uint r1, uint a) external pure returns (uint){
        uint amount = Math.getTokenAmountToBuyWithAmountC(fixedTokenAmount, fixedTokenIndex, r0, r1, a);
        return amount;
    }

    function getAmountCBySellTokens(uint a0, uint a1, uint r0, uint r1) external pure returns (uint){
        uint amount = Math.getAmountCBySellTokens(a0, a1, r0, r1);
        return amount;
    }

    function getTokenAmountToSellForAmountC(uint fixedTokenAmount, uint fixedTokenIndex, uint r0, uint r1, uint a) external view returns (uint){
        uint amount = Math.getTokenAmountToSellForAmountC(fixedTokenAmount, fixedTokenIndex, r0, r1, a);
        return amount;
    }


}