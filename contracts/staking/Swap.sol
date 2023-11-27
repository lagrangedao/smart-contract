// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenSwap is Ownable {

    event USDCtoSWAN(address indexed sender, uint256 amountIn, uint256 amountOut);
    event SWANtoUSDC(address indexed sender, uint256 amountIn, uint256 amountOut);

    uint usdcToSwanRate = 1*10**13;
    IERC20 usdc = IERC20(0x0c1a5A0Cd0Bb4A9F564f09Cc66f4c921B560371a);
    IERC20 swan = IERC20(0x407a5856050053CF1DB54113bd9Ea9D2Eeee7C35);

    function swapUsdcToSwan(uint amountIn) public returns (uint amountOut){
        uint swanAmount = amountIn * usdcToSwanRate;

        require(swan.balanceOf(address(this)) >= swanAmount, "not enought balance in contract");

        usdc.transferFrom(msg.sender, address(this), amountIn);
        swan.transfer(msg.sender, swanAmount);

        return swanAmount;
    }

    function swapSwanToUsdc(uint amountIn) public returns (uint amountOut){
        uint usdcAmount = amountIn / usdcToSwanRate;

        require(usdc.balanceOf(address(this)) >= usdcAmount, "not enought balance in contract");

        swan.transferFrom(msg.sender, address(this), amountIn);
        usdc.transfer(msg.sender, usdcAmount);

        return usdcAmount;
    }
    
}