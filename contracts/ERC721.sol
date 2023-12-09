// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;

    mapping (address=>bool) public isAdmin;
    
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only the admin can call this function.");
        _;
    }

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    { 
        isAdmin[msg.sender] = true;
    }

    function addAdmin(address newAdmin) public onlyOwner {
        isAdmin[newAdmin] = true;
    }

    function safeMint(address to, string memory uri) public onlyAdmin {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}