// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CollectionCopy} from "./CollectionCopy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";


contract DestinationMinter is CCIPReceiver, Ownable {
    // erc721 contract address mapping from source => destination
    mapping (address => address) public copiedCollections;
    mapping (bytes32 => bool) public isMessageReceived;
    address public implementationContract;
    
    // event MintCopy(address collectionAddress, uint tokenId);
    event CopyCollection(address sourceCollection, address copiedCollection);
    event CopyNFT(address sourceCollection, uint tokenId);
    event MessageReceived(bytes32 messageId);

    address public sourceContract;
    bytes32 public lastMessageId;

    constructor(address router) CCIPReceiver(router) {
        implementationContract = address(new CollectionCopy());
    }

    function _createCollection(address sourceCollectionAddress, string memory name, string memory symbol) internal {
        address copy = Clones.clone(implementationContract);
        copiedCollections[sourceCollectionAddress] = copy;

        CollectionCopy(copy).initialize(name, symbol);

        emit CopyCollection(sourceCollectionAddress, copy);
    }

    function _copyNFT(address recipient, address sourceCollectionAddress, uint tokenId, string memory uri) internal {
        require(copiedCollections[sourceCollectionAddress] != address(0), 'No destination collection created');

        CollectionCopy(copiedCollections[sourceCollectionAddress]).safeMint(recipient, tokenId, uri);

        emit CopyNFT(sourceCollectionAddress, tokenId);
    }

    // #TODO: maybe add sender address
    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal override {
        require(abi.decode(message.sender, (address)) == sourceContract, "incorrect source minter");

        lastMessageId = message.messageId;
        isMessageReceived[lastMessageId] = true;
        (address sender, address collection, string memory name, string memory symbol, uint tokenId, string memory uri) = abi.decode(message.data, (address, address, string, string, uint, string));

        if (copiedCollections[collection] == address(0)) {
            _createCollection(collection, name, symbol);
        }
           
        _copyNFT(sender, collection, tokenId, uri);
        emit MessageReceived(lastMessageId);
    }

    function setImplementation(address imp) public onlyOwner {
        implementationContract = imp;
    }

    function setSourceMinter(address source) public onlyOwner {
        sourceContract = source;
    }

    function transferCollection(address sourceCollection, address sourceOwner) public onlyOwner {
        CollectionCopy(copiedCollections[sourceCollection]).transferOwnership(sourceOwner);
    }
    

}