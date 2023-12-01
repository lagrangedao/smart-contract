// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Swap.sol";
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
    TokenSwap public tokenSwap;
    uint public usdcRewardAmount;
    uint public swanRewardAmount;
    uint public swanCollateralAmount;
    uint public duration;
    uint public startTime;
    uint public refundDeadline;
    uint public refundClaimDuration;
    bool public isProcessingRefundClaim;
    bool[] public isRewardClaimed;

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
        uint duration_
    ) public initializer{ 
        isAdmin[admin] = true;
        cpList = cpAddresses;
        isRewardClaimed = new bool[](cpList.length);
        usdcRewardAmount = usdcReward;
        swanRewardAmount = swanReward;
        swanCollateralAmount = swanCollateral;
        duration = duration_;

        arWallet = 0x47846473daE8fA6E5E51e03f12AbCf4F5eDf9Bf5;
        apWallet = 0x4BC1eE66695AD20771596290548eBE5Cfa1Be332;
        usdc = IERC20(0x0c1a5A0Cd0Bb4A9F564f09Cc66f4c921B560371a);
        swan = IERC20(0x407a5856050053CF1DB54113bd9Ea9D2Eeee7C35);
        tokenSwap = TokenSwap(0xaAc390a1A1C1BCF35261181207Ecf6f565dbacb5);

        startTime = block.timestamp;
        refundClaimDuration = 3 days;
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
        require(refundDeadline == 0, "task already completed");
        require(msg.sender == user || isAdmin[msg.sender], "sender cannot terminate task");
        
        if (isAdmin[msg.sender] && user == address(0)) {
            user = userAddress;
        }
        
        uint refundableSwanReward = swanRewardAmount;
        uint refundableUsdcReward = usdcRewardAmount;
        uint refundableCollateral = swanCollateralAmount;
        uint elaspedDuration = block.timestamp - startTime;

        usdcRewardAmount = 0;
        swanRewardAmount = 0;
        swanCollateralAmount = 0;

        uint rewardSubtotal = refundableSwanReward * (elaspedDuration / duration);
        uint rewardToLeadingCp = rewardSubtotal * 70/100;
        uint rewardToOtherCps = (rewardSubtotal - rewardToLeadingCp) / 2;

        swan.transfer(cpList[0], rewardToLeadingCp + refundableCollateral);
        swan.transfer(cpList[1], rewardToOtherCps + refundableCollateral);
        swan.transfer(cpList[2], rewardToOtherCps + refundableCollateral);

        swan.approve(address(tokenSwap), refundableSwanReward);
        uint refundToUser = tokenSwap.swapSwanToUsdc(refundableSwanReward - rewardSubtotal);

        if (refundToUser < refundableUsdcReward) {
            usdc.transfer(user, refundToUser);
        } else {
            usdc.transfer(user, refundableUsdcReward);
        }

        emit TaskTerminated(user, cpList, elaspedDuration, refundToUser, rewardToLeadingCp, rewardToOtherCps);
    }

    /**
     * @notice - admin marks task as complete
     * @dev - gives the user `refundClaimDuration` time to sumbit a refund claim.
     */
    function completeTask(address userAddress) public onlyAdmin {
        require(refundDeadline == 0, "task already completed");
        user = userAddress;
        refundDeadline = block.timestamp + refundClaimDuration;
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

            swan.approve(address(tokenSwap), refundableSwanReward); 
            uint refundToUser = tokenSwap.swapSwanToUsdc(refundableSwanReward);

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

        uint cpIndex;
        // claim rules
        for(uint i=0; i<cpList.length; i++) {
            if (msg.sender == cpList[i]) {
                cpIndex = i;
            }
        }

        require(!isRewardClaimed[cpIndex], "reward already claimed");

        isRewardClaimed[cpIndex] = true;
    
        if (cpIndex == 0) {
            swan.transfer(cpList[0], swanRewardAmount * 7/10 + swanCollateralAmount);
            emit RewardClaimed(msg.sender, swanRewardAmount * 7/10 );
        } else {
            swan.transfer(cpList[cpIndex], swanRewardAmount * 15/100 + swanCollateralAmount);
            emit RewardClaimed(msg.sender, swanRewardAmount * 15/100 );
        }

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