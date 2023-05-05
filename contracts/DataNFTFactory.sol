// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./DataNFT.sol";
import "@chainlink/contracts/src/v0.8/dev/functions/FunctionsClient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DataNFTFactory
 * @author 
 * @notice Creates ERC721 and ERC20 contracts
 * ERC721 contracts are DataNFTs representing one dataset
 * ERC721 Tokens within each contract represent versioning
 * ERC721 Tokens can accept certain ERC20 tokens as datatokens
 */
contract DataNFTFactory is FunctionsClient, Ownable {
    using Functions for Functions.Request;

    uint64 private subscriptionId; // need to fund this subscription with LINK tokens
    string public source; // js code to call GET request
    address public oracleAddress;

    struct RequestData {
        address requestor;
        string name;
        string symbol;
        string datasetUri;
        bool fulfilled;
        bool claimable;
    }

    mapping(bytes32 => RequestData) public requestData;

    constructor(
        address oracle,
        uint64 _subscriptionId,
        string memory _source
    ) FunctionsClient(oracle) {
        subscriptionId = _subscriptionId;
        source = _source;
        oracleAddress = oracle;
    }

    /**
     * 
     * @param metadataUri IPFS URL for the dataset info. should be JSON containing:
     * - name
     * - symbol
     * - datasetUrl
     * - license
     * @notice sends a request to Chainlink to verify the metadata, allowing the user to claim
     */
    function requestDataNFT(string memory metadataUri) public returns (bytes32) {
        string[] memory args = new string[](1);
        args[0] = metadataUri;

        // sends the chainlink request to call API, returns reqID
        Functions.Request memory req;
        req.initializeRequestForInlineJavaScript(source);
        req.addArgs(args);
        bytes32 assignedReqID = sendRequest(req, subscriptionId, 300000);

        // stores the req info in the mapping (we need to access this info to mint later)
        RequestData storage data = requestData[assignedReqID];
        data.requestor = msg.sender;

        return assignedReqID;
    }

    /**
     * @notice the oracle DON will call this function
     * @param requestId - request identifier
     * @param response - source code response
     * @param err - any errors
     */
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {

    }

    /**
     * @dev TODO, not sure if I should use requestID or metadataURL
     */
    function claimDataNFT() public {}


    /**
     * @notice Allows the Functions oracle address to be updated
     *
     * @param oracle New oracle address
     */
    function updateOracleAddress(address oracle) public onlyOwner {
        oracleAddress = oracle;
        setOracle(oracle);
    }

}