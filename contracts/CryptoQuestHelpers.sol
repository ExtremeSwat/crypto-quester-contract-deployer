// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

contract CryptoQuestHelpers {

    // Add the library methods
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    /// Sender not authorized for this
    /// operation.
    error Unauthorized();

    enum ChallengeStatus {
        Archived,
        Draft,
        Published,
        Finished
    }

    struct ParticipantCheckpointTrigger {
        uint256 checkpointId;
    }

    // used to signal a checkpoint
    struct ChallengeCheckpoint {
        uint256 checkpointId;
        uint256 order;
        bool isUserInputRequired;
        string userInputAnswer;
        bool exists;
    }

    struct Challenge {
        address ownerAddress;
        uint256 fromTimestamp;
        uint256 toTimestamp;
        ChallengeStatus challengeStatus;
        ChallengeCheckpoint[] challengeCheckpoints;
        uint256 lastOrder;
        uint256 lastCheckpointId;
        address winnerAddress;
    }

     // challengeOwners
    mapping(address => mapping(uint256 => bool)) challengeOwners;

    // challengeId ==> userAddress --> isParticipating
    mapping(uint256 => mapping(address => bool)) challengeParticipants;

    // challengeId ==> userAddress --> last hit checkpoint id
    mapping(uint256 => mapping(address => uint256)) participantHitTriggers;

    // challengeId ==> challengeCheckpointId --> completed
    mapping(uint256 => mapping(uint256 => bool)) participantHasHitTriggers;
    
    //platform users
    EnumerableMap.AddressToUintMap users;

    Challenge[] public challenges;

    function checkChallengeIsOwnedBySender(Challenge memory challenge) internal {
        if (challenge.ownerAddress != msg.sender) revert Unauthorized();
    }

    modifier isParticipatingInChallenge(uint256 challengeId) {
        if (!challengeParticipants[challengeId][msg.sender])
            revert Unauthorized();

        _;
    }

    modifier isChallengeOwned(uint256 challengeId) {
        if (!challengeOwners[msg.sender][challengeId]) {
            revert Unauthorized();
        }

        _;
    }

    modifier onlyRegisteredUsers() {
        if (!users.contains(msg.sender)) revert Unauthorized();

        _;
    }
}
