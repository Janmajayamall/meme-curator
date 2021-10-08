pragma solidity ^0.8.0;

library Math {
    function isValidAmountCRoot(uint a0, uint a1, uint r0, uint r1, uint a, bool buy) internal pure returns (bool){
        if (buy == true){
            if((r0 + a - a0) > 0 && (r1 + a - a1) > 0){
                return true;
            }
            return false;
        }else{
            if((r0 + a0 - a) > 0 && (r1 + a1 - a) > 0){
                return true;
            }
            return false;
        }
    }

    function getAmountCToBuyTokens(uint a0, uint a1, uint r0, uint r1) internal pure returns (uint a){
        uint b;
        uint sign;
        if ((r0 + r1) >= (a0 + a1)){
            b = (r0 + r1) - (a0 + a1);
            sign = 1;
        }else {
            b = (a0 + a1) - (r0 + r1);
            sign = 0;
        }
        uint b2 = b**2;
        uint rootVal = b2 + (4 * r0 * a1) + (4 * r1 * a0) - (4 * a0 * a1);
        rootVal = sqrt(rootVal);
        if (sign == 0){
            a = ((b + rootVal) / 2);
            if (!isValidAmountCRoot(a0, a1, r0, r1, a, true)){
                require(b >= rootVal, 'ERR rootVal>b sign=0');
                a = ((b - rootVal)/2);
            }
        }else {
            require(rootVal >= b, 'ERR b>rootVal sign=1');
            a = ((rootVal - b)/2);
        }
    }

    function getAmountCBySellTokens(uint a0, uint a1, uint r0, uint r1) internal pure returns (uint a) {
        uint nveB = r0 + a0 + r1 + a1;
        uint c = (r0*a1) + (r1*a0) + (a0*a1);
        uint rootVal = ((nveB**2) - (4 * c));
        rootVal = sqrt(rootVal);
        a = ((nveB+rootVal)/2);
        if (!isValidAmountCRoot(a0, a1, r0, r1, a, false)){
            require(nveB >= rootVal, 'ERR');
            a = (nveB - rootVal)/2;
        }
    }

    /// @notice computes square roots using the babylonian method - https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
    function sqrt(uint256 x) internal pure returns (uint256) {
        // Taken from - https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/Babylonian.sol

        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}