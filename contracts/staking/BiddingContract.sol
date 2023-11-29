// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Swap.sol";
import "./Task.sol";
import "./CollateralContract.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract BiddingContract is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    
    CollateralContract collateralContract;
    address implementation;
    address arWallet;
    address apWallet;
    IERC20 paymentToken;
    IERC20 rewardToken; 
    TokenSwap tokenSwap;

    mapping(address => bool) isAdmin;
    mapping(string => address) public tasks;
    
    event TaskCreated(string taskId, address taskContractAddress);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address ar, address ap, address collateralContractAddress, address paymentTokenAddress, address rewardTokenAddress, address swapContractAddress) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();

        collateralContract = CollateralContract(collateralContractAddress);
        paymentToken = IERC20(paymentTokenAddress);
        rewardToken = IERC20(rewardTokenAddress);
        tokenSwap = TokenSwap(swapContractAddress);
        arWallet = ar;
        apWallet = ap;
        isAdmin[msg.sender] = true;
        implementation = address(new Task());
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

    
    function assignTask(string memory taskId, address user, address[] memory cpList, uint rewardInUsdc, uint collateral, uint duration) public onlyAdmin {
        address clone = Clones.clone(implementation);
        tasks[taskId] = clone;

        uint rewardForCp = rewardInUsdc * 95/100;

        paymentToken.transferFrom(apWallet, address(this), rewardForCp);
        uint rewardInSwan = tokenSwap.swapUsdcToSwan(rewardForCp);

        collateralContract.lockCollateral(clone, cpList, collateral);
        rewardToken.transfer(clone, rewardInSwan);

        Task(clone).initialize(msg.sender, user, cpList, rewardForCp, rewardInSwan, collateral, duration);
    
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
}
