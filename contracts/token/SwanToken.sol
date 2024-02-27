// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract SwanToken is Initializable, ERC20CappedUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    uint public constant TOKEN_CAP = 1 ether * 10 ** 9;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address investor, address treasury, address team, address market) initializer public {
        __Ownable_init();
        __ERC20_init("Swan Token", "SWAN");
        __ERC20Capped_init(TOKEN_CAP);
        __UUPSUpgradeable_init();

        _mint(investor, TOKEN_CAP / 100 * 25);
        _mint(treasury, TOKEN_CAP / 100 * 40);
        _mint(team, TOKEN_CAP / 100 * 15);
        _mint(market, TOKEN_CAP / 100 * 20);
    }

    // function mint(address to, uint amount) public onlyOwner {
    //     _mint(to, amount);
    // }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}