// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './interfaces/IERC20.sol';
import './libraries/ERC20.sol';


contract OutcomeToken is ERC20 {
    address public immutable market;

    constructor (address owner) ERC20("OutcomeToken", "OT") {
        market = owner;
    }

    function issue(address to, uint256 amount) public {
        require(msg.sender == market);
        _mint(to, amount);
    }

    function revoke(address from, uint256 amount) public {
        require(msg.sender == market);
        _burn(from, amount);
    }
}