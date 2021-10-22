// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Math {
    function getAmountCToBuyTokens(uint a0, uint a1, uint r0, uint r1) internal pure returns (uint a){
        uint b;
        uint rootVal;
        uint s;
        assembly {
            if iszero(and(lt(a0,0x1000000000000000000000000000000),lt(a1,0x1000000000000000000000000000000))) {
                revert(0,0)
            }
            if iszero(and(lt(r0,0x1000000000000000000000000000000),lt(r1,0x1000000000000000000000000000000))) {
                revert(0,0)
            }
            {
                let r0Pr1 := add(r0,r1)
                let a0Pa1 := add(a0,a1)
                switch lt(r0Pr1, a0Pa1)
                case 1 {
                    s := 0
                    b := sub(a0Pa1,r0Pr1)
                }
                case 0 {
                    s := 1
                    b := sub(r0Pr1,a0Pa1)
                }
            }
            let g := mul(b,b)
            rootVal := sub(add(mul(b,b), mul(4, add(mul(r0,a1), mul(r1,a0)))), mul(4, mul(a0,a1)))
        }
        rootVal = sqrt(rootVal);
        assembly {
            {
                switch iszero(s) 
                case 1 {
                    a := div(add(b,rootVal), 2)
                    if or(lt(add(r0,a),a0), lt(add(r1,a),a1)){
                        if lt(b, rootVal) {revert(0,0)}
                        a := div(sub(b,rootVal),2)
                    }
                }
                case 0 {
                    if lt(rootVal,b) {revert(0,0)}
                    a := div(sub(rootVal,b),2)
                }
            }
            a := add(a,1)
        }

        // uint b;
        // uint sign;
        // if ((r0 + r1) >= (a0 + a1)){
        //     b = (r0 + r1) - (a0 + a1);
        //     sign = 1;
        // }
        // else {
        //     b = (a0 + a1) - (r0 + r1);
        //     sign = 0;
        // }
        // uint b2 = b**2;
        // uint rootVal = b2 + (4 * r0 * a1) + (4 * r1 * a0) - (4 * a0 * a1);
        // rootVal = sqrt(rootVal);
        // if (sign == 0){
        //     a = ((b + rootVal) / 2);
        //     if (!isValidAmountCRoot(a0, a1, r0, r1, a, true)){
        //         require(b >= rootVal, 'ERR rootVal>b sign=0');
        //         a = ((b - rootVal)/2);
        //     }
        // }else {
        //     require(rootVal >= b, 'ERR b>rootVal sign=1');
        //     a = ((rootVal - b)/2);
        // }
        // a += 1;
    }

    function getTokenAmountToBuyWithAmountC(uint fixedTokenAmount, uint fixedTokenIndex, uint r0, uint r1, uint a) internal pure returns (uint tokenAmount){
        assembly {
            if iszero(and(lt(a,0x1000000000000000000000000000000),lt(fixedTokenAmount,0x1000000000000000000000000000000))) {
                revert(0,0)
            }
            if iszero(and(lt(r0,0x1000000000000000000000000000000),lt(r1,0x1000000000000000000000000000000))) {
                revert(0,0)
            }

            if gt(fixedTokenIndex, 1) {revert(0,0)}
            let x
            let y
            {
                switch fixedTokenIndex
                case 0 {
                    if iszero(lt(fixedTokenAmount,add(r0,a))) {revert(0,0)}
                    x := add(r1,a)
                    y := div(mul(r1,r0),sub(add(r0,a),fixedTokenAmount))
                }
                case 1 {
                    if iszero(lt(fixedTokenAmount,add(r1,a))) {revert(0,0)}
                    x := add(r0,a)
                    y := div(mul(r0,r1),sub(add(r1,a),fixedTokenAmount))
                }
            }
            if eq(lt(y,x),0) {revert(0,0)}
            tokenAmount := sub(sub(x,y),1)
        }
        // require(fixedTokenIndex < 2);
        // uint x;
        // uint y;
        // if(fixedTokenIndex == 0){
        //     // find a1
        //     x = r1 + a;
        //     require(r0 + a >= fixedTokenAmount, "INVALID");
        //     y = (r0 * r1)/(r0 + a - fixedTokenAmount);
        // }else{
        //     x = r0 + a;
        //     require(r1 + a >= fixedTokenAmount, "INVALID");
        //     y = (r0 * r1)/(r1 + a - fixedTokenAmount);
        // }

        // y += 1;
        // require(x > y, "INVALID INPUTS");
        // tokenAmount = x - y;
        // tokenAmount -= 1;
    }


    function getAmountCBySellTokens(uint a0, uint a1, uint r0, uint r1) internal pure returns (uint a) {
        uint nveB;
        uint rV;
        assembly {   
            if iszero(and(lt(a0,0x1000000000000000000000000000000),lt(a1,0x1000000000000000000000000000000))) {
                revert(0,0)
            }
            if iszero(and(lt(r0,0x1000000000000000000000000000000),lt(r1,0x1000000000000000000000000000000))) {
                revert(0,0)
            }

            nveB := add(r0,add(a0, add(r1,a1)))
            rV := sub(mul(nveB, nveB), mul(4, add(mul(r0,a1), add(mul(r1,a0), mul(a0,a1))))) 
        }
        rV = sqrt(rV);
        assembly {
            a := div(add(nveB, rV), 2)
            if or(lt(add(r0,a0), a),lt(add(r1,a1), a)) {
                if lt(nveB, rV) {revert(0,0)}
                a := div(sub(nveB, rV),2)
            }
            a := sub(a,1)
        }
        // uint nveB = r0 + a0 + r1 + a1;
        // uint c = (r0*a1) + (r1*a0) + (a0*a1);
        // uint rootVal = ((nveB**2) - (4 * c));
        // rootVal = sqrt(rootVal);
        // a = (nveB + rootVal)/2;
        // if (!isValidAmountCRoot(a0, a1, r0, r1, a, false)){
        //     require(nveB > rootVal, 'ERR');
        //     a = (nveB - rootVal)/2;
        // }
        // a -= 1;
    }

    function getTokenAmountToSellForAmountC(uint fixedTokenAmount, uint fixedTokenIndex, uint r0, uint r1, uint a) internal pure returns (uint tokenAmount){
        assembly {
            if iszero(and(lt(a,0x1000000000000000000000000000000),lt(fixedTokenAmount,0x1000000000000000000000000000000))) {
                revert(0,0)
            }
            if iszero(and(lt(r0,0x1000000000000000000000000000000),lt(r1,0x1000000000000000000000000000000))) {
                revert(0,0)
            }

            if gt(fixedTokenIndex, 1) {revert(0,0)}
            let x
            let y
            {
                switch fixedTokenIndex 
                case 0 {
                    if iszero(lt(a,add(r0,fixedTokenAmount))) {revert(0,0)}
                    x := r1
                    y := div(mul(r0,r1),sub(add(r0,fixedTokenAmount),a))
                }
                case 1 {
                    if iszero(lt(a,add(r1,fixedTokenAmount))) {revert(0,0)}
                    x := r0
                    y := div(mul(r0,r1),sub(add(r1,fixedTokenAmount),a))
                }
            }
            y := add(y,a)
            if gt(x,y) {revert(0,0)}
            tokenAmount := add(sub(y,x),1)
        }
        // require(fixedTokenIndex < 2);
        // uint x;
        // uint y;
        // if(fixedTokenIndex == 0){
        //     x = r1;
        //     require(r0 + fixedTokenAmount > a, "INVALID");
        //     y = ((r0 * r1)/(r0 + fixedTokenAmount - a)) + a;
        // }else{
        //     x = r0;
        //     require(r1 + fixedTokenAmount > a, "INVALID");
        //     y = ((r0 * r1)/(r1 + fixedTokenAmount - a)) + a;
        // }

        // require(y >= x, "INVALID INPUTS");
        // tokenAmount = y - x;
        // tokenAmount += 1;
    }


    function sqrt(uint256 x) internal pure returns (uint256 n) {
        assembly {
            if iszero(x) {revert(0,0)}
            let xx := x
            let r := 1
            if gt(xx, 0x100000000000000000000000000000000) {
                xx := shr(128,xx)
                r := shl(64,r)
            }
            if gt(xx, 0x10000000000000000) {
                xx := shr(64,xx)
                r := shl(32,r)
            }
            if gt(xx, 0x100000000) {
                xx := shr(32,xx)
                r := shl(16,r)
            }
            if gt(xx, 0x10000) {
                xx := shr(16,xx)
                r := shl(8,r)
            }
            if gt(xx, 0x100) {
                xx := shr(8,xx)
                r := shl(4,r)
            }
            if gt(xx, 0x10) {
                xx := shr(4,xx)
                r := shl(2,r)
            }
            if gt(xx, 0x8) {
                r := shl(1,r)
            }

            // for {let i:=0} lt(i,7) {i := add(i,1)}
            // {
            //     r := shr(div(add(r,x),r),1)
            // }
            r := shr(1,add(r,div(x,r)))
            r := shr(1,add(r,div(x,r)))
            r := shr(1,add(r,div(x,r)))
            r := shr(1,add(r,div(x,r)))
            r := shr(1,add(r,div(x,r)))
            r := shr(1,add(r,div(x,r)))
            r := shr(1,add(r,div(x,r))) // Seven iterations should be enough

            {
                switch lt(r, div(x,r))
                case 1 {
                    n := r
                }
                case 0 {
                    n := div(x,r)
                }
            }
        }
    }

    function test_check() external {
        uint256 g = 101010001010101000101010100010101010001010101010101010;

    }
}