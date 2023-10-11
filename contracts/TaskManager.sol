// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title 
 * @author 
 * @notice 
 * 1. User requests CP and locks revenue
 * 2. Server will assign task to CP
 * 3. CP will acceptTask and lock collateral
 * 4. CP can terminateTask and lose revenue
 * 5. After task complete, user has claim window
 * 6. If the claim is validated, CP collateral gets slashed
 * 7. Otherwise, CP can claim revenue
 */
contract TaskManager is Ownable {

    struct Task {
        address user;
        uint start;
        uint taskDeadline;
        uint claimDeadline;
        uint lockedRevenue;
        uint lockedCollateral;
        bool claimSubmitted;
    }

    mapping(bytes32 => Task) public tasks;
    mapping(bytes32 => address) public assignedCp;

    IERC20 revenueToken;
    uint public revenue;
    uint public collateral;
    uint public userClaimWindow;
    uint public taskDuration;

    constructor(address token) {
        revenueToken = IERC20(token);
    }

    function requestCP(bytes32 taskId) public {
        revenueToken.transferFrom(msg.sender, address(this), revenue);
        tasks[taskId].user = msg.sender;
        tasks[taskId].lockedRevenue = revenue;
    }

    function assignTask(bytes32 taskId, address computingProvider) public onlyOwner {
        assignedCp[taskId] = computingProvider;
    }

    function acceptTask(bytes32 taskId) public {
        require(assignedCp[taskId] == msg.sender, "task is not assigned to caller");

        // lock collateral
        revenueToken.transferFrom(msg.sender, address(this), collateral);

        tasks[taskId].start = block.timestamp;
        tasks[taskId].taskDeadline = block.timestamp + taskDuration;
        tasks[taskId].lockedCollateral = collateral;
    }

    function terminateTask(bytes32 taskId) public {
        require(assignedCp[taskId] == msg.sender, "task is not assigned to caller");

        uint returnedRevenue = tasks[taskId].lockedRevenue;
        uint returnedCollateral = tasks[taskId].lockedCollateral;

        tasks[taskId].lockedRevenue = 0;
        tasks[taskId].lockedCollateral = 0;

        revenueToken.transferFrom(address(this),  tasks[taskId].user, returnedRevenue);
        revenueToken.transferFrom(address(this),  msg.sender, returnedCollateral);
    }

    function completeTask(bytes32 taskId) public {
        require(assignedCp[taskId] == msg.sender, "task is not assigned to caller");
        require(block.timestamp < tasks[taskId].taskDeadline, "task deadline passed");
        require(tasks[taskId].claimDeadline == 0, "task already completed");

        tasks[taskId].claimDeadline = block.timestamp + userClaimWindow;
    }

    function submitClaim(bytes32 taskId) public {
        require(tasks[taskId].user == msg.sender, "sender cannot claim this task");
        require(block.timestamp < tasks[taskId].claimDeadline, "not within claim window");

        tasks[taskId].claimSubmitted = true;
    }

    function collectRevenue(bytes32 taskId) public {
        require(assignedCp[taskId] == msg.sender, "task is not assigned to caller");
        require(block.timestamp > tasks[taskId].claimDeadline, "wait for claim deadline");
        require(!tasks[taskId].claimSubmitted, "claim under review");

        uint returnedRevenue = tasks[taskId].lockedRevenue;
        tasks[taskId].lockedRevenue = 0;
        revenueToken.transferFrom(address(this),  msg.sender, returnedRevenue);
    }
}