// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.7;

// import "./DataNFT.sol";
// import "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

// /**
//  * @title DataNFTFactory
//  * @author
//  * @notice Creates ERC721 and ERC20 contracts
//  * ERC721 contracts are DataNFTs representing one dataset
//  * ERC721 Tokens within each contract represent versioning
//  * ERC721 Tokens can accept certain ERC20 tokens as datatokens
//  */
// contract DataNFTFactory is FunctionsClient, Ownable {
//     using FunctionsRequest for FunctionsRequest.Request;

//     uint64 private subscriptionId; // need to fund this subscription with LINK tokens
//     string public source; // js code to call GET request
//     address public oracleAddress;

//     struct RequestData {
//         address requestor;
//         string name;
//         string symbol;
//         string datasetUri;
//         bool fulfilled;
//         bool claimable;
//     }

//     mapping(bytes32 => RequestData) public requestData;

//     event OCRResponse(bytes32 indexed requestId, bytes result, bytes err);
//     event DeployNFT(bytes32 requestId, address contractAddress);

//     constructor(
//         address oracle,
//         uint64 _subscriptionId,
//         string memory _source
//     ) FunctionsClient(oracle) {
//         subscriptionId = _subscriptionId;
//         source = _source;
//         oracleAddress = oracle;
//     }

//     /**
//      *
//      * @param metadataUri IPFS URL for the dataset info. should be JSON containing:
//      * - name
//      * - symbol
//      * - datasetUrl
//      * - license
//      * @notice sends a request to Chainlink to verify the metadata, allowing the user to claim
//      */
//     function requestDataNFT(
//         string memory metadataUri
//     ) public returns (bytes32) {
//         string[] memory args = new string[](2);
//         args[0] = metadataUri;
//         args[1] = addressToString(msg.sender);

//         // sends the chainlink request to call API, returns reqID
//         FunctionsRequest.Request memory req;
//         req.initializeRequestForInlineJavaScript(source);
//         req.addArgs(args);
//         bytes32 assignedReqID = sendRequest(req, subscriptionId, 300000);

//         // stores the req info in the mapping (we need to access this info to mint later)
//         RequestData storage data = requestData[assignedReqID];
//         data.requestor = msg.sender;

//         return assignedReqID;
//     }

//     /**
//      * @notice the oracle DON will call this function
//      * @param requestId - request identifier
//      * @param response - source code response
//      * @param err - any errors
//      */
//     function fulfillRequest(
//         bytes32 requestId,
//         bytes memory response,
//         bytes memory err
//     ) internal override {
//         if (bytesToBool(response)) {
//             requestData[requestId].claimable = true;
//         }

//         // update requestData information
//         requestData[requestId].fulfilled = true;

//         emit OCRResponse(requestId, response, err);
//     }

//     /**
//      * @dev TODO, not sure if I should use requestID or metadataURL
//      */
//     function claimDataNFT(bytes32 requestId) public {
//         require(requestData[requestId].fulfilled);
//         require(requestData[requestId].claimable);

//         DataNFT dataset = new DataNFT(
//             requestData[requestId].name,
//             requestData[requestId].symbol
//         );
//         emit DeployNFT(requestId, address(dataset));
//     }

//     function bytesToAddress(
//         bytes memory b
//     ) private pure returns (address addr) {
//         assembly {
//             addr := mload(add(b, 20))
//         }
//     }

//     function bytesToBool(bytes memory b) public pure returns (bool) {
//         if (b.length != 32) {
//             return false;
//         }
//         if (b[31] == 0x01) {
//             return true;
//         }
//         return false;
//     }

//     function addressToString(
//         address _address
//     ) public pure returns (string memory) {
//         bytes20 _bytes = bytes20(_address);
//         bytes16 _hexAlphabet = "0123456789abcdef";
//         bytes memory _stringBytes = new bytes(42);
//         _stringBytes[0] = "0";
//         _stringBytes[1] = "x";
//         for (uint i = 0; i < 20; i++) {
//             uint _byte = uint8(_bytes[i]);
//             _stringBytes[2 + i * 2] = _hexAlphabet[_byte >> 4];
//             _stringBytes[3 + i * 2] = _hexAlphabet[_byte & 0x0f];
//         }
//         return string(_stringBytes);
//     }

//     /**
//      * @notice Allows the Functions oracle address to be updated
//      *
//      * @param oracle New oracle address
//      */
//     function updateOracleAddress(address oracle) public onlyOwner {
//         oracleAddress = oracle;
//         setOracle(oracle);
//     }
// }
