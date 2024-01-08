// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface IWETH {
    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    function deposit() external payable;
    function withdraw(uint wad) external;
    function totalSupply() external view returns (uint);
    function approve(address guy, uint wad) external returns (bool);
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external;

}

contract CollateralContractV2 is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    // IERC20 public collateralToken;
    address public wethAddress;

    mapping(address => bool) public isAdmin;
    mapping(address => uint) public balances;

    event Deposit(address fundingWallet, address receivingWallet, uint depositAmount);
    event Withdraw(address fundingWallet, uint withdrawAmount);
    event LockCollateral(address taskContract, address[] cpList, uint collateralAmount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    receive() external payable {
        IWETH(wethAddress).deposit{value: msg.value}();

        balances[msg.sender] += msg.value;
    }

    function initialize(address tokenAddress) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();

        wethAddress = tokenAddress;
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

    function deposit(address recipient, uint amount) public {
        require(IERC20(wethAddress).allowance(msg.sender, address(this)) >= amount, "Please approve spending funds.");
        require(IERC20(wethAddress).balanceOf(msg.sender) >= amount, "Insufficient funds.");

        IERC20(wethAddress).transferFrom(msg.sender, address(this), amount);
        balances[recipient] += amount;

        emit Deposit(msg.sender, recipient, amount);
    }
    
    /**
     * @param amount - amount to withdraw
     * @notice - withdraws tokens from the contract
     * @dev - checks user's balance in contract before withdrawing
     */
    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount, "Withdraw amount exceeds balance");

        balances[msg.sender] -= amount;

        IWETH(wethAddress).withdraw(amount);
        payable(msg.sender).transfer(amount);

        emit Withdraw(msg.sender, amount);
    }

    /**
     * @param taskContract - the created task contract address
     * @param cpList - list of all the cps on this task
     * @param collateral - collateral amount
     * @notice - the bidding contract will move funds deposited by the CPs here to the task contract as collateral
     * @dev - checks the balance of each cp in the list to make sure there is enough funds deposited
     */
    function lockCollateral(address taskContract, address[] memory cpList, uint collateral) public onlyAdmin {
        for (uint i = 0; i < cpList.length; i++) {
            require(balances[cpList[i]] >= collateral, 'Not enough balance for collateral');
            balances[cpList[i]] -= collateral;
        }

        IERC20(wethAddress).transfer(taskContract, cpList.length * collateral);

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
}