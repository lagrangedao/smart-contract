// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./DataToken.sol";

contract DataNFT is
    ERC721,
    ERC721URIStorage,
    Ownable
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string public contractURI; // dataset metadata

    struct DataTokenSettings {
        uint uriFee; // amount to view uri
        bool consumesDataToken; // if true, user has to pay uriFee
    }

    mapping(uint => mapping(address => DataTokenSettings)) idToDataTokens;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}
 
    function mint(address recipient, string memory uri) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function deployDataToken(uint tokenId) public returns(address dataTokenAddress) {
        require(ownerOf(tokenId) == msg.sender, "only token owner can create datatoken");
        DataToken dataToken = new DataToken();
        idToDataTokens[tokenId][address(dataToken)] = DataTokenSettings(0, false);
        return address(dataToken);
    }

    function assignToken(uint tokenId, address dataTokenAddress, uint fee, bool consume) public {
        require(ownerOf(tokenId) == msg.sender, "msg.sender is not token owner");
        idToDataTokens[tokenId][dataTokenAddress] = DataTokenSettings(fee, consume);
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
        //require(uriAccess[msg.sender][tokenId], "caller does not have access");
        return super.tokenURI(tokenId);
    }

    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }
}
