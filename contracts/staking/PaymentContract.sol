// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract PaymentContract is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    
    // Address of the ERC20 token contract
    IERC20 public paymentToken;

    address arWallet;

    struct Hardware {
        string name;
        uint pricePerHour;
        bool isActive;
    }


    // Mapping of admin(s)
    mapping(address => bool) public isAdmin;
    mapping(uint => Hardware) public hardwareInfo; // maps id => info
    mapping(address => mapping(string => uint)) public claimable; // maps wallet => id => claimable amount


    event HardwareSet(uint hardwareId, string name, uint hourlyRate, bool active);
    event RefundSet(string refundId, address wallet, uint refundAmount);
    event RevenueLocked(string spaceId, address indexed user, uint amountPaid, uint duration);
    event RefundClaimed(string refundId, address user, uint refundAmount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address inToken) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();

        paymentToken = IERC20(inToken);
        isAdmin[msg.sender] = true;
    }

    // Modifier to check if the caller is the admin
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only the admin can call this function.");
        _;
    }

    function setWallet(address newArWallet) public onlyAdmin {
        arWallet = newArWallet;
    }

    function setPaymentToken(address token) public onlyOwner {
        paymentToken = IERC20(token);
    }

    function setAdmin(address admin, bool status) public onlyOwner {
        isAdmin[admin] = status;
    }

     function setHardware(uint hardwareId, string memory name, uint hourlyRate, bool active) public onlyOwner {
        hardwareInfo[hardwareId] = Hardware(name, hourlyRate, active);
        emit HardwareSet(hardwareId, name, hourlyRate, active);
    }

    function setRefund(string memory refundId, address wallet, uint refundAmount) public onlyAdmin {
        claimable[wallet][refundId] = refundAmount;
        emit RefundSet(refundId, wallet, refundAmount);
    }

    function claimRefund (string memory refundId) public {
        uint refundAmount = claimable[msg.sender][refundId];
        require(refundAmount > 0, "Nothing to claim.");
        require(paymentToken.balanceOf(arWallet) >= refundAmount, "Claim currently unavailable");

        claimable[msg.sender][refundId] = 0;
        paymentToken.transferFrom(arWallet, msg.sender, refundAmount);

        emit RefundClaimed(refundId, msg.sender, refundAmount);
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

        emit RevenueLocked(spaceId, msg.sender, price, numHours);
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
