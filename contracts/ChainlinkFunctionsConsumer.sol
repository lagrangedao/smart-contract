// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";


interface IERC721 {
    function safeMint(address to, string memory uri) external;
}

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */
contract Generator is FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;

    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;
    string public source;
    bytes encryptedSecretsUrls;
    uint8 donHostedSecretsSlotID;
    uint64 donHostedSecretsVersion;
    bytes[] bytesArgs;
    uint64 subscriptionId;

    uint32 gasLimit;
    bytes32 donID;

    address public nftContract;
    mapping(bytes32 => address) public recipient;
    mapping(bytes32 => string) public result;
    mapping(bytes32 => bool) public mintable;
    mapping(string => bytes32) public nameToId;


    error UnexpectedRequestID(bytes32 requestId);

    event Response(bytes32 indexed requestId, bytes response, bytes err);

    constructor(
        string memory sourceCode,
        bytes32 donId,
        address nftCollection
    ) FunctionsClient(0x6E2dc0F9DB014aE19888F539E59285D2Ea04244C) {
        source = sourceCode;
        encryptedSecretsUrls = '0x';
        donHostedSecretsSlotID = 0;
        donHostedSecretsVersion = 0;
        subscriptionId = 1138;
        gasLimit = 300000;
        donID = donId;
        nftContract = nftCollection;
    }

    function getResult(string memory name) public view returns(string memory) {
        return result[nameToId[name]];
    }

    /**
     * @notice Send a simple request
     */
    function sendRequest(
        string memory name, string memory desc, string memory image_url
    ) external returns (bytes32 requestId) {
        string[] memory args = new string[](3);
        args[0] = name;
        args[1] = desc;
        args[2] = image_url;

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);
        req.setArgs(args);
        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donID
        );

        nameToId[name] = s_lastRequestId;
        recipient[s_lastRequestId] = msg.sender;

        return s_lastRequestId;
    }

    /**
     * @notice Store latest result/error
     * @param requestId The request ID, returned by sendRequest()
     * @param response Aggregated response from the user code
     * @param err Aggregated error from the user code or from the execution pipeline
     * Either response or error parameter will be set, but never both
     */
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId);
        }
        s_lastResponse = response;
        s_lastError = err;
        result[requestId] = string(err);

        if (response.length > 0) {
            string memory uri = string(response);
            result[requestId] = uri;
            mintable[requestId] = true;
            // IERC721(nftContract).safeMint(recipient[requestId], result[requestId]);
        }

        emit Response(requestId, s_lastResponse, s_lastError);
    }

    function mint(string memory name) public {
        bytes32 id = nameToId[name];
        require (msg.sender == recipient[id], 'sender is not recipient');
        require (mintable[id], 'requestId not mintable');

        mintable[id] = false;

        IERC721(nftContract).safeMint(recipient[id], result[id]);
    }
}
