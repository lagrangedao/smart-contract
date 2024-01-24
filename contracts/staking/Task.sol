// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface ICollateral {
    function unlockCollateral(address, uint) external;
}

contract Task is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    string public taskUid;
    address public user;
    address[] public cpList;
    address public arWallet;
    address public apWallet;
    // IERC20 public usdc;
    IERC20 public swan;
    ICollateral public collateralContract;
    // IUniswapV2Router02 public uniswapRouter;
    // uint public usdcRewardAmount;
    uint public swanRewardAmount;
    uint public swanCollateralAmount;
    uint public rewardBalance;
    uint public refundBalance;
    uint public duration;
    uint public startTime;
    uint public endTime;
    uint public refundDeadline;
    uint public refundClaimDuration;
    bool public isProcessingRefundClaim;
    bool[] public isRewardClaimed;
    bool public isTaskTerminated;
    bool public isEndTimeUpdateable;
    // address[] public swapPath;

    mapping(address => bool) isAdmin;

    event TaskTerminated(address user, address[] cpList, uint elaspedDuration, uint userRefund, uint leadingReward, uint otherReward);
    event RewardClaimed(address cp, uint reward);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address admin,
        address[] memory cpAddresses, 
        uint swanReward, 
        uint swanCollateral, 
        uint taskDuration,
        uint refundDuration,
        address collateralAddress
    ) public initializer{ 
        isAdmin[admin] = true;
        cpList = cpAddresses;
        isRewardClaimed = new bool[](cpList.length);
        // usdcRewardAmount = usdcReward;
        swanRewardAmount = swanReward;
        swanCollateralAmount = swanCollateral;
        duration = taskDuration;

        arWallet = 0x47846473daE8fA6E5E51e03f12AbCf4F5eDf9Bf5;
        apWallet = 0x4BC1eE66695AD20771596290548eBE5Cfa1Be332;
        swan = IERC20(0x91B25A65b295F0405552A4bbB77879ab5e38166c);
        collateralContract = ICollateral(collateralAddress);

        startTime = block.timestamp;
        refundClaimDuration = refundDuration;
        isEndTimeUpdateable = true;
    }

    // Modifier to check if the caller is the admin
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only the admin can call this function.");
        _;
    }

    modifier onlyUser() {
        require(msg.sender == user, 'caller is not the user address');
        _;
    }

    modifier onlyCp() {
        bool found = false;
        for (uint i=0; i < cpList.length; i++) {
            if (cpList[i] == msg.sender) {
                found = true;
            }
        }
        require(found, 'cp is not the cp list');
        _;
    }

    function getCpList() public view returns(address[] memory) {
        return cpList;
    }

    function updateEndTime(uint end) public onlyAdmin {
        require(isEndTimeUpdateable, 'endTime is not updateable');
        require(end >= startTime, 'endTime cannot be before startTime');
        isTaskTerminated = true;
        endTime = end;
        calculatePayout();
    }

    function calculatePayout() internal {
        require(endTime > 0, 'endTime is not set');
        uint elaspedDuration = endTime - startTime;

        if (elaspedDuration > duration) {
            elaspedDuration = duration;
        }

        rewardBalance = swanRewardAmount * elaspedDuration / duration;
        refundBalance = swanRewardAmount - rewardBalance;
    }
    
    /**
     * @notice - early termination of the task. 
     * @notice - cp's will get rewarded for the time eslapsed
     * @notice - user will get usdc refunded based on the time remaining
     * @dev - swap the reward amount back to usdc, and compare with the original amount paid.
     */
    function terminateTask(address userAddress) public {
        // require(!isTaskTerminated, "task already terminated");
        // require(refundDeadline == 0, "task already completed");
        // require(msg.sender == user || isAdmin[msg.sender], "sender cannot terminate task");
        
        // isTaskTerminated = true;

        // if (isAdmin[msg.sender]) {
        //     user = userAddress;
        // }
        
        // endTime = block.timestamp;
        // calculatePayout();

        // uint rewardToLeadingCp = rewardBalance;
        // uint rewardToOtherCps = 0;

        // if (cpList.length > 1) {
        //     rewardToLeadingCp = rewardToLeadingCp * 70/100;
        //     rewardToOtherCps = (rewardBalance - rewardToLeadingCp) / (cpList.length - 1);
        // } 

        // emit TaskTerminated(userAddress, cpList, endTime - startTime, refundBalance, rewardToLeadingCp, rewardToOtherCps);
    }

    /**
     * @notice - admin marks task as complete
     * @dev - gives the user `refundClaimDuration` time to sumbit a refund claim.
     */
    function completeTask(address userAddress) public onlyAdmin {
        require(refundDeadline == 0, "task already completed");
        require(!isTaskTerminated, "task already terminated");
        user = userAddress;
        refundDeadline = block.timestamp + refundClaimDuration;
        uint taskFee = swanRewardAmount * 5/100;
        rewardBalance = swanRewardAmount - taskFee;
        refundBalance = 0;

        swan.transfer(apWallet, taskFee);
    }

    /**
     * @notice if the time is within the refund claim window, the user can submit a refund claim
     * @notice it will undergo a review process
     * @dev pauses the refundClaimDuration and stores the time remaining.
     */
    function requestRefund() public  {
        require(!isProcessingRefundClaim, "already requested refund");
        require(!isTaskTerminated, "already terminated");
        require(user == msg.sender || isAdmin[msg.sender], "sender cannot claim this task");
        require(block.timestamp < refundDeadline, "not within claim window");

        isProcessingRefundClaim = true;

        // track remaining time to unlock
        refundDeadline = refundDeadline - block.timestamp;
    }

    /**
     * 
     * @param result refund request result
     * @notice the admin submits the result of the refund request
     * @notice if true, the user gets refunded in usdc.
     */
    function validateRefund(bool result) public onlyAdmin {
        require(isProcessingRefundClaim, "no claim submitted for this task");
        if (result) {
            uint refundableSwanReward = swanRewardAmount;
            swanRewardAmount = 0;
            swan.transfer(user, refundableSwanReward);
        }

        refundDeadline += block.timestamp;
        isProcessingRefundClaim = false;
    }

    /**
     * @notice the cp can claim reward after the refundClaimDuration ends
     * @dev the leading cp receives 70% and other cps split the 30%
     * @dev the rewardBalance does not get deducted, otherwise the percent calculations will change after each call
     */
    function claimReward() public onlyCp {
        require(block.timestamp > refundDeadline || isTaskTerminated, "wait for claim deadline");
        require(!isProcessingRefundClaim, "claim under review");

        uint claimAmount = 0;
        uint collateralAmount = 0;

        // if caller is leading cp
        if (msg.sender == cpList[0] && !isRewardClaimed[0]) {
            if (cpList.length == 1) {
                claimAmount += rewardBalance;
            } else {
                claimAmount += rewardBalance * 7/10;
            }
            collateralAmount += swanCollateralAmount;
            isRewardClaimed[0] = true;
        }
        // claim rules
        for(uint i=1; i<cpList.length; i++) {
            if (msg.sender == cpList[i] && !isRewardClaimed[i]) {
                claimAmount += (rewardBalance * 3/10) / (cpList.length - 1);
                collateralAmount += swanCollateralAmount;
                isRewardClaimed[i] = true;
            }
        }

        isEndTimeUpdateable = false;

        collateralContract.unlockCollateral(msg.sender, collateralAmount);

        emit RewardClaimed(msg.sender, claimAmount);
    }

    function claimRefund() public {
        require(msg.sender == user, 'sender is not user address');
        require(isTaskTerminated);
        
        isEndTimeUpdateable = false;

        uint claimAmount = refundBalance;
        refundBalance = 0;
        isEndTimeUpdateable = false;
        swan.transfer(msg.sender, claimAmount);
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