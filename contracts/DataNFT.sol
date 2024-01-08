// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./DataToken.sol";

contract DataNFT is Initializable, ERC721URIStorageUpgradeable, OwnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    string public contractURI; // dataset metadata
    address public factory;

    mapping(uint => address) public idToDataToken;
    event DeployDataToken(uint tokenId, address dataTokenAddress);
    event CreateLicense(uint tokenId, address recipient, string uri);

    // owner and factory are admins
    modifier onlyAdmin {
        require(msg.sender == owner() || msg.sender == factory);
        _;
   }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // _disableInitializers();
    }

    // factory should initialize contract
    function initialize(address owner, string memory name, string memory uri) initializer public {
        __ERC721_init(name, "DATA");
        __ERC721URIStorage_init();
        __Ownable_init();

        factory = msg.sender;
        transferOwnership(owner);

        setContractUri(uri);
    }

    /**
     * @notice creates a new version for the dataset, sub-licensed to recipient
     * @param recipient - sub-licensee
     */
    function createLicense(address recipient, string memory uri) public onlyAdmin {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, uri);

        emit CreateLicense(tokenId, recipient, uri);
    }

    /**
     * @notice deploys a new data token for this dataset.
     * @dev each token gets 1 datatoken
     */
    function deployDataToken(uint tokenId, string memory name, string memory symbol) public {
        require(ownerOf(tokenId) == msg.sender);
        DataToken dataToken = new DataToken(name, symbol);
        idToDataToken[tokenId] = address(dataToken);
        emit DeployDataToken(tokenId, address(dataToken));
    }

    function setContractUri(string memory uri) public onlyAdmin {
        contractURI = uri;
    }

    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}