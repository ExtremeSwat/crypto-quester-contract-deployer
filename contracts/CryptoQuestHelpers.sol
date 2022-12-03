// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CryptoQuestHelpers {
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

    struct ChallengeCheckpoint {
        uint256 checkpointId;
        uint256 order;
        bool exists;

        uint256 checkpointTriggerId;
        bool checkpointTriggerExists;
    }

    struct Challenge {
        uint256 challengeId;
        address ownerAddress;
        uint256 fromTimestamp;
        uint256 toTimestamp;
        ChallengeStatus challengeStatus;
        uint256 lastOrder;
        uint256 lastCheckpointId;
        address winnerAddress;
    }
    
     // challengeOwners
    mapping(uint256 => Challenge) challenges;
    mapping(uint256 => ChallengeCheckpoint[]) challengeCheckpoints;
    //Challenge[] public challenges;

    mapping(address => mapping(uint256 => bool)) challengeOwners;
    mapping(uint256 => uint256) challengeNumberOfCheckpoints;

    // challengeId ==> userAddress --> isParticipating
    mapping(uint256 => mapping(address => bool)) challengeParticipants;

    // challengeId ==> userAddress --> last hit checkpoint id
    mapping(uint256 => mapping(address => uint256)) participantHitTriggers;

    // challengeId ==> challengeCheckpointId --> completed
    mapping(uint256 => mapping(uint256 => bool)) participantHasHitTriggers;

    // users
    mapping(address => bool) users;

    modifier isParticipatingInChallenge(uint256 challengeId) {
        if (!challengeParticipants[challengeId][msg.sender])
            revert Unauthorized();

        _;
    }

    modifier isChallengeOwned(uint256 challengeId) {
        console.log("Is challengeId: %s is owned by %s = %s", Strings.toString(challengeId), msg.sender,challengeOwners[msg.sender][challengeId]);
        
        require(challengeOwners[msg.sender][challengeId]);

        _;
    }

    modifier onlyRegisteredUsers() {
        if (!users[msg.sender]) revert Unauthorized();

        _;
    }

    modifier checkChallengeEditability(uint256 challengeId) {
        require(
            challenges[challengeId].toTimestamp > block.timestamp,
            "Cannot alter a challenge in past !"
        );

        require(
            challenges[challengeId].challengeStatus == ChallengeStatus.Draft,
            "Can only alter drafts !"
        );

       _;
    }

    function getChallengeCheckpointIndex(
        uint256 checkpointId,
        ChallengeCheckpoint[] memory checkpoints
    ) internal pure returns (uint256 challengeCheckpointIndex, bool exists) {
        for (uint i = 0; i < checkpoints.length; i++) {
            if (checkpoints[i].checkpointId == checkpointId) {
                return(i, true);
            }
        }

        return (0, false);
    }
}
