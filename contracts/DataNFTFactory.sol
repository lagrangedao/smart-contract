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
        // uint datasetId;
        string uri;
        string name;
        string symbol;
        address contractAddress;
        bool fulfilled;
    }
    mapping(bytes32 => RequestData) public requestData;
    // mapping(uint => address) public dataIdToNftAddress;
    mapping(string => address) public uriToNftAddress;

    event OracleResult(bytes32 indexed requestId, bool isOwner);
    event DeployNFT(string uri, address contractAddress);

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
     * @dev The deployed contract stores Metadata, ownership, sub-license 
     * information, permissions.
     * @notice Users call this function to request Chainlink Oracle to 
     * deploy your dataNFT contract. The oracle will verify the sender is the 
     * owner of the dataset
     * @return requestId - analogous to placing an order and getting an order#
     * users can refer to requestData[requestId] to "track" progress
     */
    function requestDataNFT(
            // uint datasetId, 
            string memory uri, 
            string memory name, 
            string memory symbol
        ) public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        req.add("get", uri);
        req.add("path", "owner");


        bytes32 assignedReqID = sendChainlinkRequest(req, fee);
        requestData[assignedReqID] = RequestData(
                msg.sender, 
                // datasetId, 
                uri, 
                name, 
                symbol, 
                address(0), 
                false
            );

        return assignedReqID;
    }

    /**
     * @notice this function should only be called by the oracle
     * if the requester was the owner of the dataset, it will deploy DataNFT
     * and emit an event containing the contract address
     * @dev currently verifying ownership via owner parameter in the passed uri
     */
    function fulfill(
        bytes32 requestId,
        bytes memory uriOwnerBytes
    ) public recordChainlinkFulfillment(requestId) {
        require(msg.sender == oracleAddress, "only called by oracle");

        requestData[requestId].fulfilled = true; // the oracle processed the request (regardless of result)
        address uriOwner = bytesToAddress(uriOwnerBytes);

        if (uriOwner == requestData[requestId].owner) {
            RequestData storage data = requestData[requestId];
            DataNFT dataset = new DataNFT(data.name, data.symbol);
            data.contractAddress = address(dataset);
            uriToNftAddress[data.uri] = address(dataset);
            emit DeployNFT(data.uri, data.contractAddress);
        }

        emit OracleResult(requestId, uriOwner == requestData[requestId].owner);
    }

    function bytesToAddress(bytes memory b) private pure returns (address addr) {
        assembly {
        addr := mload(add(b,20))
        }
    }
}