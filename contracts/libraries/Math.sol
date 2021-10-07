pragma solidity ^0.8.0;

library Math {
    
    /// @notice Solves quadratic equations
    /// @dev Should only be called for equations with real roots (eg. 10 = (4 + x)*(5+x))
    /// @param a a in qudratic formula
    /// @param b b in qudratic formula
    /// @param c c in qudratic formula
    function quadraticEq(int a, int b, int c) internal pure returns (int val1, int val2) {
        int underRoot = int(sqrt(uint((b**2)-((4*a)*c))));
        val1 = ((-1*b) + underRoot) / (2*a);
        val2 = ((-1*b) - underRoot) / (2*a);
    }

    /// @notice computes square roots using the babylonian method - https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
    // Taken from - https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/Babylonian.sol
    function sqrt(uint256 x) internal pure returns (uint256) {
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