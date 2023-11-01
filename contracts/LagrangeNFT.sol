// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";

contract LagrangeNFT is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply, ERC1155URIStorage {
    string public name;
    string public symbol;
    string public contractURI;

    constructor(string memory collectionName, string memory collectionSymbol) ERC1155("") {
        name = collectionName;
        symbol = collectionSymbol;
    }

    function setContractURI(string memory newUri) public onlyOwner {
        contractURI = newUri;
    }

     // sets URI for existing token if not already set
    function setURI(uint id, string memory newUri) public onlyOwner {
        // require(exists(id), 'Supply: tokenId does not exist'); 
        _setURI(id, newUri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

     // overrides
    function uri(uint256 tokenId) public view virtual override(ERC1155, ERC1155URIStorage) returns (string memory) {
        return ERC1155URIStorage.uri(tokenId);
    }

    function tokenURI(uint256 tokenId) public view  returns (string memory) {
        return ERC1155URIStorage.uri(tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
