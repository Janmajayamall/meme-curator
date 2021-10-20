// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "./../../libraries/Math.sol";

contract GasMathTest is DSTest {

    function setUp() public {

    }
    function test_getAmountCToBuyTokens() public {
        // uint a0 = uint(_a0);
        // uint a1 = uint(_a1);
        // uint r0 = uint(_r0);
        // uint r1 = uint(_r1);
        // if (r0 == 0 || r1 == 0) return;
        uint a = Math.getAmountCToBuyTokens(
            1329227995784915872903807060280344574, 
            395898540111640672058452071334031554, 
            963657363776882618085741652757407931, 
            1329227995784915872903807060280344575
            );
        // assertGe((r0*r1), ((r0+a)-a0)*((r1+a)-a1));
    }

    // function test_sqrt() external {
    //     Math.sqrt(type(uint256).max);
    // }

    function test_getAmountCBySellTokens() public {
        uint a0 = uint(1);
        uint a1 = uint(1329227995784915872903807060280344575);
        uint r0 = uint(1329227995784915872903807060280344574);
        uint r1 = uint(1329227995784915872903807060280344575);
        if (r0 == 0 || r1 == 0) return;
        if (a0 == 0 && a1 == 0) return;
        uint a = Math.getAmountCBySellTokens(a0, a1, r0, r1);
        // emit log_named_uint("adada", a);
        // emit log_named_uint("121313", ((r0+a0)-a)*((r1+a1)-a));
        // emit log_named_uint("18301921", (r0*r1));
        // assertLe((r0*r1), ((r0+a0)-a)*((r1+a1)-a));
    }

    // function test_getTokenAmountToBuyWithAmountC(uint120 _r0, uint120 _r1, uint120 _a) public {
    //     uint a = uint(_a);
    //     uint r0 = uint(_r0);
    //     uint r1 = uint(_r1);
    //     if (r0 == 0 || r1 == 0 || a == 0) return;
    //     uint a0 = Math.getTokenAmountToBuyWithAmountC(0, 1, r0, r1, a);
    //     assertLe((r0*r1), ((r0+a)-a0)*(r1+a));
    // }

    // function test_getTokenAmountToSellForAmountC(uint120 _r0, uint120 _r1, uint120 _a) public {         
    //     uint a = uint(_a);
    //     uint r0 = uint(_r0);
    //     uint r1 = uint(_r1);
    //     if (r0 == 0 || r1 == 0) return;
    //     if (a >= r1) return;
    //     uint a0 = Math.getTokenAmountToSellForAmountC(0, 1, r0, r1, a);
    //     // assertLe((r0*r1), ((r0+a0)-a)*(r1-a));
    // }
}

//  test_getAmountCBySellTokens(uint120,uint120,uint120,uint120). Counterexample: (1329227995784915872903807060280344575, 1, 952670756597753243645152287621751804, 1125273963327064887518249884590249138)