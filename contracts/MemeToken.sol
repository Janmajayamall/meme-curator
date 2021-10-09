// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './interfaces/IERC20.sol';
import './libraries/ERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract MemeToken is ERC20, Ownable {

    constructor () ERC20('dawdad', 'dwada') {
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
