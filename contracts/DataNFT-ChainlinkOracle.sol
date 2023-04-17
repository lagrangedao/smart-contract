// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract LagrangeChainlinkDataConsumer is
    ERC721,
    ERC721URIStorage,
    ChainlinkClient,
    Ownable
{
    using Chainlink for Chainlink.Request;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    bytes32 private jobId;
    uint256 private fee;
    address public oracleAddress;

    struct RequestData {
        address minter;
        string uri;
        bool fulfilled;
    }

    mapping(bytes32 => RequestData) public requestData;

    event OracleResult(bytes32 indexed requestId, address uriOwner);
    event URIUpdate(uint tokenId, string uri);

    constructor(
        address linkTokenAddress,
        address _oracleAddress,
        uint _fee
    ) ERC721("Lagrange Data", "LDNFT") {
        setChainlinkToken(linkTokenAddress);
        setChainlinkOracle(_oracleAddress);
        oracleAddress = _oracleAddress;
        jobId = '7da2702f37fd48e5b1b9a5715e3509b6';
        fee = _fee; // 0,1 * 10**18 (Varies by network and job)
    }

    function bytesToAddress(bytes memory b) private pure returns (address addr) {
        assembly {
        addr := mload(add(b,20))
        }
    }

    // sends chainlink request
    // and the token gets minted (if api returns true) in the fulfill function
    // args[0] msg.sender
    // args[1] metadata uri
    // TODO: args is string array because sendRequests takes args array
    // TODO: mint should take (cid), create a array of cid and msg.sender
    function mint(string memory uri) public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        req.add("get", uri);
        req.add("path", "owner");


        bytes32 assignedReqID = sendChainlinkRequest(req, fee);
        requestData[assignedReqID] = RequestData(msg.sender, uri, false);

        return assignedReqID;
    }

    function fulfill(
        bytes32 requestId,
        bytes memory uriOwnerBytes
    ) public recordChainlinkFulfillment(requestId) {
        // if the response is true (meaning the minter is the owner of the dataset)
        // then mint the nft to the user
        address uriOwner = bytesToAddress(uriOwnerBytes);
        if (uriOwner == requestData[requestId].minter) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();

            _safeMint(requestData[requestId].minter, tokenId);
            _setTokenURI(tokenId, requestData[requestId].uri);
        }

        // update requestData information
        requestData[requestId].fulfilled = true;

        emit OracleResult(requestId, uriOwner);
    }

    // The following functions are overrides required by Solidity.

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function updateURI(uint tokenId, string memory uri) public {
        require(ownerOf(tokenId) == msg.sender, "caller is not owner");
        _setTokenURI(tokenId, uri);

        emit URIUpdate(tokenId, uri);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        //require(uriAccess[msg.sender][tokenId], "caller does not have access");
        return super.tokenURI(tokenId);
    }

    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

}
