// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract USDC is ERC20, Ownable {

    constructor() ERC20("USD Coin", "USDC") {
    }

    function decimals() override public pure returns(uint8) {
        return 6;
    }


    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}