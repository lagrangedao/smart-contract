// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */
contract SourceMinter is Ownable {

    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
    error NotEnoughAllowance(uint256 currentAllowance, uint256 calculatedFees);

    IERC20 linkToken;
    IRouterClient router;

    address destinationMinter;
    uint public latestMessageFee;

    event MessageSent(bytes32 messageId, address caller, address collection, uint tokenId, uint gasLimit);

    constructor(address _router, address token) {
        router = IRouterClient(_router);
        linkToken = IERC20(token);
        linkToken.approve(_router, type(uint256).max);
    }

    function copyNFT(uint64 destinationChainSelector, address collection, uint tokenId, uint gasLimit) external returns(bytes32 messageId) {
        require(IERC721Metadata(collection).ownerOf(tokenId) == msg.sender, "incorrect nft owner");
        
        string memory name = IERC721Metadata(collection).name();
        string memory symbol = IERC721Metadata(collection).symbol();
        string memory uri = IERC721Metadata(collection).tokenURI(tokenId);

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(destinationMinter),
            data: abi.encode(msg.sender, collection, name, symbol, tokenId, uri),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit and non-strict sequencing mode
                Client.EVMExtraArgsV1({gasLimit: gasLimit, strict: false})
            ),
            feeToken: address(linkToken)
        });

        uint256 fees = router.getFee(destinationChainSelector, message);
        latestMessageFee = fees;

        if (fees > linkToken.balanceOf(msg.sender))
            revert NotEnoughBalance(linkToken.balanceOf(msg.sender), fees);

        if (fees > linkToken.allowance(msg.sender, address(this)))
            revert NotEnoughAllowance(linkToken.allowance(msg.sender, address(this)), fees);

        linkToken.transferFrom(msg.sender, address(this), fees);


        // Send the CCIP message through the router and store the returned CCIP message ID
        messageId = router.ccipSend(
            destinationChainSelector,
            message
        );

        emit MessageSent(messageId, msg.sender, collection, tokenId, gasLimit);

        // Return the CCIP message ID
        return messageId;
    }

    function setDestinationMinter(address minter) public onlyOwner {
        destinationMinter = minter;
    }
}