// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Import the ERC20 token contract
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract SpacePaymentV3 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    // Address of the ERC20 token contract
    IERC20 public tokenContract;

    struct SpaceInfo {
        uint hardwareId;
        uint expiryDate;
    }

    struct Hardware {
        string name;
        uint pricePerHour;
        bool isActive;
    }

    // Mapping of admin(s)
    mapping(address => bool) public isAdmin;

    mapping(uint => Hardware) public hardwareInfo; // maps id => info
    mapping(string => SpaceInfo) public spaceInfo; // maps id => info
    mapping(address => mapping(string => uint)) public claimable; // maps wallet => id => claimable amount

    event HardwareSet(uint hardwareId, string name, uint hourlyRate, bool active);
    event PaymentMade(address spaceOwner, string spaceId, string hardware, uint numHours);
    event RefundSet(string refundId, address wallet, uint amount);
    event RefundClaimed(string refundId, address wallet, uint amount);
    event RewardSet(string taskId, address wallet, uint amount);
    event RewardClaimed(string taskId, address wallet, uint amount);

    event RevenueLocked(string taskId, address indexed user, uint revenue, uint duration);
    event CollateralLocked(string taskId, address indexed cp, uint collateral);
    event TaskCompleted(string taskId, uint timestamp);
    event RefundSubmitted(string taskId, address indexed user);
    event ClaimResult(string taskId, bool result);
    event RevenueCollected(string taskId, uint revenue);

    uint public refundClaimDuration;

    struct Task {
        address user;
        address cp;

        uint startTime;
        uint duration;
        uint taskDeadline;
        uint refundDeadline;

        uint revenue;
        uint collateral;
        bool processingRefundClaim;
    }

    mapping(string => Task) public tasks;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address token) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();

        tokenContract = IERC20(token);
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

     function setHardware(uint hardwareId, string memory name, uint hourlyRate, bool active) public onlyOwner {
        hardwareInfo[hardwareId] = Hardware(name, hourlyRate, active);
        emit HardwareSet(hardwareId, name, hourlyRate, active);
    }

    function setToken(address token) public onlyOwner {
        tokenContract = IERC20(token);
    }
    
    function setClaim(address wallet, string memory claimId, uint claimAmount) internal {
        claimable[wallet][claimId] = claimAmount;
    }

    function setRefund(string memory refundId, address wallet, uint refundAmount) public onlyAdmin {
        setClaim(wallet, refundId, refundAmount);
        emit RefundSet(refundId, wallet, refundAmount);
    }

    function setReward(string memory taskId, address cpWallet, uint rewardAmount) public onlyAdmin {
        setClaim(cpWallet, taskId, rewardAmount);
        emit RewardSet(taskId, cpWallet, rewardAmount);
    }

    function claim (address wallet, string memory claimId) internal returns(uint){
        uint claimAmount = claimable[wallet][claimId];
        require(claimAmount > 0, "Nothing to claim.");
        require(tokenContract.balanceOf(address(this)) >= claimAmount, "Claim currently unavailable");

        claimable[wallet][claimId] = 0;
        tokenContract.transfer(wallet, claimAmount);

        return claimAmount;
    }

    function claimRefund (string memory refundId) public {
        uint refundAmount = claim(msg.sender, refundId);
        emit RefundClaimed(refundId, msg.sender, refundAmount);
    }

    function claimReward (string memory taskId) public {
        uint refundAmount = claim(msg.sender, taskId);
        emit RewardClaimed(taskId, msg.sender, refundAmount);
    }

    // Make a payment for a space
    function makePayment(string memory spaceId, uint hardwareId, uint numHours) public {
        require(hardwareInfo[hardwareId].isActive, "Requested hardware is not supported.");

        uint price = hardwareInfo[hardwareId].pricePerHour * numHours;
        require(tokenContract.balanceOf(msg.sender) >= price, "Insufficient funds.");
        require(tokenContract.allowance(msg.sender, address(this)) >= price, "Approve spending funds.");

        // Transfer the payment to the admin wallet
        tokenContract.transferFrom(msg.sender, address(this), price);

        if (spaceInfo[spaceId].expiryDate <= block.timestamp) {
            // new space
            spaceInfo[spaceId] = SpaceInfo(hardwareId, block.timestamp + (numHours * 1 hours));
        } else {
            // TODO: extending space
            spaceInfo[spaceId].hardwareId = hardwareId;
            spaceInfo[spaceId].expiryDate +=  numHours * 1 hours;
        }

        emit PaymentMade(msg.sender, spaceId, hardwareInfo[hardwareId].name, numHours);
    }

    function withdraw(uint amount) public onlyOwner {
        tokenContract.transfer(msg.sender, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function version() public pure returns(uint) {
        return 3;
    }

    function setRefundClaimDuration(uint duration) public onlyAdmin {
        refundClaimDuration = duration;
    }

    function lockRevenue(string memory taskId, uint hardwareId, uint numHours) public {
        require(tasks[taskId].user == address(0), "task id already in use");
        require(hardwareInfo[hardwareId].isActive, "Requested hardware is not supported.");

        uint price = hardwareInfo[hardwareId].pricePerHour * numHours;
        require(tokenContract.balanceOf(msg.sender) >= price, "Insufficient funds.");
        require(tokenContract.allowance(msg.sender, address(this)) >= price, "Approve spending funds.");

        // Transfer the payment to the admin wallet
        tokenContract.transferFrom(msg.sender, address(this), price);

        tasks[taskId].user = msg.sender;
        tasks[taskId].duration = numHours * 1 hours;
        tasks[taskId].revenue = price;

        emit RevenueLocked(taskId, msg.sender, price, tasks[taskId].duration);
    }

    function assignTask(string memory taskId, address cp, uint collateral) public onlyAdmin {
        tasks[taskId].cp = cp;
        tasks[taskId].collateral = collateral;
    }

    function lockCollateral(string memory taskId) public {
        require(tasks[taskId].startTime == 0, "task already accepted");
        require(tokenContract.balanceOf(msg.sender) >= tasks[taskId].collateral, "Insufficient funds.");
        require(tokenContract.allowance(msg.sender, address(this)) >= tasks[taskId].collateral, "Approve spending funds.");

        tokenContract.transferFrom(msg.sender, address(this), tasks[taskId].collateral);

        tasks[taskId].startTime = block.timestamp;
        tasks[taskId].taskDeadline = block.timestamp + tasks[taskId].duration;

        emit CollateralLocked(taskId, msg.sender, tasks[taskId].collateral);
    }

    function terminateTask(string memory taskId) public {
        // TODO
    }

    function completeTask(string memory taskId) public onlyAdmin {
        require(block.timestamp < tasks[taskId].taskDeadline, "task deadline passed");
        require(tasks[taskId].refundDeadline == 0, "task already completed");

        tasks[taskId].refundDeadline = block.timestamp + refundClaimDuration;

        emit TaskCompleted(taskId, block.timestamp);
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
            uint returnedRevenue = tasks[taskId].revenue;
            tasks[taskId].revenue = 0;
            tokenContract.transfer(msg.sender, returnedRevenue);
        } 

        tasks[taskId].refundDeadline += block.timestamp;
        tasks[taskId].processingRefundClaim = false;

        emit ClaimResult(taskId, isClaimValid);
    }

    function collectRevenue(string memory taskId) public {
        require(tasks[taskId].cp == msg.sender, "task is not assigned to caller");
        require(block.timestamp > tasks[taskId].refundDeadline, "wait for claim deadline");
        require(!tasks[taskId].processingRefundClaim, "claim under review");

        uint revenue = tasks[taskId].revenue;
        uint returnAmount = revenue + tasks[taskId].collateral;
        tasks[taskId].revenue = 0;
        tasks[taskId].collateral = 0;
        tokenContract.transfer(msg.sender, returnAmount);

        emit RevenueCollected(taskId, revenue);
    }
}