// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SwanToken is Ownable, ERC20Capped {
    uint public constant TOKEN_CAP = 1 ether * 10 ** 9;

    constructor() ERC20("Swan Token", "SWAN") ERC20Capped(TOKEN_CAP) {}

    function mint(address to, uint amount) public onlyOwner {
        _mint(to, amount);
    }
}