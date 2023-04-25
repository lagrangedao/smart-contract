// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./DataNFT.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

/**
 * @title DataNFTFactory
 * @author 
 * @notice Creates ERC721 and ERC20 contracts
 * ERC721 contracts are DataNFTs representing one dataset
 * ERC721 Tokens within each contract represent versioning
 * ERC721 Tokens can accept certain ERC20 tokens as datatokens
 */
contract DataNFTFactory is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    bytes32 private jobId;
    uint256 private fee;
    address public oracleAddress;

    struct RequestData {
        address owner;
        uint datasetId;
        string uri;
        bool fulfilled;
        bool verified;
    }
    mapping(bytes32 => RequestData) public requestData;
    mapping(uint => address) public dataIdToNftAddress;

    event OracleResult(bytes32 indexed requestId, address uriOwner);

    constructor(
        address linkTokenAddress,
        address _oracleAddress,
        uint _fee
    ) {
        setChainlinkToken(linkTokenAddress);
        setChainlinkOracle(_oracleAddress);
        oracleAddress = _oracleAddress;
        jobId = '7da2702f37fd48e5b1b9a5715e3509b6'; // GET req job ID
        fee = _fee; // 0,1 * 10**18 (Varies by network and job)
    }

    /**
     * @dev for now, pass in uri, checks owner,
     * TODO: pass dataset id, check api to verify owner
     * @dev The deployed contract stores Metadata, ownership, sub-license information, permissions.
     */
    function requestDataNFT(uint datasetId, string memory uri) public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        req.add("get", uri);
        req.add("path", "owner");


        bytes32 assignedReqID = sendChainlinkRequest(req, fee);
        requestData[assignedReqID] = RequestData(msg.sender, datasetId, uri, false, false);

        return assignedReqID;
    }

    function fulfill(
        bytes32 requestId,
        bytes memory uriOwnerBytes
    ) public recordChainlinkFulfillment(requestId) {
        address uriOwner = bytesToAddress(uriOwnerBytes);

        if (uriOwner == requestData[requestId].owner) {
            requestData[requestId].verified = true;
        }

        requestData[requestId].fulfilled = true;
        emit OracleResult(requestId, uriOwner);
    }

    function bytesToAddress(bytes memory b) private pure returns (address addr) {
        assembly {
        addr := mload(add(b,20))
        }
    }

    function createDataNFT(bytes32 requestId, string memory name, string memory symbol) public returns (address) {
        RequestData storage data = requestData[requestId];
        require(data.fulfilled == true && data.verified == true, "verify dataset ownership first");
        require(data.owner == msg.sender, "you are not the owner of the dataset");

        DataNFT dataset = new DataNFT(name, symbol);
        dataIdToNftAddress[data.datasetId] = address(dataset);
        return address(dataset);
    }
}