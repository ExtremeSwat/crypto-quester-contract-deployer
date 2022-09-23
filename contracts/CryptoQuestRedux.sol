// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./CryptoQuestHelpers.sol";
import "./CryptoQuest.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

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
        string memory lat,
        string memory lng,
        uint8 isUserInputRequired,
        string memory userInputAnswer
    ) external payable;

    function removeCheckpoint(uint256 checkpointId) external payable;

    function createChallenge(
        uint256 id,
        string memory title,
        string memory description,
        uint256 fromTimestamp,
        uint256 toTimestamp,
        uint256 mapSkinId,
        address owner
    ) external payable;

    function participateInChallenge(uint256 challengeId, address participantAddress) external payable;

    function triggerChallengeStart(uint256 challengeId, address ownerAddress) external payable;
    function participantProgressCheckIn(uint256 challengeCheckpointId, address participantAddress) external payable;
    function createNewUser(address userAddress, string memory nickName) external payable;
    function archiveChallenge(uint256 challengeId, uint256 archiveEnum) external payable;
    function setChallengeWinner(uint256 challengeId, address challengeWinner, uint256 challengeStatus) external payable;
}

contract CryptoQuestRedux is Ownable, CryptoQuestHelpers {
    uint256 challengeCurrentId;
    uint256 challengeCheckpointId;
    CryptoQuestInterface cryptoQuestInterface;

    function setCryptoQuestAddress(address _address) external onlyOwner{
        cryptoQuestInterface = CryptoQuestInterface(_address);
    }

    function createChallenge(
        string memory title,
        string memory description,
        uint256 fromTimestamp,
        uint256 toTimestamp,
        uint256 mapSkinId
    ) external returns (uint256) {
        // preventing jumbled timestamps
        require(fromTimestamp < toTimestamp, "Wrong start-end range !");

        Challenge storage newChallenge = challenges.push();

        newChallenge.fromTimestamp = fromTimestamp;
        newChallenge.challengeStatus = ChallengeStatus.Draft;
        newChallenge.toTimestamp = toTimestamp;
        newChallenge.ownerAddress = msg.sender;

        cryptoQuestInterface.createChallenge(challengeCurrentId, title, description, fromTimestamp, toTimestamp, mapSkinId, msg.sender);

        challengeOwners[msg.sender][challengeCurrentId] = true;
        challengeCurrentId++;
        return challengeCurrentId;
    }

    function archiveChallenge(uint256 challengeId)
        external
        payable
        isChallengeOwned(challengeId)
    {
        Challenge storage challenge = challenges[challengeId];
        checkChallengeEditability(challenge);
        challenge.challengeStatus = ChallengeStatus.Archived;

        //sql fantasy
        cryptoQuestInterface.archiveChallenge(challengeId, uint256(ChallengeStatus.Archived));
    }

    function createCheckpoint(
        uint256 challengeId,
        uint256 order,
        string memory title,
        string memory iconUrl,
        string memory lat,
        string memory lng,
        bool isUserInputRequired,
        string memory userInputAnswer
    ) external payable isChallengeOwned(challengeId) returns (uint256) {
        Challenge storage challenge = challenges[challengeId];
        checkChallengeEditability(challenge);

        checkChallengeIsOwnedBySender(challenge);

        require(order > 0, "Ordering starts from 1 !");

        if (challenge.challengeCheckpoints.length > 0) {
            require(
                order >
                    challenge
                        .challengeCheckpoints[challenge.lastCheckpointId]
                        .order,
                "invalid ordering"
            );
        }

        challenge.challengeCheckpoints.push(
            ChallengeCheckpoint(
                challengeCheckpointId,
                order,
                isUserInputRequired,
                userInputAnswer,
                true
            )
        );
        challenge.lastCheckpointId = challengeCheckpointId;
        challenge.lastOrder = order;
        ++challengeCheckpointId;

        uint8 userInputAnswerInt;
        if(isUserInputRequired) {
            userInputAnswerInt = 1;
        } else {
            userInputAnswerInt = 0;
        }

        cryptoQuestInterface.createCheckpoint(challengeCheckpointId, challengeId, order, title, iconUrl, lat, lng, userInputAnswerInt, userInputAnswer);
        
        //sql fantasy then return
        return challengeCheckpointId - 1;
    }

    function removeCheckpoint(uint256 challengeId, uint256 checkpointId)
        external
        payable
        isChallengeOwned(challengeId)
    {
        Challenge storage challenge = challenges[challengeId];
        checkChallengeEditability(challenge);
        checkChallengeIsOwnedBySender(challenge);

        uint256 foundIndex;
        bool found;
        for (uint i = 0; i < challenge.challengeCheckpoints.length; i++) {
            if (
                challenge.challengeCheckpoints[i].checkpointId == checkpointId
            ) {
                foundIndex = i;
                found = true;
                break;
            }
        }

        require(found, "checkpoint not found");
        challenge.challengeCheckpoints[foundIndex] = challenge
            .challengeCheckpoints[challenge.challengeCheckpoints.length - 1];
        challenge.challengeCheckpoints.pop();
        if (foundIndex > 0) {
            challenge.lastCheckpointId -= 1;
        }
        
        cryptoQuestInterface.removeCheckpoint(checkpointId);
    }

    /**
     * @dev Allows an owner to start his own challenge
     *
     * challengeId - id of the challenge [mandatory]
     */
    function triggerChallengeStart(uint256 challengeId)
        external
        payable
        isChallengeOwned(challengeId)
    {
        Challenge storage challengeToStart = challenges[challengeId];
        checkChallengeEditability(challengeToStart);

        require(
            challengeToStart.challengeCheckpoints.length > 0,
            "Cannot start a challenge with no checkpoints added"
        );

        challengeToStart.challengeStatus = ChallengeStatus.Published;

        // sql update
    }

    /**
     * @dev Allows a user to participate in a challenge
     *
     * challengeId - id of the challenge [mandatory]
     */

    function participateInChallenge(uint256 challengeId) external {
        Challenge storage challengeToParticipateIn = challenges[challengeId];
        checkChallengeEditability(challengeToParticipateIn);

        // hasn't participated yet
        require(
            !challengeParticipants[challengeId][msg.sender],
            "Already active in challenge !"
        );

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

        uint256 lastTriggeredCheckpointId = participantHitTriggers[challengeId][
            msg.sender
        ];
        ChallengeCheckpoint
            memory currentCheckpoint = getCheckpointByCheckpointId(
                lastTriggeredCheckpointId,
                challenge.challengeCheckpoints
            );
        ChallengeCheckpoint
            memory triggeredCheckpoint = getCheckpointByCheckpointId(
                checkpointId,
                challenge.challengeCheckpoints
            );

        if (
            !participantHasHitTriggers[challengeId][lastTriggeredCheckpointId]
        ) {
            // first timer
        } else {
            // checks
            require(triggeredCheckpoint.exists, "Non-existing checkpointId !");
            require(
                triggeredCheckpoint.order > currentCheckpoint.order,
                "Invalid completion attempt !"
            );
            require(
                (triggeredCheckpoint.order - currentCheckpoint.order) == 1,
                "Trying to complete a higher order challenge ? xD"
            );
        }

        //mark as visited
        participantHitTriggers[challengeId][
            msg.sender
        ] = lastTriggeredCheckpointId;
        participantHasHitTriggers[challengeId][checkpointId] = true;

        if (triggeredCheckpoint.order == challenge.lastOrder) {
            //
            challenge.challengeStatus = ChallengeStatus.Finished;
            challenge.winnerAddress = msg.sender;

            // SQL update
            cryptoQuestInterface.setChallengeWinner(challengeId, msg.sender, uint(ChallengeStatus.Finished));
        } else {
            // evnt to signal progress
            // SQL update
            cryptoQuestInterface.participantProgressCheckIn(checkpointId, msg.sender);
        }
    }

    function createNewUser(string memory nickName) external payable {
        if(users[msg.sender])
            revert Unauthorized();

        users[msg.sender] = true;

        cryptoQuestInterface.createNewUser(msg.sender, nickName);
    }

    //-------------------------------- privates & modifiers
    function checkChallengeEditability(Challenge memory challenge) private view {
        require(
            challenge.toTimestamp < block.timestamp,
            "Cannot alter a challenge in past !"
        );
        require(
            challenge.challengeStatus == ChallengeStatus.Draft,
            "Can only alter drafts !"
        );
    }

    function getCheckpointByCheckpointId (
        uint256 checkpointId,
        ChallengeCheckpoint[] memory checkpoints
    ) private pure returns (ChallengeCheckpoint memory) {
        ChallengeCheckpoint memory soughtCheckpoint;
        for (uint i = 0; i < checkpoints.length; i++) {
            if (checkpoints[i].checkpointId == checkpointId) {
                soughtCheckpoint = checkpoints[i];
                break;
            }
        }

        return soughtCheckpoint;
    }
}
