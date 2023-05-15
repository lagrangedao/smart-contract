// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./DataToken.sol";

/**
 * @title DataNFT
 * @notice This contract is an ERC721 contract representing one dataset.
 * each tokenId will be mapped to metadata (that should include the dataset uri)
 * and can be viewed as different versions of the dataset.
 */
contract DataNFT is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string public contractURI; // dataset metadata

    mapping(uint => address) idToDataToken;
    event DeployDataToken(address dataTokenAddress);

    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {}

    /**
     * @notice creates a new version for the dataset, sub-licensed to recipient
     * @param recipient - sub-licensee
     * @param uri - new verison metadata
     */
    function mint(address recipient, string memory uri) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, uri);
    }

    /**
     * @notice deploys a new data token for this dataset.
     */
    function deployDataToken(
        uint tokenId,
        string memory name,
        string memory symbol
    ) public {
        DataToken dataToken = new DataToken(name, symbol);
        idToDataToken[tokenId] = address(dataToken);
        emit DeployDataToken(address(dataToken));
    }

    // The following functions are overrides required by Solidity.

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function updateContractURI(string memory uri) public onlyOwner {
        contractURI = uri;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }
}
