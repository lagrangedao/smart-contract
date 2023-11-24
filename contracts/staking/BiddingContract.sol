// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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
    mapping(address => bool) isAdmin;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address ar, address ap, address collateralContractAddress, address paymentTokenAddress, address rewardTokenAddress) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();

        collateralContract = CollateralContract(collateralContractAddress);
        paymentToken = IERC20(paymentTokenAddress);
        rewardToken = IERC20(rewardTokenAddress);
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

    
    function assignTask(address user, address[] memory cpList, uint reward, uint collateral, uint duration) public onlyAdmin {
        address clone = Clones.clone(implementation);
        Task(clone).initialize(user, cpList, arWallet, apWallet, reward, collateral, duration);

        collateralContract.lockCollateral(clone, cpList, collateral);
        rewardToken.transferFrom(apWallet, clone, reward);
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
