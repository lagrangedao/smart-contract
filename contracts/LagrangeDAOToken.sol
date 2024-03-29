// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract SwanTokenUpgradeable is Initializable, ERC20CappedUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    uint public constant TOKEN_CAP = 1 ether * 10 ** 9;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __Ownable_init();
        __ERC20_init("Swan Token", "SWAN");
        __ERC20Capped_init(TOKEN_CAP);
        __UUPSUpgradeable_init();
    }

    function mint(address to, uint amount) public onlyOwner {
        _mint(to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}