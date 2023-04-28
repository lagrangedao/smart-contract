// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./DataNFT.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DataNFTFactory
 * @author 
 * @notice Creates ERC721 and ERC20 contracts
 * ERC721 contracts are DataNFTs representing one dataset
 * ERC721 Tokens within each contract represent versioning
 * ERC721 Tokens can accept certain ERC20 tokens as datatokens
 */
contract DataNFTFactory is ChainlinkClient, Ownable {
    using Chainlink for Chainlink.Request;

    bytes32 private jobId;
    uint256 private fee;
    address public oracleAddress;

    struct RequestData {
        address owner;
        // uint datasetId;
        string uri;
        bool deployable;
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
     * @notice this function will not deploy the contract, it will set 
     * RequestData.deployable to true, so the user needs to call 
     * CreateDataNFT to deploy. This is to avoid out of gas error from oracle.
     * @return requestId - analogous to placing an order and getting an order#
     * users can refer to requestData[requestId] to "track" progress
     */
    function requestDataNFT(
            // uint datasetId, 
            string memory uri
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
                false,
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
        address uriOwner = bytesToAddress(uriOwnerBytes);

        requestData[requestId].deployable = uriOwner == requestData[requestId].owner;
        requestData[requestId].fulfilled = true; // the oracle processed the request (regardless of result)

        emit OracleResult(requestId, requestData[requestId].deployable);
    }

    function createDataNFT( bytes32 requestId, string memory name, string memory symbol) public {
            DataNFT dataset = new DataNFT(name, symbol);
            uriToNftAddress[requestData[requestId].uri] = address(dataset);
            emit DeployNFT(requestData[requestId].uri, address(dataset));
    }

    function bytesToAddress(bytes memory b) private pure returns (address addr) {
        assembly {
        addr := mload(add(b,20))
        }
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}