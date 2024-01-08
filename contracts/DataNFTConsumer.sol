// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./DataNFT.sol";

contract DataNFTFactoryConsumer is
    ChainlinkClient,
    Ownable
{
    using Chainlink for Chainlink.Request;

    bytes32 public jobId = 'fb6846302d324792955cb3623f636088';
    uint256 public fee = 0.1 ether;

    string public baseUrl = "https://api.lagrangedao.org/";
    string public targetPath = "data,ipfs_url";

    address private implementation;

    enum RequestType {Datasets, Spaces}

    struct RequestData {
        address requestor;
        string datasetName;
        string uri;
        bool fulfilled;
        bool claimable;
    }

    struct RequestArguements {
        RequestType requestType; // 0 = dataset, 1 = space
        address requestor;
        string assetName;
    }

    mapping(bytes32 => RequestArguements) public idToArgs;
    mapping(RequestType => mapping(address => mapping(string => RequestData))) public requestData;
    mapping(RequestType => mapping(address => mapping(string => address))) public dataNFTAddresses;

    event OracleResult(bytes32 indexed requestId, string uri);
    event CreateDataNFT(address indexed owner, string datasetName, address dataNFTAddress);
    
    constructor() {
        setChainlinkToken(0xb0897686c545045aFc77CF20eC7A532E3120E0F1);
        setChainlinkOracle(0x9F306bB9da1a12bF1590d3EA65e038fC414d6b68);

        implementation = address(new DataNFT());
    }

    function requestDataNFT(RequestType requestType, string memory datasetName) public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        // BUILD URL
        string memory urlWithType;
        if (requestType == RequestType.Datasets) {
            urlWithType = concat(baseUrl, 'datasets/');
        } else if (requestType == RequestType.Spaces) {
            urlWithType = concat(baseUrl, 'spaces/');
        } else {
            revert("Invalid request type");
        }
        string memory urlWithAddress = concat(concat(urlWithType, addressToString(msg.sender)), "/");
        string memory urlWithDataset = concat(concat(urlWithAddress, datasetName), "/generate_metadata");

        req.add("url", urlWithDataset);
        req.add("path", targetPath);

        bytes32 assignedReqID = sendChainlinkRequest(req, fee);
        idToArgs[assignedReqID] = RequestArguements(requestType, msg.sender, datasetName);
        RequestData storage data = requestData[requestType][msg.sender][datasetName];
        data.requestor = msg.sender;
        data.datasetName = datasetName;
        data.fulfilled = false;
        data.claimable = false;

        return assignedReqID;
    }

    function fulfill(
        bytes32 requestId,
        bytes memory uriBytes
    ) public recordChainlinkFulfillment(requestId) {
        RequestArguements memory args = idToArgs[requestId];
        RequestData storage data = requestData[args.requestType][args.requestor][args.assetName];

        data.fulfilled = true;

        if (uriBytes.length > 0) {
            data.uri = string(uriBytes);
            data.claimable = true;
        }

        emit OracleResult(requestId, string(uriBytes));
    }

    function claimDataNFT(RequestType requestType, string memory datasetName) public {
        RequestData storage data = requestData[requestType][msg.sender][datasetName];
        require(data.claimable, "this dataNFT is not claimable yet");
        address clone = Clones.clone(implementation);
        DataNFT(clone).initialize(data.requestor, data.datasetName, data.uri);

        dataNFTAddresses[requestType][data.requestor][data.datasetName] = clone;
        emit CreateDataNFT(data.requestor, data.datasetName, clone);
    }

    function concat(string memory a, string memory b) public pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function addressToString(
        address _address
    ) public pure returns (string memory) {
        bytes20 _bytes = bytes20(_address);
        bytes16 _hexAlphabet = "0123456789abcdef";
        bytes memory _stringBytes = new bytes(42);
        _stringBytes[0] = "0";
        _stringBytes[1] = "x";
        for (uint i = 0; i < 20; i++) {
            uint _byte = uint8(_bytes[i]);
            _stringBytes[2 + i * 2] = _hexAlphabet[_byte >> 4];
            _stringBytes[3 + i * 2] = _hexAlphabet[_byte & 0x0f];
        }
        return string(_stringBytes);
    }

    function setOracleAddress(address oracle) public onlyOwner {
        setChainlinkOracle(oracle);
    }

    function getOracle() public view returns (address) {
        return chainlinkOracleAddress();
    }

    function setLinkToken(address token) public onlyOwner {
        setChainlinkToken(token);
    }


    function setJobId(bytes32 job) public onlyOwner {
        jobId = job;
    }

    function setFee(uint _fee) public onlyOwner {
        fee = _fee;
    }

    function setBaseUrl(string memory url) public onlyOwner {
        baseUrl = url;
    }

    function setPath(string memory newPath) public onlyOwner {
        targetPath = newPath;
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function withdraw(address tokenAddress) public onlyOwner {
        LinkTokenInterface token = LinkTokenInterface(tokenAddress);
        require(
            token.transfer(msg.sender, token.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
} 