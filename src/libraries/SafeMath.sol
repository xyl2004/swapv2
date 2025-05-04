// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// a library for performing overflow-safe math
// 在 Solidity 0.8.0+ 中，算术运算默认会进行溢出检查，但保留此库以兼容现有代码

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        return x + y;
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        return x - y;
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        return x * y;
    }
}
