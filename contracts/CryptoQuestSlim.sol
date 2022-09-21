// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

contract CryptoQuest_Slim {
    // Add the library methods
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    //platform users
    EnumerableMap.AddressToUintMap users;
    mapping(uint256 => Challenge) challenges;

    /// Sender not authorized for this
    /// operation.
    error Unauthorized();

    // used to signal participant's progress
    struct ChallengeParticipantTrigger {
        uint256 checkpointTriggerId;
    }

    // used to signal participant 
    struct ChallengeParticipant {
        uint256 participantAddress;
        ChallengeParticipantTrigger[] participantCheckpointTriggers;
    }

    // used to signal a checkpoint 
    struct ChallengeCheckpoints {
        uint256 checkpointId;
        uint256 order;

        bool isUserInputRequired;
        string userInputAnswer;
    }

    struct Challenge {
        

        uint256 challengeId;
        address ownerAddress;

        uint256 fromTimestamp;
        uint256 toTimestamp;

        ChallengeCheckpoints[] challengeCheckpoints;
        ChallengeParticipant[] challengeParticipants;
    }

    function createChallenge() public returns (uint256) {
        
    }

    function registerUser() public {
        if(users.contains(msg.sender))
            revert Unauthorized();

        uint256 index = users.length() + 1;
        users.set(msg.sender, index);
    }

    modifier onlyRegisteredUsers() {
        if(!users.contains(msg.sender))
            revert Unauthorized();

        _;
    }
}