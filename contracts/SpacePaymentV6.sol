// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// Import the ERC20 token contract
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract SpacePaymentV6 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    // Address of the ERC20 token contract
    IERC20 public paymentToken;

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

    event RevenueLocked(string spaceId, address indexed user, uint amountPaid, uint amountToEarn, uint duration);
    event CollateralLocked(string taskId, address indexed cp, uint collateral);
    event TaskCompleted(string taskId, uint timestamp);
    event RefundSubmitted(string taskId, address indexed user);
    event ClaimResult(string taskId, bool result);
    event RevenueCollected(string taskId, uint revenue);
    event TaskTerminated(string taskId, address terminator, uint timestamp);

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
        uint cpRevenue;
    }

    mapping(string => Task) public tasks;

    address public arWallet;
    address public apWallet;
    IERC20 public revenueToken;
    uint public paymentToRevenueRate;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address inToken, address outToken) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();

        paymentToken = IERC20(inToken);
        revenueToken = IERC20(outToken);
        isAdmin[msg.sender] = true;
    }

    // Modifier to check if the caller is the admin
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only the admin can call this function.");
        _;
    }

    /** SETTER FUNCTIONS */

    function setAdmin(address admin, bool status) public onlyOwner {
        isAdmin[admin] = status;
    }

     function setHardware(uint hardwareId, string memory name, uint hourlyRate, bool active) public onlyOwner {
        hardwareInfo[hardwareId] = Hardware(name, hourlyRate, active);
        emit HardwareSet(hardwareId, name, hourlyRate, active);
    }

    function setPaymentToken(address token) public onlyOwner {
        paymentToken = IERC20(token);
    }

    function setRevenueToken(address token) public onlyAdmin {
        revenueToken = IERC20(token);
    }

    function setConversionRate(uint rate) public onlyAdmin {
        paymentToRevenueRate = rate;
    }

    function setWallets(address newArWallet, address newApWallet) public onlyAdmin {
        arWallet = newArWallet;
        apWallet = newApWallet;
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

    /* CLAIM FUNCTIONS */

    function claim (address wallet, string memory claimId) internal returns(uint){
        uint claimAmount = claimable[wallet][claimId];
        require(claimAmount > 0, "Nothing to claim.");
        require(paymentToken.balanceOf(arWallet) >= claimAmount, "Claim currently unavailable");

        claimable[wallet][claimId] = 0;
        paymentToken.transferFrom(arWallet, wallet, claimAmount);

        return claimAmount;
    }

    function claimRefund (string memory refundId) public {
        uint refundAmount = claim(msg.sender, refundId);
        emit RefundClaimed(refundId, msg.sender, refundAmount);
    }

    function claimReward (string memory taskId) public {
        uint claimAmount = claimable[msg.sender][taskId];
        require(claimAmount > 0, "Nothing to claim.");
        require(revenueToken.balanceOf(apWallet) >= claimAmount, "Claim currently unavailable");

        claimable[msg.sender][taskId] = 0;
        revenueToken.transferFrom(apWallet, msg.sender, claimAmount);

        emit RewardClaimed(taskId, msg.sender, claimAmount);
        // require(tasks[taskId].cp == msg.sender, "task is not assigned to caller");
        // require(block.timestamp > tasks[taskId].refundDeadline, "wait for claim deadline");
        // require(!tasks[taskId].processingRefundClaim, "claim under review");

        // uint collateral = tasks[taskId].collateral;
        // uint revenue = tasks[taskId].cpRevenue;
        // tasks[taskId].revenue = 0;
        // tasks[taskId].cpRevenue = 0;
        // tasks[taskId].collateral = 0;
        // paymentToken.transfer(msg.sender, collateral);
        // revenueToken.transferFrom(apWallet, msg.sender, revenue);

        // emit RevenueCollected(taskId, revenue);
    }

    // Make a payment for a space (DEPRECIATED, USE lockRevenue)
    function makePayment(string memory spaceId, uint hardwareId, uint numHours) public {
        require(hardwareInfo[hardwareId].isActive, "Requested hardware is not supported.");

        uint price = hardwareInfo[hardwareId].pricePerHour * numHours;
        require(paymentToken.balanceOf(msg.sender) >= price, "Insufficient funds.");
        require(paymentToken.allowance(msg.sender, address(this)) >= price, "Approve spending funds.");

        // Transfer the payment to the admin wallet
        paymentToken.transferFrom(msg.sender, address(this), price);

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
        paymentToken.transfer(msg.sender, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function version() public pure returns(uint) {
        return 6;
    }

    function setRefundClaimDuration(uint duration) public onlyAdmin {
        refundClaimDuration = duration;
    }

    /**
     * 
     * @param spaceId - identify for space
     * @param hardwareId - cp hardware id
     * @param numHours - duration in hours
     * @notice The user calls this function to pay for the task, amount paid based on hardware id and duration
     * @dev checks if the user has enough funds and approval
     */
    function lockRevenue(string memory spaceId, uint hardwareId, uint numHours) public {
        // require(tasks[taskId].user == address(0), "task id already in use");
        require(hardwareInfo[hardwareId].isActive, "Requested hardware is not supported.");

        uint price = hardwareInfo[hardwareId].pricePerHour * numHours;
        require(paymentToken.balanceOf(msg.sender) >= price, "Insufficient funds.");
        require(paymentToken.allowance(msg.sender, address(this)) >= price, "Approve spending funds.");

        // Transfer the payment to the admin wallet
        paymentToken.transferFrom(msg.sender, arWallet, price);

        tasks[spaceId].user = msg.sender;
        tasks[spaceId].duration = numHours * 1 hours;
        tasks[spaceId].revenue = price;

        emit RevenueLocked(spaceId, msg.sender, price, tasks[spaceId].revenue, tasks[spaceId].duration);
    }

    /**
     * 
     * @param taskId - task id
     * @param cp - computing provider address
     * @param revenueInPaymentToken - the amount the user paid (usdc)
     * @param collateral - the required amount of colleteral the cp will need to lock
     * @notice This function assigns the cp and collateral values in the Task object
     * @dev This function also calculates how much SWAN the cp will earn
     */
    function assignTask(string memory taskId, address cp, uint revenueInPaymentToken, uint collateral) public onlyAdmin {
        // require(tasks[taskId].revenue == 0 || tasks[taskId].revenue == revenue, "revenue amount does not match");
        tasks[taskId].cp = cp;
        tasks[taskId].cpRevenue = revenueInPaymentToken * paymentToRevenueRate * 95 / 100;
        tasks[taskId].collateral = collateral;
    }

    /**
     * 
     * @param taskId - task id
     * @notice The CP will call this to lock collateral in the contract. Checks funds and approval.
     * @dev This function will also use the block timestamp as the start time.
     */
    function lockCollateral(string memory taskId) public {
        require(tasks[taskId].startTime == 0, "task already accepted");
        require(paymentToken.balanceOf(msg.sender) >= tasks[taskId].collateral, "Insufficient funds.");
        require(paymentToken.allowance(msg.sender, address(this)) >= tasks[taskId].collateral, "Approve spending funds.");

        paymentToken.transferFrom(msg.sender, address(this), tasks[taskId].collateral);

        tasks[taskId].startTime = block.timestamp;

        emit CollateralLocked(taskId, msg.sender, tasks[taskId].collateral);
    }

    /**
     * 
     * @param taskId - task id
     * @notice the user can terminate the task early. The CP should get paid relative to the time elasped.
     * @dev currently not in use, need more discussion on CP termination
     */
    function terminateTask(string memory taskId) public {
    //     require(tasks[taskId].cp == msg.sender || tasks[taskId].user == msg.sender, "task is not assigned to caller");

    //     uint revenue = tasks[taskId].revenue;
    //     uint collateral = tasks[taskId].collateral;
    //     uint elaspedDuration = block.timestamp - tasks[taskId].startTime;

    //     tasks[taskId].revenue = 0;
    //     tasks[taskId].collateral = 0;

    //    //TODO: slashing rules

    //     if (tasks[taskId].user == msg.sender) {
    //         uint earnedRevenue = revenue * (elaspedDuration / tasks[taskId].duration);
    //         uint revenueToCp = earnedRevenue * 95 / 100;
    //         uint revenueToCpInRevenueToken = revenueToCp * paymentToRevenueRate;

    //         revenueToken.transfer(tasks[taskId].cp, revenueToCpInRevenueToken);
    //         paymentToken.transfer(tasks[taskId].cp, collateral);
    //     } else if (msg.sender == tasks[taskId].cp) {
    //         uint earnedCollateral = collateral * (elaspedDuration / tasks[taskId].duration);

    //         paymentToken.transfer(msg.sender, earnedCollateral);
    //     }

    //     paymentToken.transferFrom(apWallet, msg.sender, revenue);
    //     emit TaskTerminated(taskId, msg.sender, block.timestamp);
    }

    /**
     * 
     * @param taskId - task id
     * @notice completes the task and starts the cooldown so the cp can claim the reward.
     */
    function completeTask(string memory taskId) public onlyAdmin {
        // require(block.timestamp < tasks[taskId].taskDeadline, "task deadline passed");
        require(tasks[taskId].refundDeadline == 0, "task already completed");

        tasks[taskId].refundDeadline = block.timestamp + refundClaimDuration;

        emit TaskCompleted(taskId, block.timestamp);
    }

    /**
     * 
     * @param taskId - task id
     * @notice the user can request refund only during the cooldown period. This pauses the cooldown
     * @dev refundDeadline becomes the remaining time so when we need to resume, we can just add block timestamp
     */
    function requestRefund(string memory taskId) public {
        require(tasks[taskId].user == msg.sender || isAdmin[msg.sender], "sender cannot claim this task");
        require(block.timestamp < tasks[taskId].refundDeadline, "not within claim window");

        tasks[taskId].processingRefundClaim = true;

        // track remaining time to unlock
        tasks[taskId].refundDeadline = tasks[taskId].refundDeadline - block.timestamp;

        emit RefundSubmitted(taskId, msg.sender);
    }

    /**
     * 
     * @param taskId - task id
     * @param isClaimValid - claim success result
     * @notice the validation system should determine the result and call this function. 
     * @notice If true, the user should be eligible for refund, and collateral should be slashed
     * @dev slashing rule here still needs to be discussed.
     */
    function validateClaim(string memory taskId, bool isClaimValid) public onlyAdmin {
        require(tasks[taskId].processingRefundClaim, "no claim submitted for this task");
        if (isClaimValid) {
            // uint returnedRevenue = tasks[taskId].revenue;
            tasks[taskId].revenue = 0;
            // paymentToken.transferFrom(apWallet, tasks[taskId].user, returnedRevenue);
        } 

        tasks[taskId].refundDeadline += block.timestamp;
        tasks[taskId].processingRefundClaim = false;

        emit ClaimResult(taskId, isClaimValid);
    }

    // depreciated in favor of claimReward
    function collectRevenue(string memory taskId) public {
        // require(tasks[taskId].cp == msg.sender, "task is not assigned to caller");
        // require(block.timestamp > tasks[taskId].refundDeadline, "wait for claim deadline");
        // require(!tasks[taskId].processingRefundClaim, "claim under review");

        // uint collateral = tasks[taskId].collateral;
        // uint revenue = tasks[taskId].revenue;
        // tasks[taskId].revenue = 0;
        // tasks[taskId].collateral = 0;
        // paymentToken.transfer(msg.sender, collateral);
        // revenueToken.transferFrom(apWallet, msg.sender, revenue);

        // emit RevenueCollected(taskId, revenue);
    }


}