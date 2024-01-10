// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


contract Task is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    string public taskUid;
    address public user;
    address[] public cpList;
    address public arWallet;
    address public apWallet;
    IERC20 public usdc;
    IERC20 public swan;
    IUniswapV2Router02 public uniswapRouter;
    uint public usdcRewardAmount;
    uint public swanRewardAmount;
    uint public swanCollateralAmount;
    uint public duration;
    uint public startTime;
    uint public refundDeadline;
    uint public refundClaimDuration;
    bool public isProcessingRefundClaim;
    bool[] public isRewardClaimed;
    bool public isTaskTerminated;
    address[] public swapPath;

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
        uint usdcReward, 
        uint swanReward, 
        uint swanCollateral, 
        uint taskDuration,
        uint refundDuration
    ) public initializer{ 
        isAdmin[admin] = true;
        cpList = cpAddresses;
        isRewardClaimed = new bool[](cpList.length);
        usdcRewardAmount = usdcReward;
        swanRewardAmount = swanReward;
        swanCollateralAmount = swanCollateral;
        duration = taskDuration;

        arWallet = 0x47846473daE8fA6E5E51e03f12AbCf4F5eDf9Bf5;
        apWallet = 0x4BC1eE66695AD20771596290548eBE5Cfa1Be332;
        usdc = IERC20(0x0c1a5A0Cd0Bb4A9F564f09Cc66f4c921B560371a);
        swan = IERC20(0x407a5856050053CF1DB54113bd9Ea9D2Eeee7C35);
        uniswapRouter = IUniswapV2Router02(0x9b89AA8ed8eF4EDeAAd266F58dfec09864bbeC1f);
        swapPath = [0x407a5856050053CF1DB54113bd9Ea9D2Eeee7C35, 0x0c1a5A0Cd0Bb4A9F564f09Cc66f4c921B560371a];

        startTime = block.timestamp;
        refundClaimDuration = refundDuration;
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
    
    /**
     * @notice - early termination of the task. Can only be called by the user
     * @notice - cp's will get rewarded for the time eslapsed
     * @notice - user will get usdc refunded based on the time remaining
     * @dev - swap the reward amount back to usdc, and compare with the original amount paid.
     */
    function terminateTask(address userAddress) public {
        require(!isTaskTerminated, "task already terminated");
        require(refundDeadline == 0, "task already completed");
        require(msg.sender == user || isAdmin[msg.sender], "sender cannot terminate task");
        
        isTaskTerminated = true;

        if (isAdmin[msg.sender]) {
            user = userAddress;
        }
        
        uint refundableSwanReward = swanRewardAmount;
        uint refundableUsdcReward = usdcRewardAmount;
        uint refundableCollateral = swanCollateralAmount;
        uint elaspedDuration = block.timestamp - startTime;

        usdcRewardAmount = 0;
        swanRewardAmount = 0;
        swanCollateralAmount = 0;

        if (elaspedDuration > duration) {
            elaspedDuration = duration;
        }

        uint rewardSubtotal = refundableSwanReward * elaspedDuration / duration;
        uint rewardToLeadingCp = rewardSubtotal;
        uint rewardToOtherCps = 0;

        if (cpList.length > 1) {
            rewardToLeadingCp = rewardSubtotal * 70/100;
            rewardToOtherCps = (rewardSubtotal - rewardToLeadingCp) / (cpList.length - 1);
        }

        if (cpList.length >= 1) {
            swan.transfer(cpList[0], rewardToLeadingCp + refundableCollateral); 
        }

        for (uint i = 1; i < cpList.length; i++) {
            swan.transfer(cpList[i], rewardToOtherCps + refundableCollateral);
        }   

        uint refundAmount = refundableSwanReward - rewardSubtotal;
        uint refundToUser = 0;

        if (refundAmount > 0) {
            swan.approve(address(uniswapRouter), refundableSwanReward);
            uint[] memory result = uniswapRouter.swapExactTokensForTokens(refundableSwanReward - rewardSubtotal, 0, swapPath, address(this), block.timestamp + 2 hours);

            refundToUser = result[1];
        }

        if (refundToUser < refundableUsdcReward) {
            usdc.transfer(userAddress, refundToUser);
        } else {
            usdc.transfer(userAddress, refundableUsdcReward);
        }

        emit TaskTerminated(userAddress, cpList, elaspedDuration, refundToUser, rewardToLeadingCp, rewardToOtherCps);
    }

    /**
     * @notice - admin marks task as complete
     * @dev - gives the user `refundClaimDuration` time to sumbit a refund claim.
     */
    function completeTask(address userAddress) public onlyAdmin {
        require(refundDeadline == 0, "task already completed");
        user = userAddress;
        refundDeadline = block.timestamp + refundClaimDuration;
        uint taskFee = swanRewardAmount * 5/100;
        swanRewardAmount -= taskFee;

        swan.transfer(apWallet, taskFee);
    }

    /**
     * @notice if the time is within the refund claim window, the user can submit a refund claim
     * @notice it will undergo a review process
     * @dev pauses the refundClaimDuration and stores the time remaining.
     */
    function requestRefund() public  {
        require(!isProcessingRefundClaim, "already requested refund");
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
            uint refundableUsdcReward = usdcRewardAmount;
            swanRewardAmount = 0;
            usdcRewardAmount = 0;   

            uint refundAmount = refundableSwanReward;
            uint refundToUser = 0;

            if (refundAmount > 0) {
                swan.approve(address(uniswapRouter), refundableSwanReward); 
                uint[] memory swapResult = uniswapRouter.swapExactTokensForTokens(refundableSwanReward, 0, swapPath, address(this), block.timestamp + 2 hours);
                refundToUser = swapResult[1];
            }

            if (refundToUser < refundableUsdcReward) {
                usdc.transfer(user, refundToUser);
            } else {
                usdc.transfer(user, refundableUsdcReward);
            }
        }

        refundDeadline += block.timestamp;
        isProcessingRefundClaim = false;
    }

    /**
     * @notice the cp can claim reward after the refundClaimDuration ends
     * @dev the leading cp receives 70% and other cps split the 30%
     */
    function claimReward() public onlyCp {
        require(block.timestamp > refundDeadline, "wait for claim deadline");
        require(!isProcessingRefundClaim, "claim under review");

        uint claimAmount = 0;

        if (msg.sender == cpList[0] && !isRewardClaimed[0]) {
            if (cpList.length == 1) {
                claimAmount += swanRewardAmount + swanCollateralAmount;
            } else {
                claimAmount += swanRewardAmount * 7/10 + swanCollateralAmount;
            }
            isRewardClaimed[0] = true;
        }
        // claim rules
        for(uint i=1; i<cpList.length; i++) {
            if (msg.sender == cpList[i] && !isRewardClaimed[i]) {
                claimAmount += (swanRewardAmount * 3/10) / (cpList.length - 1);
                claimAmount += swanCollateralAmount;
                isRewardClaimed[i] = true;
            }
        }

        swan.transfer(msg.sender, claimAmount);
        emit RewardClaimed(msg.sender, claimAmount );
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