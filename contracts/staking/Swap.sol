// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenSwap {

    uint public usdcToSwanRate = 10**13; // Make it public so it can be inspected
    IERC20 public usdc ;
    IERC20 public swan ;
    
    event USDCtoSWAN(address indexed sender, uint256 amountIn, uint256 amountOut);
    event SWANtoUSDC(address indexed sender, uint256 amountIn, uint256 amountOut);


    constructor() {
        usdc = IERC20(0x0c1a5A0Cd0Bb4A9F564f09Cc66f4c921B560371a);
        swan = IERC20(0x407a5856050053CF1DB54113bd9Ea9D2Eeee7C35);
    }

    function swapUsdcToSwan(uint amountIn) public returns (uint){
        uint swanAmount = amountIn * usdcToSwanRate;

        require(swan.balanceOf(address(this)) >= swanAmount, "not enough balance in contract");

        usdc.transferFrom(msg.sender, address(this), amountIn);
        swan.transfer(msg.sender, swanAmount);

        emit USDCtoSWAN(msg.sender, amountIn, swanAmount);

        return swanAmount;
    }

    function swapSwanToUsdc(uint amountIn) public returns (uint){
        uint usdcAmount = amountIn / usdcToSwanRate;

        require(usdc.balanceOf(address(this)) >= usdcAmount, "not enough balance in contract");

        swan.transferFrom(msg.sender, address(this), amountIn);
        usdc.transfer(msg.sender, usdcAmount);

        emit SWANtoUSDC(msg.sender, amountIn, usdcAmount);

        return usdcAmount;
    }
    
}