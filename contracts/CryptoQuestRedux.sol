// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./CryptoQuestHelpers.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

using Counters for Counters.Counter;

/*
    Interface used to communicate w/ a contract 
*/
interface CryptoQuestInterface {
    function createCheckpoint(
        uint256 checkpointId,
        uint256 challengeId,
        uint256 ordering,
        string memory title,
        string memory iconUrl,
        uint256 iconId,
        string memory lat,
        string memory lng
    ) external payable;

    function createCheckpointTrigger(
        uint256 checkpointTriggerId,
        uint256 checkpointId,
        string memory title,
        string memory imageUrl,
        uint8 isPhotoRequired,
        string memory photoDescription,
        uint8 isUserInputRequired,
        string memory userInputDescription,
        string memory userInputAnswer
    ) external payable;

    function removeCheckpointTrigger(uint256 challengeCheckpointId)
        external
        payable;

    function removeCheckpoint(uint256 checkpointId) external payable;

    function createChallenge(
        uint256 id,
        string memory title,
        string memory description,
        uint256 fromTimestamp,
        uint256 toTimestamp,
        uint256 mapSkinId,
        address owner,
        string memory imagePreviewURL
    ) external payable;

    function participateInChallenge(
        uint256 challengeId,
        address participantAddress
    ) external payable;

    function triggerChallengeStart(uint256 challengeId, uint256 challengeStatus)
        external
        payable;

    function participantProgressCheckIn(
        uint256 challengeCheckpointId,
        address participantAddress
    ) external payable;

    function createNewUser(address userAddress, string memory nickName)
        external
        payable;

    function archiveChallenge(uint256 challengeId, uint256 archiveEnum)
        external
        payable;

    function setChallengeWinner(
        uint256 challengeId,
        address challengeWinner,
        uint256 challengeStatus
    ) external payable;
}

contract CryptoQuestRedux is Ownable, CryptoQuestHelpers {
    Counters.Counter private _challengeCurrentId;
    Counters.Counter private _challengeCheckpointId;
    Counters.Counter private _challengeCheckpointTriggerId;

    CryptoQuestInterface cryptoQuestInterface;

    function setCryptoQuestAddress(address _address) external onlyOwner {
        cryptoQuestInterface = CryptoQuestInterface(_address);
    }

    function createChallenge(
        string memory title,
        string memory description,
        uint256 fromTimestamp,
        uint256 toTimestamp,
        uint256 mapSkinId,
        string memory imagePreviewURL
    ) external returns (uint256) {
        require(fromTimestamp < toTimestamp, "Wrong start-end range !");

        Challenge storage newChallenge = challenges.push();

        newChallenge.challengeId = _challengeCurrentId.current();
        newChallenge.fromTimestamp = fromTimestamp;
        newChallenge.challengeStatus = ChallengeStatus.Draft;
        newChallenge.toTimestamp = toTimestamp;
        newChallenge.ownerAddress = msg.sender;

        cryptoQuestInterface.createChallenge(
            newChallenge.challengeId,
            title,
            description,
            fromTimestamp,
            toTimestamp,
            mapSkinId,
            msg.sender,
            imagePreviewURL
        );

        challengeOwners[msg.sender][newChallenge.challengeId] = true;
        _challengeCurrentId.increment();

        return newChallenge.challengeId;
    }

    function archiveChallenge(uint256 challengeId)
        external
        payable
        isChallengeOwned(challengeId)
        checkChallengeEditability(challengeId)
    {
        Challenge storage challenge = challenges[challengeId];
        challenge.challengeStatus = ChallengeStatus.Archived;

        cryptoQuestInterface.archiveChallenge(
            challengeId,
            uint256(ChallengeStatus.Archived)
        );
    }

    function createCheckpoint(
        uint256 challengeId,
        uint256 order,
        string memory title,
        string memory iconUrl,
        uint256 iconId,
        string memory lat,
        string memory lng
    )
        external
        payable
        isChallengeOwned(challengeId)
        checkChallengeEditability(challengeId)
        returns (uint256)
    {
        Challenge storage challenge = challenges[challengeId];

        require(order > 0, "Ordering starts from 1 !");
        require(order > challenge.lastOrder, "Invalid ordering !");

        uint256 currentCheckpointId = _challengeCheckpointId.current();
        challenge.challengeCheckpoints[
            currentCheckpointId
        ] = ChallengeCheckpoint(currentCheckpointId, order, true, 0, false);

        challenge.lastCheckpointId = currentCheckpointId;
        challenge.lastOrder = order;

        cryptoQuestInterface.createCheckpoint(
            currentCheckpointId,
            challengeId,
            order,
            title,
            iconUrl,
            iconId,
            lat,
            lng
        );

        _challengeCheckpointId.increment();
        challengeNumberOfCheckpoints[
            challengeId
        ] = ++challengeNumberOfCheckpoints[challengeId];

        return currentCheckpointId;
    }

    function removeCheckpoint(uint256 challengeId, uint256 checkpointId)
        external
        payable
        isChallengeOwned(challengeId)
        checkChallengeEditability(challengeId)
    {
        Challenge storage challenge = challenges[challengeId];
        ChallengeCheckpoint storage challengeCheckpoint = challenge
            .challengeCheckpoints[challengeId];

        require(challengeCheckpoint.exists);
        cryptoQuestInterface.removeCheckpoint(checkpointId);

        delete challenge.challengeCheckpoints[challengeId];
    }

    function createCheckpointTrigger(
        uint256 challengeId,
        uint256 checkpointId,
        string memory title,
        string memory imageUrl,
        bool isPhotoRequired,
        string memory photoDescription,
        bool isUserInputRequired,
        string memory userInputDescription,
        string memory userInputAnswer
    )
        external
        payable
        isChallengeOwned(challengeId)
        checkChallengeEditability(challengeId)
        returns (uint256)
    {
        Challenge storage challenge = challenges[challengeId];
        ChallengeCheckpoint storage challengeCheckpoint = challenge
            .challengeCheckpoints[checkpointId];

        require(challengeCheckpoint.exists);
        require(!challengeCheckpoint.checkpointTriggerExists);

        // sql insert of trigger
        cryptoQuestInterface.createCheckpointTrigger(
            _challengeCheckpointTriggerId.current(),
            checkpointId,
            title,
            imageUrl,
            isPhotoRequired ? 1 : 0,
            photoDescription,
            isUserInputRequired ? 1 : 0,
            userInputDescription,
            userInputAnswer
        );

        challengeCheckpoint.checkpointTriggerId = _challengeCheckpointTriggerId.current();
        challengeCheckpoint.checkpointTriggerExists = true;

        _challengeCheckpointTriggerId.increment();
        return _challengeCheckpointTriggerId.current() - 1;
    }

    function removeCheckpointTrigger(uint256 challengeId, uint256 checkpointId)
        external
        payable
        isChallengeOwned(challengeId)
        checkChallengeEditability(challengeId)
    {
        Challenge storage challenge = challenges[challengeId];
        ChallengeCheckpoint storage challengeCheckpoint = challenge
            .challengeCheckpoints[checkpointId];

        require(challengeCheckpoint.exists);

        console.log('removing checkpoint trigger with id: %s', challengeCheckpoint.checkpointTriggerId);
        cryptoQuestInterface.removeCheckpointTrigger(
            challengeCheckpoint.checkpointTriggerId
        );

        challengeCheckpoint.checkpointTriggerExists = false;
    }

    function triggerChallengeStart(uint256 challengeId)
        external
        payable
        isChallengeOwned(challengeId)
    {
        require(
            challengeNumberOfCheckpoints[challengeId] > 0,
            "Cannot start a challenge with no checkpoints added"
        );

        Challenge storage challengeToStart = challenges[challengeId];
        challengeToStart.challengeStatus = ChallengeStatus.Published;
        cryptoQuestInterface.triggerChallengeStart(
            challengeId,
            uint(ChallengeStatus.Published)
        );
    }

    function participateInChallenge(uint256 challengeId)
        external
        payable
    {
        require(!challengeParticipants[challengeId][msg.sender]);
        challengeParticipants[challengeId][msg.sender] = true;
        cryptoQuestInterface.participateInChallenge(challengeId, msg.sender);
    }

    function participantProgressCheckIn(
        uint256 challengeId,
        uint256 checkpointId
    ) external payable isParticipatingInChallenge(challengeId) {
        Challenge storage challenge = challenges[challengeId];
        require(
            challenge.challengeStatus == ChallengeStatus.Published,
            "Challenge must be active to be able to participate"
        );

        console.log('after checkup');


        uint256 lastTriggeredCheckpointId = participantHitTriggers[challengeId][msg.sender];

        ChallengeCheckpoint memory currentCheckpoint = challenge.challengeCheckpoints[lastTriggeredCheckpointId];
        ChallengeCheckpoint memory triggeredCheckpoint = challenge.challengeCheckpoints[checkpointId];

        console.log('after challengeCheckpoint current and triggered');

        if (!participantHasHitTriggers[challengeId][lastTriggeredCheckpointId]) {
            // first timer
        } else {
            // checks
            require(triggeredCheckpoint.exists, "Non-existing checkpointId !");
            require(triggeredCheckpoint.order > currentCheckpoint.order,"Invalid completion attempt !");
            require(
                (triggeredCheckpoint.order - currentCheckpoint.order) == 1,
                "Trying to complete a higher order challenge ? xD"
            );
        }

        //mark as visited
        participantHitTriggers[challengeId][msg.sender] = lastTriggeredCheckpointId;
        participantHasHitTriggers[challengeId][checkpointId] = true;

        if (triggeredCheckpoint.order == challenge.lastOrder) {
            // Challenge has been won by msg.sender
            challenge.challengeStatus = ChallengeStatus.Finished;
            challenge.winnerAddress = msg.sender;

            // Tableland call to update our challenge row
            cryptoQuestInterface.setChallengeWinner(
                challengeId,
                msg.sender,
                uint(ChallengeStatus.Finished)
            );
        }

        console.log('about to mark participant progress for checkpoint id: %s and sender: %s', checkpointId, msg.sender);

        cryptoQuestInterface.participantProgressCheckIn(
            checkpointId,
            msg.sender
        );
    }

     function createNewUser(string memory nickName) external payable {
        if (users[msg.sender]) revert Unauthorized();

        users[msg.sender] = true;

        cryptoQuestInterface.createNewUser(msg.sender, nickName);
    }
}
