// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the ERC20 token contract
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SpacePaymentV2 is Ownable {
    // Address of the ERC20 token contract
    IERC20 public tokenContract;

    struct SpaceInfo {
        // address owner;
        // string spaceName;
        uint hardwareId;
        uint expiryDate;
        uint refundableAmount;
    }

    struct Hardware {
        string name;
        uint pricePerHour;
        bool isActive;
    }

    // Mapping of admin(s)
    mapping(address => bool) public isAdmin;

    mapping(address => mapping(string => SpaceInfo)) public spaceInfo;
    mapping(uint => Hardware) public hardwareInfo;

    event HardwareSet(uint hardwareId, string name, uint hourlyRate, bool active);
    event PaymentMade(address payer, address spaceOwner, string spaceName, string hardware, uint numHours);
    event RefundSet(address wallet, string spaceName, uint amount);
    event RefundClaimed(address wallet, string spaceName, uint amount);


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

    // Update the refundable status of a space
    function setRefund(address wallet, string memory spaceName, uint refundAmount) public onlyAdmin {
        spaceInfo[wallet][spaceName].refundableAmount = refundAmount;
        emit RefundSet(wallet, spaceName, refundAmount);
    }

    // Update the refundable status of a space
    function claimRefund (string memory spaceName) public {
        uint refundAmount = spaceInfo[msg.sender][spaceName].refundableAmount;
        require(refundAmount > 0, "No refund to claim.");
        require(tokenContract.balanceOf(address(this)) >= refundAmount, "Refund currently unavailable");

        spaceInfo[msg.sender][spaceName].refundableAmount = 0;
        tokenContract.transfer(msg.sender, refundAmount);

        emit RefundClaimed(msg.sender, spaceName, refundAmount);
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
            spaceInfo[spaceOwner][spaceName] = SpaceInfo(hardwareId, block.timestamp + (numHours * 1 hours), 0);
        } else {
            // TODO: extending space
            spaceInfo[spaceOwner][spaceName].hardwareId = hardwareId;
            spaceInfo[spaceOwner][spaceName].expiryDate +=  numHours * 1 hours;
        }

        emit PaymentMade(msg.sender, spaceOwner, spaceName, hardwareInfo[hardwareId].name, numHours);
    }
}
