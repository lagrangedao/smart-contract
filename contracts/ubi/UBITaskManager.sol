// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract UBITaskManager is Initializable, OwnableUpgradeable, UUPSUpgradeable{
    
    uint challengeDuration;

    mapping(address => bool) isAdmin;
    mapping(address => bool) isChallenger;
    mapping(string => Task) public tasks;

    struct Task {
        address cp;
        string nodeId;
        uint taskId;
        string taskUid;
        string taskUri;
        string proof;
        uint8 taskType;
        bool isCompleted;
        uint challengeDeadline;
        uint claimableAmount;
    }

    event TaskAssigned(string taskUid, address cp, string taskUri);
    event ProofSubmitted(string taskUid, string proof);

    event RewardSet(string taskUid, uint rewardAmount);
    event RewardClaimed(string taskUid, uint rewardAmount);


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

     // Modifier to check if the caller is the admin
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only the admin can call this function.");
        _;
    }
    modifier onlyChallenger() {
        require(isChallenger[msg.sender], "Only the Challenger can call this function.");
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        
        isAdmin[msg.sender] = true;
        challengeDuration = 1 days;
    }

    function setChallengeDuration(uint duration) public onlyOwner {
        challengeDuration = duration;
    }

    function addAdmin(address admin) public onlyOwner {
        isAdmin[admin] = true;
    }

    function removeAdmin(address admin) public onlyOwner {
        isAdmin[admin] = false;
    }
    
    function addChallenger(address challenger) public onlyOwner {
        isAdmin[challenger] = true;
    }

    function removeChallenger(address challenger) public onlyOwner {
        isAdmin[challenger] = false;
    }

    function assignUBITask(string memory taskUid, address cpAddress, string memory nodeId, string memory taskUri) public onlyAdmin {
        require(tasks[taskUid].cp == address(0), 'task already assigned');
        tasks[taskUid].cp = cpAddress;
        tasks[taskUid].nodeId = nodeId;
        tasks[taskUid].taskUid = taskUid;
        tasks[taskUid].taskUri = taskUri;

        emit TaskAssigned(taskUid, cpAddress, taskUri);
    }
    function submitUBIProof(address cpAddress, string memory nodeID, string memory taskUid, uint taskId, uint8 taskType, string memory proof) public {
        require(tasks[taskUid].cp == msg.sender, 'caller is not the assigned cp');
        tasks[taskUid].taskType = taskType;
        tasks[taskUid].taskId = taskId;
        tasks[taskUid].proof = proof;
        tasks[taskUid].isCompleted = true;
        tasks[taskUid].challengeDeadline = block.timestamp + challengeDuration;

        emit ProofSubmitted(taskUid, proof);
    }

    // function submitChallenge() public onlyChallenger {}
    function setReward(string memory taskUid, uint amount) public onlyAdmin {
        tasks[taskUid].claimableAmount = amount;

        emit RewardSet(taskUid, amount);
    }
    function claimReward(string memory taskUid) public {
        require(tasks[taskUid].cp == msg.sender, 'caller is not the assigned cp');
        require(tasks[taskUid].isCompleted, 'task is not complete');
        require(block.timestamp >= tasks[taskUid].challengeDeadline, 'still within the challenge window');
        require(address(this).balance >= tasks[taskUid].claimableAmount, 'not enought contract balance');

        uint claimAmount = tasks[taskUid].claimableAmount;
        tasks[taskUid].claimableAmount = 0;
        payable(msg.sender).transfer(claimAmount);

        emit RewardClaimed(taskUid, claimAmount);
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
