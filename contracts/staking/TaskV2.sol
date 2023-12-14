// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface IWETH {
    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    function deposit() external payable;
    function withdraw(uint wad) external;
    function totalSupply() external view returns (uint);
    function approve(address guy, uint wad) external returns (bool);
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external;
}

interface ICollateral {
    function deposit(address recipient, uint amount) external;
}

contract TaskV2 is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    string public taskUid;
    address public user;
    address[] public cpList;
    address public arWallet;
    address public apWallet;
    address public wethAddress;
    address public collateralAddress;
    uint public reward;
    uint public collateral;
    uint public duration;
    uint public startTime;
    uint public refundDeadline;
    uint public refundClaimDuration;
    bool public isProcessingRefundClaim;
    bool[] public isRewardClaimed;
    bool public isTaskTerminated;

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
        uint rewardAmount,
        uint collateralAmount, 
        uint taskDuration,
        uint refundDuration
    ) public initializer{ 
        isAdmin[admin] = true;
        cpList = cpAddresses;
        isRewardClaimed = new bool[](cpList.length);
        reward = rewardAmount;
        collateral = collateralAmount;
        duration = taskDuration;

        arWallet = 0x47846473daE8fA6E5E51e03f12AbCf4F5eDf9Bf5;
        apWallet = 0x4BC1eE66695AD20771596290548eBE5Cfa1Be332;
        wethAddress = 0x4A5d0592CDA144fCCe9543a4D3dEB121CbB0221D;
        collateralAddress = 0x494E750c3ED3AD9e2fcD8aEEDf54b2D98Bd8B1dA;

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
        
        uint refundableReward = reward;
        uint refundableCollateral = collateral;
        uint elaspedDuration = block.timestamp - startTime;

        reward = 0;
        collateral = 0;

        uint rewardSubtotal = refundableReward * elaspedDuration / duration;
        uint rewardToLeadingCp = rewardSubtotal;
        uint rewardToOtherCps = 0;

        if (cpList.length > 1) {
            rewardToLeadingCp = rewardSubtotal * 70/100;
            rewardToOtherCps = (rewardSubtotal - rewardToLeadingCp) / (cpList.length - 1);
        }

        if (cpList.length >= 1) {
            IWETH(wethAddress).transfer(cpList[0], rewardToLeadingCp + refundableCollateral); 

            // IWETH(wethAddress).approve(collateralAddress, refundableCollateral);
            // ICollateral(collateralAddress).deposit(cpList[0], refundableCollateral);
        }

        for (uint i = 1; i < cpList.length; i++) {
            IWETH(wethAddress).transfer(cpList[i], rewardToOtherCps + refundableCollateral);

            // IWETH(wethAddress).approve(collateralAddress, refundableCollateral);
            // ICollateral(collateralAddress).deposit(cpList[i], refundableCollateral);
        }   

        IWETH(wethAddress).transfer(userAddress, refundableReward - rewardSubtotal);

        emit TaskTerminated(userAddress, cpList, elaspedDuration, refundableReward - rewardSubtotal, rewardToLeadingCp, rewardToOtherCps);
    }

    /**
     * @notice - admin marks task as complete
     * @dev - gives the user `refundClaimDuration` time to sumbit a refund claim.
     */
    function completeTask(address userAddress) public onlyAdmin {
        require(refundDeadline == 0, "task already completed");
        user = userAddress;
        refundDeadline = block.timestamp + refundClaimDuration;
        uint taskFee = reward * 5/100;
        reward -= taskFee;

        IWETH(wethAddress).transfer(apWallet, taskFee);
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
            uint refundableReward = reward;
            uint refundableCollateral = collateral;
            reward = 0;
            collateral = 0;

            IWETH(wethAddress).transfer(user, refundableReward);
            IWETH(wethAddress).transfer(arWallet, refundableCollateral * cpList.length);

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
        uint claimCount = 0;

        if (msg.sender == cpList[0] && !isRewardClaimed[0]) {
            if (cpList.length == 1) {
                claimAmount += reward;
            } else {
                claimAmount += reward * 7/10;
            }
            isRewardClaimed[0] = true;
            claimCount++;
        }
        // claim rules
        for(uint i=1; i<cpList.length; i++) {
            if (msg.sender == cpList[i] && !isRewardClaimed[i]) {
                claimAmount += (reward * 3/10) / (cpList.length - 1);
                claimCount++;
                isRewardClaimed[i] = true;
            }
        }

        IWETH(wethAddress).transfer(msg.sender, claimAmount + (collateral * claimCount));

        // IWETH(wethAddress).approve(collateralAddress, collateral * claimCount);
        // ICollateral(collateralAddress).deposit(msg.sender, collateral * claimCount);

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