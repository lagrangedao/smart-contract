// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";

// Import the ERC20 token contract
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract UBINFTClaim is Initializable, OwnableUpgradeable, ERC1155HolderUpgradeable {

    IERC1155 public collection;

    uint[] public tokenIds;

    // Mapping of admin(s)
    mapping(address => bool) public isAdmin;
    mapping(address => uint[]) public claimable; // user -> quantity

    event NFTClaimed(address indexed user, uint[] tokenIds, uint[] quantities);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address collectionAddress) initializer public {
        __Ownable_init();
        __ERC1155Holder_init();

        isAdmin[msg.sender] = true;
        collection = IERC1155(collectionAddress);

        tokenIds = [58, 59, 60, 61, 62];
    }

    // Modifier to check if the caller is the admin
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only the admin can call this function.");
        _;
    }

    function setAdmin(address admin, bool status) public onlyOwner {
        isAdmin[admin] = status;
    }

    function setClaim(address claimer, uint[] memory quantity) public onlyAdmin {
        claimable[claimer] = quantity;
    }

    function claim() public {
        require(claimable[msg.sender].length == tokenIds.length);
        uint[] memory quantities = claimable[msg.sender];
        claimable[msg.sender] = [0, 0, 0, 0, 0];

        collection.safeBatchTransferFrom(address(this), msg.sender, tokenIds, quantities, "");

        emit NFTClaimed(msg.sender, tokenIds, quantities);
    }

    function setTokenIds(uint[] memory ids) public onlyOwner {
        tokenIds = ids;
    }
}