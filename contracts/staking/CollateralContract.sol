// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract CollateralContract is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    mapping(address => bool) public isAdmin;
    mapping(address => uint) public balances;
    mapping(address => uint) public taskBalance;
    mapping(address => uint) public frozenBalance;

    event Deposit(address fundingWallet, address receivingWallet, uint depositAmount);
    event Withdraw(address fundingWallet, uint withdrawAmount);
    event LockCollateral(address taskContract, address[] cpList, uint collateralAmount);
    event UnlockCollateral(address taskContract, address cp, uint collateralAmount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();

        isAdmin[msg.sender] = true;
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

    receive() external payable {
        deposit(msg.sender);
    }

    /**
     * @notice - deposits tokens into the contract
     */
    function deposit(address recipient) public payable {
        balances[recipient] += msg.value;

        emit Deposit(msg.sender, recipient, msg.value);
    }
    
    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount, "Withdraw amount exceeds balance");

        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);

        emit Withdraw(msg.sender, amount);
    }

    function lockCollateral(address taskContract, address[] memory cpList, uint collateral) public onlyAdmin {
        for (uint i = 0; i < cpList.length; i++) {
            require(balances[cpList[i]] >= collateral, 'Not enough balance for collateral');
        }

        for (uint i = 0; i < cpList.length; i++) {
            balances[cpList[i]] -= collateral;
            frozenBalance[cpList[i]] += collateral;
        }

        uint totalCollateral = cpList.length * collateral;
        taskBalance[taskContract] += totalCollateral;

        emit LockCollateral(taskContract, cpList, collateral);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function version() public pure returns(uint) {
        return 1;
    }

    function unlockCollateral(address recipient, uint amount) public {
        require(taskBalance[msg.sender] >= amount, "task has no balance");
        taskBalance[msg.sender] -= amount;
        frozenBalance[recipient] -= amount;
        balances[recipient] += amount;

        emit UnlockCollateral(msg.sender, recipient, amount);
    }
}
