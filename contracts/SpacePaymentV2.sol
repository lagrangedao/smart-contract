// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the ERC20 token contract
import "./YourERC20Token.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SpacePaymentV2 is Ownable {
    // Address of the ERC20 token contract
    YourERC20Token public tokenContract;

    // Mapping of space to refund amount
    mapping(address => mapping(string => uint)) public spaceRefund;

    // Mapping of admin(s)
    mapping(address => bool) public isAdmin;

    // Mapping of GPU prices
    mapping(uint => uint) public gpuPrices;

    // Event emitted when the refundable status is updated
    event RefundableStatusUpdated(uint256 spaceId, bool refundable);

    // Event emitted when a payment is made for a space
    event PaymentMade(uint256 spaceId, address payer, uint256 amount);

    event RefundSet(address wallet, string spaceName, uint amount);
    event RefundClaimed(address wallet, string spaceName, uint amount);


    constructor(address _tokenContract) {
        tokenContract = YourERC20Token(_tokenContract);
        isAdmin[msg.sender] = true;
    }

    // Modifier to check if the caller is the admin
    modifier onlyAdmin() {
        require(msg.sender == adminWallet, "Only the admin can call this function.");
        _;
    }

    function setAdmin(address admin, bool status) public onlyOwner {
        isAdmin[admin] = status;
    }

    function setGpuPrice(uint gpuId, uint price) public onlyOwner {
        gpuPrices[gpuId] = price;
    }

    // Update the refundable status of a space
    function setRefund(address wallet, string memory spaceName, uint refundAmount) external onlyAdmin {
        spaceRefund[wallet][spaceName] = refundAmount;
    }

    // Make a payment for a space
    function makePayment(uint256 spaceId) external payable {
        require(spaces[spaceId].gpuPrice > 0, "Space with the given ID does not exist.");
        require(msg.value > 0, "Payment amount must be greater than zero.");

        uint256 price = spaces[spaceId].gpuPrice;

        // Transfer the payment to the admin wallet
        adminWallet.transfer(price);

        // Transfer an equivalent amount of ERC20 tokens from the caller to the contract
        tokenContract.transferFrom(msg.sender, address(this), price);

        emit PaymentMade(spaceId, msg.sender, price);
    }

    // Check if a space is refundable
    function isRefundable(uint256 spaceId) external view returns (bool) {
        require(spaces[spaceId].gpuPrice > 0, "Space with the given ID does not exist.");

        return spaces[spaceId].refundable;
    }
}
