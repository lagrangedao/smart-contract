// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


contract Task is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    address user;
    address[] cpList;
    address arWallet;
    address apWallet;
    address rewardToken;
    address collateralToken;
    uint reward;
    uint collateral;
    uint duration;
    uint startTime;

    modifier onlyUser() {
        require(msg.sender == user, 'caller is not the user address');
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address userAddress, address[] memory cpAddresses, address arAddress, address apAddress, uint rewardAmount, uint collateralAmount, uint duration_) public initializer{ 
        user = userAddress;
        cpList = cpAddresses;
        arWallet = arAddress;
        apWallet = apAddress;
        reward = rewardAmount;
        collateral = collateralAmount;
        duration = duration_;

        startTime = block.timestamp;
    }

    function terminateTask() public onlyUser {
        uint refundableReward = reward;
        uint refundableCollateral = collateral;
        uint elaspedDuration = block.timestamp - startTime;

        reward = 0;
        collateral = 0;

        uint rewardSubtotal = reward * (elaspedDuration / duration);
        uint rewardFee = rewardSubtotal * 5 / 100;
        uint rewardToCp = rewardSubtotal - rewardFee;

        // rewardToken.transfer();
        // paymentToken.transferFrom();
    }
    
    // function completeTask() public {}
    // function requestRefund() public {}
    // function validateRefund() public {}
    // function claimReward() public {}

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function version() public pure returns(uint) {
        return 1;
    }
}