// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DNFT is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    mapping(address => mapping(uint => bool)) uriAccess;



    constructor() ERC721("Lagrange DATA", "LADATA") {}

    function safeMint(address to, string memory uri) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        uriAccess[to][tokenId] = true;
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(uriAccess[msg.sender][tokenId], "msg.sender does not have access");
        return super.tokenURI(tokenId);
    }

    function grantAccess(uint256 tokenId, address accessee)
        public
    {
        require(msg.sender == ownerOf(tokenId), "msg.sender does not own this token");
        uriAccess[accessee][tokenId] = true;
    }

    function checkAccess(uint256 tokenId, address accessee)
        public view returns (bool)
    {
        return uriAccess[accessee][tokenId];
    }
}
