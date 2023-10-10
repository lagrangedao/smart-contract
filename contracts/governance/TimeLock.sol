// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/governance/TimelockController.sol";

contract TimeLock is TimelockController {
    constructor (
        uint minDelay, // how long to wait before executing
        address[] memory proposers, // list of addresses that can propose
        address[] memory executors,
        address admin
    ) TimelockController(minDelay, proposers, executors, admin) {

    }
}