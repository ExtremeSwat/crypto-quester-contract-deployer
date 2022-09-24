// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./CryptoQuestDeployer.sol";

// todo: re-entrancy attack prevention
// toDo: stop spamming STrings.bs this will cause extra gas units, just extract them to the upper lines of the function into memory vars, cheaper and cleanier
// todo: remove simple acl on address and just insert it
contract CryptoQuest is CryptoQuestDeployer {
    // Creation Events
    event ChallengeCreated(address indexed _userAddress, string title);
    event ParticipantJoined(address indexed _userAddress, uint256 challengeId);
    event CheckpointCreated(address indexed _userAddress, string title);

    constructor(address registry) CryptoQuestDeployer(registry) {}

    /**
     * @dev Generates a checkpoint for a given challengeId
     *
     */
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
    ) external payable {
        // stack too deep :/

        string memory insertStatement = SQLHelpers.toInsert(
            challengeCheckpointsPrefix,
            challengeCheckpointsTableId,
            "id, challengeId, ordering, title, iconUrl, lat, lng, creationTimestamp, isUserInputRequired, userInputAnswer",
            string.concat(
                string.concat(
                    getUintInQuotes(checkpointId, true),
                    getUintInQuotes(challengeId, true),
                    getUintInQuotes(ordering, true),
                    getStringInQuotes(title, true),
                    getStringInQuotes(iconUrl, true)
                ),
                string.concat(
                    getStringInQuotes(lat, true),
                    getStringInQuotes(lng, true),
                    getUintInQuotes(block.timestamp, true),
                    getUintInQuotes(isUserInputRequired, true),
                    getStringInQuotes(userInputAnswer, false)
                )
            )
        );

        _tableland.runSQL(
            address(this),
            challengeCheckpointsTableId,
            insertStatement
        );
    }

    /**
     * @dev Removes a checkpoint
     */
    function removeCheckpoint(uint256 checkpointId) external payable {
        string memory deleteCheckpointStatement = SQLHelpers.toDelete(
            challengeCheckpointsPrefix,
            challengeCheckpointsTableId,
            string.concat("id = ", Strings.toString(checkpointId))
        );

        _tableland.runSQL(
            address(this),
            challengeCheckpointsTableId,
            deleteCheckpointStatement
        );
    }

    function archiveChallenge(uint256 challengeId, uint256 archiveEnum)
        external
        payable
    {
        string memory challengeIdStr = Strings.toString(challengeId);
        string memory archiveEnumStr = Strings.toString(archiveEnum);

        string memory updateStatement = SQLHelpers.toUpdate(
            challengesPrefix,
            challengesTableId,
            string.concat("challengeStatus = ", archiveEnumStr),
            string.concat("id = ", challengeIdStr)
        );
        _tableland.runSQL(address(this), challengesTableId, updateStatement);
    }

    /**
     * @dev Generates a challenge
     *
     * title - Title of the challenge. [mandatory]
     * description - Description of the challenge. [mandatory]
     * fromTimestamp - unix epoch which indicates the start of the challenge. [mandatory]
     * toTimestamp - unix epoch which indicates when the challenge will end. [mandatory]
     * mapSkinId - skinId from skins table [mandatory]
     *
     */

    function createChallenge(
        uint256 id,
        string memory title,
        string memory description,
        uint256 fromTimestamp,
        uint256 toTimestamp,
        uint256 mapSkinId,
        address owner
    ) external payable {
        // preventing jumbled timestamps
        require(fromTimestamp < toTimestamp, "Wrong start-end range !");

        string memory insertStatement = SQLHelpers.toInsert(
            challengesPrefix,
            challengesTableId,
            "id,title,description,fromTimestamp,toTimestamp,userAddress,creationTimestamp,mapSkinId,challengeStatus",
            string.concat(
                Strings.toString(id),
                ",'",
                title,
                "','",
                description,
                "',",
                Strings.toString(fromTimestamp),
                ",",
                Strings.toString(toTimestamp),
                ",'",
                getUserAddressAsString(owner),
                "',",
                Strings.toString(block.timestamp),
                ",",
                Strings.toString(mapSkinId),
                ",",
                Strings.toString(0)
            )
        );

        _tableland.runSQL(address(this), challengesTableId, insertStatement);
        emit ChallengeCreated(msg.sender, title);
    }

    /**
     * @dev Allows a user to participate in a challenge
     *
     * challengeId - id of the challenge [mandatory]
     */

    function participateInChallenge(
        uint256 challengeId,
        address participantAddress
    ) external payable {
        string memory insertStatement = SQLHelpers.toInsert(
            participantsPrefix,
            participantsTableId,
            "userAddress, joinTimestamp, challengeId",
            string.concat(
                "'",
                getUserAddressAsString(participantAddress),
                "',",
                Strings.toString(block.timestamp),
                ",",
                Strings.toString(challengeId)
            )
        );

        _tableland.runSQL(address(this), participantsTableId, insertStatement);
        emit ParticipantJoined(msg.sender, challengeId);
    }

    /**
     * @dev Allows an owner to start his own challenge
     *
     * challengeId - id of the challenge [mandatory]
     */
    function triggerChallengeStart(uint256 challengeId, address ownerAddress)
        external
        payable
    {
        string memory filter = string.concat(
            "id=",
            Strings.toString(challengeId),
            // only the owner can do it
            " and userAddress='",
            getUserAddressAsString(ownerAddress)
        );

        string memory updateStatement = SQLHelpers.toUpdate(
            challengesPrefix,
            challengesTableId,
            string.concat(
                "triggerTimestamp= ",
                Strings.toString(block.timestamp)
            ),
            filter
        );

        _tableland.runSQL(address(this), challengesTableId, updateStatement);
    }

    function setChallengeWinner(
        uint256 challengeId,
        address challengeWinner,
        uint256 challengeStatus
    ) external payable {
        string memory userAddress = getUserAddressAsString(challengeWinner);
        string memory updateStatement = SQLHelpers.toUpdate(
            challengesPrefix,
            challengesTableId,
            string.concat(
                "challengeStatus=",
                Strings.toString(challengeStatus),
                ", winnerAddress='",
                userAddress,
                "'"
            ),
            string.concat("id =", Strings.toString(challengeId))
        );

        _tableland.runSQL(address(this), challengesTableId, updateStatement);
    }

    function participantProgressCheckIn(
        uint256 challengeCheckpointId,
        address participantAddress
    ) external payable {
        string memory userAddress = getUserAddressAsString(participantAddress);

        string memory insertStatement = SQLHelpers.toInsert(
            participantProgressPrefix,
            participantsProgressTableId,
            "userAddress, challengeCheckpointId, visitTimestamp",
            string.concat(
                "'",
                userAddress,
                "',",
                Strings.toString(challengeCheckpointId),
                ",",
                Strings.toString(block.timestamp)
            )
        );

        _tableland.runSQL(
            address(this),
            participantsProgressTableId,
            insertStatement
        );
    }

    function createNewUser(address userAddress, string memory nickName)
        public
        payable
    {
        string memory insertStatement = SQLHelpers.toInsert(
            usersPrefix,
            usersTableId,
            "userAddress, nickname, registeredDate",
            string.concat(
                "'",
                getUserAddressAsString(userAddress),
                "', '",
                nickName,
                "', ",
                Strings.toString(block.timestamp)
            )
        );

        _tableland.runSQL(address(this), usersTableId, insertStatement);
    }

    // ------------------------------------------ PRIVATE METHODS ------------------------------------------------

    function getUserAddressAsString(address sender)
        private
        pure
        returns (string memory)
    {
        return Strings.toHexString(uint256(uint160(sender)), 20);
    }

    function getUintInQuotes(uint256 value, bool attachComma)
        private
        returns (string memory)
    {
        string memory toRet = string.concat(Strings.toString(value));
        if (attachComma) {
            toRet = string.concat(toRet, ",");
        }

        return toRet;
    }

    function getStringInQuotes(string memory value, bool attachComma)
        private
        returns (string memory)
    {
        string memory toRet = string.concat("'", value, "'");
        if (attachComma) {
            toRet = string.concat(toRet, ",");
        }

        return toRet;
    }
}
