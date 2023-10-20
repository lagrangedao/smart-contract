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
        uint taskDuration;
        uint taskDeadline;
        uint claimDeadline;
        uint lockedRevenue;
        uint lockedCollateral;
        bool claimSubmitted;
    }

    mapping(string => Task) public tasks;
    mapping(string => address) public assignedCp;
    mapping(address => bool) public isAdmin;

    IERC20 public revenueToken;
    uint public userClaimWindow;

    event RevenueLocked(string taskId, address indexed user, uint revenue);
    event TaskAssigned(string taskId, address indexed cp);
    event TaskAccepted(string taskId, address indexed cp, uint collateral);
    event TaskTerminated(string taskId, uint returnedRevenue, uint returnedCollateral);
    event TaskCompleted(string taskId, uint claimDeadline);
    event RefundSubmitted(string taskId, address indexed user);
    event RevenueCollected(string taskId, uint revenue);
    event ClaimResult(string taskId, bool isClaimValid);


    constructor(address token) {
        revenueToken = IERC20(token);
        isAdmin[msg.sender] = true;
    }

    // Modifier to check if the caller is the admin
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only the admin can call this function.");
        _;
    }

    function setAdmin(address admin, bool status) public onlyOwner {
        isAdmin[admin] = status;
    }

    function lockRevenue(string memory taskId, uint revenue) public {
        require(tasks[taskId].lockedRevenue == 0, "task already requested");
        require(revenueToken.balanceOf(msg.sender) >= revenue, "Insufficient funds.");
        require(revenueToken.allowance(msg.sender, address(this)) >= revenue, "Approve spending funds.");

        bool transferSuccess = revenueToken.transferFrom(msg.sender, address(this), revenue);
        require(transferSuccess, "Token transfer failed");

        tasks[taskId].user = msg.sender;
        tasks[taskId].lockedRevenue = revenue;

        emit RevenueLocked(taskId, msg.sender, revenue);
    }

    function lockCollateral(string memory taskId) public {
        require(assignedCp[taskId] == msg.sender, "task is not assigned to caller");
        require(tasks[taskId].start == 0, "task already accepted");

        // lock collateral
        bool transferSuccess = revenueToken.transferFrom(msg.sender, address(this), tasks[taskId].lockedCollateral);
        require(transferSuccess, "Token transfer failed");

        tasks[taskId].start = block.timestamp;
        tasks[taskId].taskDeadline = block.timestamp + tasks[taskId].taskDuration;

        emit TaskAccepted(taskId, msg.sender, tasks[taskId].lockedCollateral);
    }

    function terminateTask(string memory taskId) public {
        require(assignedCp[taskId] == msg.sender || tasks[taskId].user == msg.sender, "task is not assigned to caller");

        uint returnedRevenue = tasks[taskId].lockedRevenue;
        uint returnedCollateral = tasks[taskId].lockedCollateral;
    
        uint elaspedDuration = block.timestamp - tasks[taskId].start;

        tasks[taskId].lockedRevenue = 0;
        tasks[taskId].lockedCollateral = 0;

       //TODO: slashing rules

        if (tasks[taskId].user == msg.sender) {
        
            revenueToken.transfer(msg.sender, returnedCollateral);
        }

        revenueToken.transfer(tasks[taskId].user, returnedRevenue);
        revenueToken.transfer(msg.sender, returnedCollateral);

        emit TaskTerminated(taskId, returnedRevenue, returnedCollateral);
    }

    function completeTask(string memory taskId) public onlyAdmin {
        require(block.timestamp < tasks[taskId].taskDeadline, "task deadline passed");
        require(tasks[taskId].claimDeadline == 0, "task already completed");

        tasks[taskId].claimDeadline = block.timestamp + userClaimWindow;

        emit TaskCompleted(taskId, tasks[taskId].claimDeadline);
    }

    function submitClaim(string memory  taskId) public {
        require(tasks[taskId].user == msg.sender, "sender cannot claim this task");
        require(block.timestamp < tasks[taskId].claimDeadline, "not within claim window");

        tasks[taskId].claimSubmitted = true;

        emit RefundSubmitted(taskId, msg.sender);
    }

    function validateClaim(string memory taskId, bool isClaimValid) public onlyAdmin {
        require(tasks[taskId].claimSubmitted, "no claim submitted for this task");
        if (isClaimValid) {
            uint returnedRevenue = tasks[taskId].lockedRevenue;
            tasks[taskId].lockedRevenue = 0;
            revenueToken.transfer(msg.sender, returnedRevenue);
        } else {
            tasks[taskId].claimSubmitted = false;
        }

        emit ClaimResult(taskId, isClaimValid);
    }

    function collectRevenue(string memory  taskId) public {
        require(assignedCp[taskId] == msg.sender, "task is not assigned to caller");
        require(block.timestamp > tasks[taskId].claimDeadline, "wait for claim deadline");
        require(!tasks[taskId].claimSubmitted, "claim under review");

        uint revenue = tasks[taskId].lockedRevenue;
        uint returnAmount = revenue + tasks[taskId].lockedCollateral;
        tasks[taskId].lockedRevenue = 0;
        tasks[taskId].lockedCollateral = 0;
        revenueToken.transfer(msg.sender, returnAmount);

        emit RevenueCollected(taskId, revenue);
    }

    function setUserClaimWindow(uint duration) public onlyOwner {
        userClaimWindow = duration;
    }
}