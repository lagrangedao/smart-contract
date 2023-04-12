// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/dev/functions/FunctionsClient.sol";

contract LagrangeChainlinkData is
    ERC721,
    ERC721URIStorage,
    FunctionsClient,
    Ownable
{
    using Functions for Functions.Request;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint64 private subscriptionId; // need to fund this subscription with LINK tokens
    string public source; // js code to call GET request
    address public oracleAddress;

    struct RequestData {
        address minter;
        string uri;
        bool fulfilled;
    }

    mapping(bytes32 => RequestData) public requestData;

    bytes32 public latestRequestId;
    bytes public latestResponse;
    bytes public latestError;

    event OCRResponse(bytes32 indexed requestId, bytes result, bytes err);
    event URIUpdate(uint tokenId, string uri);

    constructor(
        address oracle,
        uint64 _subscriptionId,
        string memory _source
    ) ERC721("Lagrange Data", "LDNFT") FunctionsClient(oracle) {
        subscriptionId = _subscriptionId;
        source = _source;
        oracleAddress = oracle;
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

    // sends chainlink request
    // and the token gets minted (if api returns true) in the fulfill function
    // args[0] msg.sender
    // args[1] metadata uri
    // TODO: args is string array because sendRequests takes args array
    // TODO: mint should take (cid), create a array of cid and msg.sender
    function mint(string memory uri, uint32 gasLimit) public returns (bytes32) {
        string[] memory args = new string[](2);
        args[0] = addressToString(msg.sender);
        args[1] = uri;

        // sends the chainlink request to call API, returns reqID
        Functions.Request memory req;
        req.initializeRequestForInlineJavaScript(source);
        req.addArgs(args);
        bytes32 assignedReqID = sendRequest(req, subscriptionId, gasLimit);
        latestRequestId = assignedReqID;

        // stores the req info in the mapping (we need to access this info to mint later)
        requestData[assignedReqID] = RequestData(msg.sender, uri, false);

        return assignedReqID;
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        require(response.length > 0 && err.length > 0);
        // if the response is true (meaning the minter is the owner of the dataset)
        require(bytesToBool(response) == true);

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        _safeMint(requestData[requestId].minter, tokenId);
        _setTokenURI(tokenId, requestData[requestId].uri);

        requestData[requestId].fulfilled = true;

        emit OCRResponse(requestId, response, err);
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
