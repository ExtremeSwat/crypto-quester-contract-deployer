// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

contract CryptoQuest_Slim {
    // Add the library methods
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    //platform users
    EnumerableMap.AddressToUintMap users;

    Challenge[] public challenges;

    /// Sender not authorized for this
    /// operation.
    error Unauthorized();
    error ChallengeInProgress();
    error CannotChangeActiveChallenge();

    enum ChallengeStatus {
        Draft,
        Published
    }

    // used to signal participant's progress
    struct ChallengeParticipantTrigger {
        uint256 checkpointTriggerId;
    }

    // used to signal participant
    struct ChallengeParticipant {
        uint256 participantId;
        ChallengeParticipantTrigger[] participantCheckpointTriggers;
    }

    // used to signal a checkpoint
    struct ChallengeCheckpoint {
        uint256 order;
        bool isUserInputRequired;
        string userInputAnswer;
    }

    struct Challenge {
        uint256 challengeId;
        address ownerAddress;
        uint256 fromTimestamp;
        uint256 toTimestamp;
        ChallengeStatus challengeStatus;
        uint256 challengeCheckpointsIndex;
        uint256 challengeParticipantsIndex;
        mapping(uint256 => ChallengeCheckpoint) challengeCheckpoints;

        mapping(address => ChallengeParticipant) challengeParticipants;
    }

    function createChallenge(
        string memory title,
        string memory description,
        uint256 fromTimestamp,
        uint256 toTimestamp,
        uint256 mapSkinId
    ) public returns (uint256) {
        // preventing jumbled timestamps
        require(fromTimestamp < toTimestamp, "Wrong start-end range !");

        Challenge storage newChallenge = challenges.push();
        uint256 newChallengeId = challenges.length + 1;

        newChallenge.fromTimestamp = fromTimestamp;
        newChallenge.toTimestamp = toTimestamp;
        newChallenge.challengeId = newChallengeId;
        newChallenge.ownerAddress = msg.sender;

        // to insert into table
        //title is to be concatenated with id

        return newChallengeId;
    }

    function removeChallenge(uint256 challengeId) public {
        Challenge storage challengeToRemove = challenges[challengeId];
        if (challengeToRemove.ownerAddress != msg.sender) revert Unauthorized();
        checkChallengeEditability(challengeToRemove);

        delete challenges[challengeId];

        //sql fantasy
    }

    function createCheckpoint(
        uint256 challengeId,
        uint256 ordering,
        string memory title,
        string memory iconUrl,
        string memory lat,
        string memory lng,
        bool isUserInputRequired,
        string memory userInputAnswer
    ) public returns (uint256) {
        Challenge storage challenge = challenges[challengeId];
        if (challenge.ownerAddress != msg.sender) revert Unauthorized();
        checkChallengeEditability(challenge);

        challenge.challengeCheckpointsIndex++;
        challenge.challengeCheckpoints[
            challenge.challengeCheckpointsIndex
        ] = ChallengeCheckpoint(ordering, isUserInputRequired, userInputAnswer);

        //sql fantasy then return

        return challenge.challengeCheckpointsIndex;
    }

    function removeCheckpoint(uint256 challengeId, uint256 checkpointId) public {
        Challenge storage challengeToRemove = challenges[challengeId];
        if (challengeToRemove.ownerAddress != msg.sender) revert Unauthorized();
        checkChallengeEditability(challengeToRemove);

        delete challengeToRemove.challengeCheckpoints[checkpointId];

        // sql statement
    }

     /**
     * @dev Allows a user to participate in a challenge
     *
     * challengeId - id of the challenge [mandatory]
    */

    function participateInChallenge(uint256 challengeId) public
    {
        Challenge storage challengeToParticipateIn = challenges[challengeId];
        checkChallengeEditability(challengeToParticipateIn);
       
        // hasn't participated yet
        require(challengeToParticipateIn.challengeParticipants[msg.sender].participantId == 0);

        // challengeToParticipateIn.challengeParticipants[msg.sender] = ChallengeParticipant(++challengeToParticipateIn.challengeParticipantsIndex, );
    }

    function checkChallengeEditability(Challenge storage challenge) private {
        require(
            challenge.toTimestamp > block.timestamp,
            "Cannot alter a challenge in past !"
        );
        require(
            challenge.challengeStatus == ChallengeStatus.Draft,
            "Can only alter drafts !"
        );
    }

    function registerUser() public {
        if (users.contains(msg.sender)) revert Unauthorized();

        uint256 index = users.length() + 1;
        users.set(msg.sender, index);

        // once set, insert into table
    }

    modifier onlyRegisteredUsers() {
        if (!users.contains(msg.sender)) revert Unauthorized();

        _;
    }
}
