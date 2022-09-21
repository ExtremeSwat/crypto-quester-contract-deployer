// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

contract CryptoQuest_Slim {
    // Add the library methods
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    //platform users
    EnumerableMap.AddressToUintMap users;

    // challengeOwners
    mapping(address => mapping(uint256 => bool)) challengeOwners;

    // challengeId ==> userAddress --> isParticipating
    mapping(uint256 => mapping(address => bool)) challengeParticipants;

    // challengeId ==> userAddress --> last hit checkpoint id
    mapping(uint256 => mapping(address => uint256)) participantHitTriggers;

    Challenge[] public challenges;

    /// Sender not authorized for this
    /// operation.
    error Unauthorized();
    error ChallengeInProgress();
    error CannotChangeActiveChallenge();

    enum ChallengeStatus {
        Draft,
        Published,
        Finished
    }

    struct ParticipantCheckpointTrigger {
        uint256 checkpointId;
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
        ChallengeCheckpoint[] challengeCheckpoints;
        uint256 challengeCheckpointsIndex;
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

        challengeOwners[msg.sender][newChallengeId] = true;
        return newChallengeId;
    }

    function removeChallenge(uint256 challengeId)
        public
        isChallengeOwned(challengeId)
    {
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
    ) public isChallengeOwned(challengeId) returns (uint256) {
        Challenge storage challenge = challenges[challengeId];
        checkChallengeEditability(challenge);

        challenge.challengeCheckpointsIndex++;
        challenge.challengeCheckpoints[
            challenge.challengeCheckpointsIndex
        ] = ChallengeCheckpoint(ordering, isUserInputRequired, userInputAnswer);

        //sql fantasy then return

        return challenge.challengeCheckpointsIndex;
    }

    function removeCheckpoint(uint256 challengeId, uint256 checkpointId)
        public
        isChallengeOwned(challengeId)
    {
        Challenge storage challengeToRemove = challenges[challengeId];
        checkChallengeEditability(challengeToRemove);

        delete challengeToRemove.challengeCheckpoints[checkpointId];

        // sql statement
    }

    /**
     * @dev Allows an owner to start his own challenge
     *
     * challengeId - id of the challenge [mandatory]
     */
    function triggerChallengeStart(uint256 challengeId) public isChallengeOwned(challengeId)
    {
        Challenge storage challengeToStart = challenges[challengeId];
        checkChallengeEditability(challengeToStart);

        challengeToStart.challengeStatus = ChallengeStatus.Published;

        // sql update
    }

    function participantProgressTrigger(uint256 challengeId, uint256 challengeCheckpointId, uint256 checkpointId) public isParticipatingInChallenge(challengeId)
    {
        Challenge storage challenge = challenges[challengeId];
        uint256 lastTriggeredCheckpointId = participantHitTriggers[challengeId][msg.sender];
        ChallengeCheckpoint memory challengeCheckpoint = challenge.challengeCheckpoints[challengeCheckpointId];

        require(challengeCheckpoint.order > lastTriggeredCheckpointId && challengeCheckpoint.order - lastTriggeredCheckpointId == 1);
        
        participantHitTriggers[challengeId][msg.sender] = ++lastTriggeredCheckpointId;

        // evnt to signal progress
        
        // SQL updates 
        if(lastTriggeredCheckpointId == challenge.challengeCheckpoints.length) {
            challenge.challengeStatus = ChallengeStatus.Finished;
        }
    }   

    /**
     * @dev Allows a user to participate in a challenge
     *
     * challengeId - id of the challenge [mandatory]
     */

    function participateInChallenge(uint256 challengeId) public {
        Challenge storage challengeToParticipateIn = challenges[challengeId];
        checkChallengeEditability(challengeToParticipateIn);

        // hasn't participated yet
        require(!challengeParticipants[challengeId][msg.sender]);

        //add and save to sql
        challengeParticipants[challengeId][msg.sender] = true;
    }

    function abandonChallenge(uint256 challengeId) public {
        Challenge storage challengeToParticipateIn = challenges[challengeId];
        checkChallengeEditability(challengeToParticipateIn);

        require(challengeParticipants[challengeId][msg.sender]);

        //also sql
        delete challengeParticipants[challengeId][msg.sender];
    }

    function registerUser() public {
        if (users.contains(msg.sender)) revert Unauthorized();

        uint256 index = users.length() + 1;
        users.set(msg.sender, index);

        // once set, insert into table
    }

    //-------------------------------- privates & modifiers
    function checkChallengeEditability(Challenge memory challenge) private {
        require(
            challenge.toTimestamp > block.timestamp,
            "Cannot alter a challenge in past !"
        );
        require(
            challenge.challengeStatus == ChallengeStatus.Draft,
            "Can only alter drafts !"
        );
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
