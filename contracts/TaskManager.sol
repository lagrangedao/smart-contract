// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title 
 * @author 
 * @notice 
 * 1. Lagrange will add Task to contract
 * 2. User and CP will lock tokens to contract
 * 3. After CP completes task, there will be a refund window
 * 4. If the user makes a refund claim within the refund window, Lagrange will validate the claim
 * 5. After the claim window, the CP can claim the user's revenue and unlock collateral
 */
contract TaskManager is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    struct Task {
        address user;
        address assignedCP;
        uint startTimestamp;
        uint taskDuration;
        uint taskDeadline;
        uint refundDeadline;

        uint revenue;
        uint lockedRevenue;
        uint lockedCollateral;
        bool processingRefundClaim;
    }

    mapping(string => Task) public tasks;
    mapping(address => bool) public isAdmin;

    IERC20 public token;
    uint public refundClaimDuration;

    event RevenueLocked(string taskId, address indexed user, uint revenue);
    event CollateralLocked(string taskId, address indexed cp, uint collateral);
    event TaskAccepted(string taskId, address indexed cp);
    event TaskTerminated(string taskId, uint timestamp);
    event TaskCompleted(string taskId, uint claimDeadline);
    event RefundSubmitted(string taskId, address indexed user);
    event ClaimResult(string taskId, bool isClaimValid);
    event RevenueCollected(string taskId, uint revenue);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address tokenAddress) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();

        token = IERC20(tokenAddress);
        isAdmin[msg.sender] = true;

        refundClaimDuration = 3 days;
    }

    // Modifier to check if the caller is the admin
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only the admin can call this function.");
        _;
    }

    function lockRevenue(string memory taskId, uint duration, uint revenue) public {
        require(tasks[taskId].lockedRevenue == 0, "task already requested");
        require(token.balanceOf(msg.sender) >= revenue, "Insufficient funds.");
        require(token.allowance(msg.sender, address(this)) >= revenue, "Approve spending funds.");

        bool transferSuccess = token.transferFrom(msg.sender, address(this), revenue);
        require(transferSuccess, "Token transfer failed");

        tasks[taskId].user = msg.sender;
        tasks[taskId].taskDuration = duration;
        tasks[taskId].lockedRevenue = revenue;

        emit RevenueLocked(taskId, msg.sender, revenue);
    }

    function assignTask(string memory taskId, address cp, uint collateral) public onlyAdmin {
        tasks[taskId].assignedCP = cp;
        tasks[taskId].lockedCollateral = collateral;
    }

    function lockCollateral(string memory taskId) public {
        require(tasks[taskId].startTimestamp == 0, "task already accepted");
        require(token.balanceOf(msg.sender) >= tasks[taskId].lockedCollateral, "Insufficient funds.");
        require(token.allowance(msg.sender, address(this)) >= tasks[taskId].lockedCollateral, "Approve spending funds.");

        bool transferSuccess = token.transferFrom(msg.sender, address(this), tasks[taskId].lockedCollateral);
        require(transferSuccess, "Token transfer failed");

        tasks[taskId].startTimestamp = block.timestamp;
        tasks[taskId].taskDeadline = block.timestamp + tasks[taskId].taskDuration;

        emit CollateralLocked(taskId, msg.sender, tasks[taskId].lockedCollateral);
        emit TaskAccepted(taskId, msg.sender);
    }

    function terminateTask(string memory taskId) public {
        require(tasks[taskId].assignedCP == msg.sender || tasks[taskId].user == msg.sender, "task is not assigned to caller");

        uint returnedRevenue = tasks[taskId].lockedRevenue;
        uint returnedCollateral = tasks[taskId].lockedCollateral;
    
        uint elaspedDuration = block.timestamp - tasks[taskId].startTimestamp;

        tasks[taskId].lockedRevenue = 0;
        tasks[taskId].lockedCollateral = 0;

       //TODO: slashing rules

        if (tasks[taskId].user == msg.sender) {
            uint collectedRevenue = returnedRevenue * (elaspedDuration / tasks[taskId].taskDuration);

            token.transfer(msg.sender, returnedRevenue - collectedRevenue);
            token.transfer(tasks[taskId].assignedCP, returnedCollateral + collectedRevenue);
        } else if (msg.sender == tasks[taskId].assignedCP) {
            token.transfer(tasks[taskId].user, returnedRevenue);
            // slash collateral
        }

        emit TaskTerminated(taskId, block.timestamp);
    }

    function completeTask(string memory taskId) public onlyAdmin {
        require(block.timestamp < tasks[taskId].taskDeadline, "task deadline passed");
        require(tasks[taskId].refundDeadline == 0, "task already completed");

        tasks[taskId].refundDeadline = block.timestamp + refundClaimDuration;

        emit TaskCompleted(taskId, tasks[taskId].refundDeadline);
    }

    function requestRefund(string memory taskId) public {
        require(tasks[taskId].user == msg.sender, "sender cannot claim this task");
        require(block.timestamp < tasks[taskId].refundDeadline, "not within claim window");

        tasks[taskId].processingRefundClaim = true;

        // track remaining time to unlock
        tasks[taskId].refundDeadline = tasks[taskId].refundDeadline - block.timestamp;

        emit RefundSubmitted(taskId, msg.sender);
    }

    function validateClaim(string memory taskId, bool isClaimValid) public onlyAdmin {
        require(tasks[taskId].processingRefundClaim, "no claim submitted for this task");
        if (isClaimValid) {
            uint returnedRevenue = tasks[taskId].lockedRevenue;
            tasks[taskId].lockedRevenue = 0;
            token.transfer(msg.sender, returnedRevenue);
        } 

        tasks[taskId].refundDeadline += block.timestamp;
        tasks[taskId].processingRefundClaim = false;

        emit ClaimResult(taskId, isClaimValid);
    }

    function collectRevenue(string memory  taskId) public {
        require(tasks[taskId].assignedCP == msg.sender, "task is not assigned to caller");
        require(block.timestamp > tasks[taskId].refundDeadline, "wait for claim deadline");
        require(!tasks[taskId].processingRefundClaim, "claim under review");

        uint revenue = tasks[taskId].lockedRevenue;
        uint returnAmount = revenue + tasks[taskId].lockedCollateral;
        tasks[taskId].lockedRevenue = 0;
        tasks[taskId].lockedCollateral = 0;
        token.transfer(msg.sender, returnAmount);

        emit RevenueCollected(taskId, revenue);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function version() public pure returns(uint) {
        return 1;
    }
}