// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";

// Import the ERC20 token contract
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract ClaimNFT is Initializable, OwnableUpgradeable, ERC1155HolderUpgradeable {

    IERC1155 collection;

    // Mapping of admin(s)
    mapping(address => bool) public isAdmin;
    mapping(address => mapping(uint => bool)) public claimable;

    event NFTClaimed(address indexed user, uint256 tokenId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address collectionAddress) initializer public {
        __Ownable_init();
        __ERC1155Holder_init();

        isAdmin[msg.sender] = true;
        collection = IERC1155(collectionAddress);
    }

    // Modifier to check if the caller is the admin
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only the admin can call this function.");
        _;
    }

    function setAdmin(address admin, bool status) public onlyOwner {
        isAdmin[admin] = status;
    }

    function setClaim(address claimer, uint tokenId) public onlyAdmin {
        claimable[claimer][tokenId] = true;
    }

    function claim(uint tokenId) public {
        require(claimable[msg.sender][tokenId], "token id not claimable");
        claimable[msg.sender][tokenId] = false;

        collection.safeTransferFrom(address(this), msg.sender, tokenId, 1, "");

        emit NFTClaimed(msg.sender, tokenId);
    }
}