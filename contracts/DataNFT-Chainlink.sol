// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./dev/functions/FunctionsClient.sol";

contract LagrangeChainlinkData is ERC721, ERC721URIStorage, FunctionsClient, Ownable {
    using Functions for Functions.Request;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint64 private subscriptionId;
    string public source;
    
    bytes32 public latestRequestId;
    bytes public latestResponse;
    bytes public latestError;

    event OCRResponse(bytes32 indexed requestId, bytes result, bytes err);

    constructor(address oracle, uint64 _subscriptionId, string memory _source) ERC721("Lagrange Data", "LDNFT") FunctionsClient(oracle) {
        subscriptionId = _subscriptionId;
        source = _source;
    }

    function bytesToBool(bytes memory b) public pure returns (bool) {
        if (b.length != 32) {
            return false;
        }
        if (b[31] == 0x01) {
            return true;
        }
        return false;
    }

    function executeRequest(string[] calldata args) public returns (bytes32) {
        Functions.Request memory req;
        req.initializeRequestForInlineJavaScript(source);
        req.addArgs(args);
        bytes32 assignedReqID = sendRequest(req, subscriptionId, 100000);
        latestRequestId = assignedReqID;
        return assignedReqID;
    }

    function isContractOwner(string[] calldata args) public returns (bool) {
        executeRequest(args);
        return bytesToBool(latestResponse);
    }

    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        latestResponse = response;
        latestError = err;
        emit OCRResponse(requestId, response, err);
    }

    // function mint()
    

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function updateURI(uint tokenId, string memory uri) public {
        require(ownerOf(tokenId) == msg.sender, "caller is not owner");
        _setTokenURI(tokenId, uri);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        //require(uriAccess[msg.sender][tokenId], "caller does not have access");
        return super.tokenURI(tokenId);
    }

  /**
   * @notice Allows the Functions oracle address to be updated
   *
   * @param oracle New oracle address
   */
    function updateOracleAddress(address oracle) public onlyOwner {
        setOracle(oracle);
    }
}