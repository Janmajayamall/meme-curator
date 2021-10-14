// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import './../libraries/Math.sol';


contract MathTest is DSTest {

    function setUp() public {

    }

    function test_getAmountCToBuyTokens(uint112 _a0, uint112 _a1, uint112 _r0, uint112 _r1) public {
        uint minAmount = 10**18;
        uint a0 = uint(_a0);
        uint a1 = uint(_a1);
        uint r0 = uint(_r0);
        uint r1 = uint(_r1);
        if (a0 < minAmount || a1 < minAmount || r0 < minAmount || r1 < minAmount) return;
        uint a = Math.getAmountCToBuyTokens(a0, a1, r0, r1);
        assertLe((r0*r1), ((r0+a)-a0)*((r1+a)-a1));
    }

    function test_getAmountCBySellTokens(uint112 _a0, uint112 _a1, uint112 _r0, uint112 _r1) public {
        uint minAmount = 10**18;
        uint a0 = uint(_a0);
        uint a1 = uint(_a1);
        uint r0 = uint(_r0);
        uint r1 = uint(_r1);
        if (a0 < minAmount || a1 < minAmount || r0 < minAmount || r1 < minAmount) return;
        uint a = Math.getAmountCBySellTokens(a0, a1, r0, r1);
        assertLe((r0*r1), ((r0+a0)-a)*((r1+a1)-a));
    }
}
