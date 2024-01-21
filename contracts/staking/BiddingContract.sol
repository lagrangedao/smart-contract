// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./Task.sol";
import "./CollateralContract.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract BiddingContract is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    
    CollateralContract public collateralContract;
    address public implementation;
    address public arWallet;
    address public apWallet;
    IERC20 public paymentToken;
    // IERC20 public rewardToken; 
    // IUniswapV2Router02 public uniswapRouter;
    // uint public swapTime;
    // address[] public swapPath;
    

    mapping(address => bool) public isAdmin;
    mapping(string => address) public tasks;
    
    event TaskCreated(string taskId, address taskContractAddress);

    uint public refundClaimDuration;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address ar, address ap, address collateralContractAddress, address paymentTokenAddress
        // address rewardTokenAddress, address swapContractAddress
        ) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();

        collateralContract = CollateralContract(collateralContractAddress);
        paymentToken = IERC20(paymentTokenAddress);
        // rewardToken = IERC20(rewardTokenAddress);
        // uniswapRouter = IUniswapV2Router02(swapContractAddress);
        arWallet = ar;
        apWallet = ap;
        isAdmin[msg.sender] = true;
        implementation = address(new Task());

        // swapTime = 2 hours;
        // swapPath = [paymentTokenAddress, rewardTokenAddress];

        // paymentToken.approve(swapContractAddress, type(uint256).max);
    }

    // Modifier to check if the caller is the admin
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only the admin can call this function.");
        _;
    }

    function addAdmin(address newAdmin) public onlyOwner {
        isAdmin[newAdmin] = true;
    }

    function removeAdmin(address admin) public onlyOwner {
        isAdmin[admin] = false;
    }

    function setImplementation(address newImplementation) public onlyOwner {
        implementation = newImplementation;
    }

    function setRefundClaimDuration(uint claimDuration) public onlyOwner {
        refundClaimDuration = claimDuration;
    }
    
    function assignTask(string memory taskId, address[] memory cpList, uint reward, uint collateral, uint duration) public onlyAdmin {
        require(tasks[taskId] == address(0), "taskId already assigned");
        address clone = Clones.clone(implementation);
        tasks[taskId] = clone;

        // uint rewardInSwan = 0;

        if (reward > 0) {
            paymentToken.transferFrom(apWallet, clone, reward);
            // paymentToken.approve(address(uniswapRouter), rewardInUsdc);
            // uint[] memory swapOutput = uniswapRouter.swapExactTokensForTokens(rewardInUsdc, 0, swapPath, clone, block.timestamp + swapTime);
            // rewardInSwan = swapOutput[1];
        }

        collateralContract.lockCollateral(clone, cpList, collateral);

        Task(clone).initialize(msg.sender, cpList, reward, collateral, duration, refundClaimDuration);
    
        emit TaskCreated(taskId, clone);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function version() public pure returns(uint) {
        return 1;
    }

    function setCollateralContract(address newCollateralContract) public onlyOwner {
        collateralContract = CollateralContract(newCollateralContract);
    }
}
