// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the ERC20 token contract
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SpacePaymentV4 is Ownable {
    // Address of the ERC20 token contract
    IERC20 public tokenContract;

    struct SpaceInfo {
        // address owner;
        // string spaceName;
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

    mapping(uint => Hardware) public hardwareInfo;
    mapping(address => mapping(string => SpaceInfo)) public spaceInfo;
    mapping(address => mapping(string => uint)) public claimable;

    event HardwareSet(uint hardwareId, string name, uint hourlyRate, bool active);
    event PaymentMade(address payer, address spaceOwner, string spaceName, string hardware, uint numHours);
    event RefundSet(string refundId, address wallet, uint amount);
    event RefundClaimed(string refundId, address wallet, uint amount);
    event RewardSet(string taskId, address wallet, uint amount);
    event RewardClaimed(string taskId, address wallet, uint amount);


    constructor(address _tokenContract) {
        tokenContract = IERC20(_tokenContract);
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

    function withdraw(uint amount) public onlyOwner {
        tokenContract.transfer(msg.sender, amount);
    }

    function setClaim(address wallet, string memory claimId, uint claimAmount) internal {
        claimable[wallet][claimId] = claimAmount;
    }

    function claim (address wallet, string memory claimId) internal returns(uint){
        uint claimAmount = claimable[wallet][claimId];
        require(claimAmount > 0, "Nothing to claim.");
        require(tokenContract.balanceOf(address(this)) >= claimAmount, "Claim currently unavailable");

        claimable[wallet][claimId] = 0;
        tokenContract.transfer(wallet, claimAmount);

        return claimAmount;
    }

    function setRefund(string memory refundId, address wallet, uint refundAmount) public onlyAdmin {
        setClaim(wallet, refundId, refundAmount);
        emit RefundSet(refundId, wallet, refundAmount);
    }

    function setReward(string memory taskId, address cpWallet, uint rewardAmount) public onlyAdmin {
        setClaim(cpWallet, taskId, rewardAmount);
        emit RewardSet(taskId, cpWallet, rewardAmount);
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
    function makePayment(address spaceOwner, string memory spaceName, uint hardwareId, uint numHours) public {
        require(hardwareInfo[hardwareId].isActive, "Requested hardware is not supported.");

        uint price = hardwareInfo[hardwareId].pricePerHour * numHours;
        require(tokenContract.balanceOf(msg.sender) >= price, "Insufficient funds.");
        require(tokenContract.allowance(msg.sender, address(this)) >= price, "Approve spending funds.");

        // Transfer the payment to the admin wallet
        tokenContract.transferFrom(msg.sender, address(this), price);

        if (spaceInfo[spaceOwner][spaceName].expiryDate <= block.timestamp) {
            // new space
            spaceInfo[spaceOwner][spaceName] = SpaceInfo(hardwareId, block.timestamp + (numHours * 1 hours));
        } else {
            // TODO: extending space
            spaceInfo[spaceOwner][spaceName].hardwareId = hardwareId;
            spaceInfo[spaceOwner][spaceName].expiryDate +=  numHours * 1 hours;
        }

        emit PaymentMade(msg.sender, spaceOwner, spaceName, hardwareInfo[hardwareId].name, numHours);
    }
}
