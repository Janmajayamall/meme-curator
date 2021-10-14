// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './interfaces/IERC20.sol';
import './libraries/ERC20.sol';

contract MemeToken is ERC20 {

    address public immutable owner;

    constructor () ERC20('MemeToken', 'MT') {
        owner = msg.sender;
    }

    function mint(address to, uint256 amount) public {
        require(owner == msg.sender);
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        require(owner == msg.sender);
        _burn(address(this), amount);
    }
}
