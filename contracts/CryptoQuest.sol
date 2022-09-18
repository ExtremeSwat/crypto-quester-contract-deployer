// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./CryptoQuestDeployer.sol";

// todo: re-entrancy attack prevention
// toDo: stop spamming STrings.bs this will cause extra gas units, just extract them to the upper lines of the function into memory vars, cheaper and cleanier

abstract contract CryptoQuest is CryptoQuestDeployer {
    // Creation Events
    event ChallengeCreated(address indexed _userAddress, string title);
    event ParticipantJoined(address indexed _userAddress, uint256 challengeId);
    event CheckpointCreated(address indexed _userAddress, string title);

    /**
     * @dev Generates a checkpoint for a given challengeId
     *
     */
    function createCheckpoint(
        uint256 challengeId,
        uint256 ordering,
        string memory title,
        string memory iconUrl,
        string memory lat,
        string memory lng
    ) public payable validChallengeId(challengeId) {
        string memory currentTimestamp = Strings.toString(block.timestamp);
        string memory userAddress = Strings.toHexString(
            uint256(uint160(msg.sender)),
            20
        );

        string memory checkPointTableName = SQLHelpers.toNameFromId(
            challengeCheckpointsPrefix,
            challengeCheckpointsTableId
        );

        string memory challengesTableName = SQLHelpers.toNameFromId(
            challengesPrefix,
            challengesTableId
        );

        string memory challengeIdStr = Strings.toString(challengeId);

        string memory checkpointInsertStatement = string.concat(
            "insert into ",
            checkPointTableName,
            " (challengeId, ordering, title, iconUrl, lat, lng, creationTimestamp)",
            " select cll.id, case when c.ordering is null then column1 else null) as ordering, column2, column3, column4, column5, ", currentTimestamp,",",
            " from (values(", Strings.toString(ordering), 
            ",'", title, "','", iconUrl,"',", lat,",", lng,
            ")) v",
            " left join ", challengesTableName ," cll on cll.id = ", challengeIdStr, " and cll.userAddress = '", userAddress, "'" ,
            " left join ", checkPointTableName, "c on c.ordering != ", Strings.toString(ordering), " and c.challengeId = ", challengeIdStr
        );

        _tableland.runSQL(
            address(this),
            challengeCheckpointsTableId,
            checkpointInsertStatement
        );
    }

    /**
     * @dev Removes a checkpoint
     * limits --> will not be able to throw errors since I can't make SQLite crash w/ an error :/ on deletes
     * will need to dig deeper once MVP is done
     * title - checkpointId
     *
     */
    function removeCheckpoint(uint256 checkpointId) public payable {
        string memory checkPointTableName = SQLHelpers.toNameFromId(
            challengeCheckpointsPrefix,
            challengeCheckpointsTableId
        );

        string memory checkpointTriggersTableName = SQLHelpers.toNameFromId(
            challengeCheckpointTriggerPrefix,
            challengeCheckpointTriggersTableId
        );

        string memory challengesTableName = SQLHelpers.toNameFromId(
            challengesPrefix,
            challengesTableId
        );

        string memory userAddress = Strings.toHexString(
            uint256(uint160(msg.sender)),
            20
        );

        string memory checkpointIdStr = Strings.toString(checkpointId);

        string memory deleteCheckpointStatement = string.concat(
            "delete from ", checkPointTableName,
            " where id =", checkpointIdStr,
            " and checkpointId = ", checkpointIdStr,
            " and challengeId in (select id from ", challengesTableName, " where userAddress='", userAddress ,")",
            " and id not in (select id from ", checkpointTriggersTableName, ", where checkpointId = ", checkpointIdStr, ")"
        );

        _tableland.runSQL(address(this), challengeCheckpointsTableId, deleteCheckpointStatement);
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
        string memory title,
        string memory description,
        uint256 fromTimestamp,
        uint256 toTimestamp,
        uint256 mapSkinId
    ) public payable {
        // preventing jumbled timestamps
        require(fromTimestamp < toTimestamp, "Wrong start-end range !");

        // can't create things in the past lmao
        require(
            block.timestamp < fromTimestamp,
            "Cannot set a range for the past !"
        );

        // can't create a challenge with a diff < 8 h, maybe we should have it configurable from UI ?
        require(
            toTimestamp - fromTimestamp < 8 hours,
            "Can't create a challenge that'll last fewer than one hour !"
        );

        (
            string memory columns,
            string memory values
        ) = createChallengeInsertStatement(
                title,
                description,
                fromTimestamp,
                toTimestamp,
                mapSkinId
            );

        string memory insertStatement = SQLHelpers.toInsert(
            challengesPrefix,
            challengesTableId,
            columns,
            values
        );

        _tableland.runSQL(address(this), challengesTableId, insertStatement);
        emit ChallengeCreated(msg.sender, title);
    }

    /**
     * @dev Allows a user to participate in a challenge
     *
     * challengeId - id of the challenge [mandatory]
    */

    function participateInChallenge(uint256 challengeId)
        public
        payable
        validChallengeId(challengeId)
    {
        string memory participants = SQLHelpers.toNameFromId(
            participantsPrefix,
            participantsTableId
        );

        string memory users = SQLHelpers.toNameFromId(
            usersPrefix,
            usersTableId
        );

        string memory userAddress = Strings.toHexString(uint256(uint160(msg.sender)), 20);

        string memory insertStatement = string.concat(
            "insert into ",
            participants,
            " (participant_address, joinTimestamp, challengeId)",
            " select case when c.userAddress == '",userAddress,
            "' or pa.id is not null or usr is null then null else column1 end, column2, c.id",
            " from ( values ( '", userAddress,
            "',",
            Strings.toString(block.timestamp),
            ", ",
            Strings.toString(challengeId),
            ") ) v",
            // we must ensure ppl don't join while thing's started lmao
            " left join challenges c on v.column3 = c.id and (c.triggerTimestamp > ",
            Strings.toString(block.timestamp),
            " or c.triggerTimestamp is null)"
            " left join ", participants, " pa on column1 = pa.participant_address",
            " left join ", users ," usr on usr.userAddress = pa.participant_address"
        );

        _tableland.runSQL(address(this), challengesTableId, insertStatement);
        emit ParticipantJoined(msg.sender, challengeId);
    }

    /**
     * @dev Allows an owner to start his own challenge
     *
     * challengeId - id of the challenge [mandatory]
    */
     function triggerChallengeStart(uint256 challengeId)
        public
        payable
        validChallengeId(challengeId)
    {
        string memory currentTimestamp = Strings.toString(block.timestamp);

        string memory participantsTableName = SQLHelpers.toNameFromId(
            participantsPrefix,
            participantsTableId
        );

         string memory challengeCheckpointsTableName = SQLHelpers.toNameFromId(
            challengeCheckpointsPrefix,
            challengeCheckpointsTableId
        );

        string memory updateStatement = SQLHelpers.toUpdate(
            challengesPrefix,
            challengesTableId,
            string.concat(
                "triggerTimestamp= ",
                Strings.toString(block.timestamp)
            ),
            string.concat(
                "id=",
                Strings.toString(challengeId),
                // only the owner can do it
                " and userAddress=",
                Strings.toHexString(uint256(uint160(msg.sender)), 20),
                // cannot alter an already started challenge
                " and triggerTimestamp is null",
                // cannot be out of bounds
                " and fromTimestamp <=",
                currentTimestamp,
                " and toTimestamp >= ",
                currentTimestamp,
                // at least one POI challenge exists
                " and exists (select 'ex' from ", challengeCheckpointsTableName, ", where challengeId = ", Strings.toString(challengeId), ")"
                // at least one challenger has to participate
                " and exists (select 'ex' from ",
                participantsTableName,
                " where challengeId = ",
                Strings.toString(challengeId),
                ")"
            )
        );

        _tableland.runSQL(address(this), challengesTableId,  updateStatement);
    }

    // ------------------------------------------ PRIVATE METHODS ------------------------------------------------

    /*
        Generates values for insert
    */
    function createChallengeInsertStatement(
        string memory title,
        string memory description,
        uint256 fromTimestamp,
        uint256 toTimestamp,
        uint256 mapSkinId
    ) private view returns (string memory, string memory) {
        string memory columns = string.concat(
            "title,",
            "description,",
            "fromTimestamp,",
            "toTimestamp,",
            "userAddress,",
            "creationTimestamp,",
            "mapSkinId,",
            "challengeStatus"
        );

        string memory values = string.concat(
            "'",
            title,
            "',"
            "'",
            description,
            "',",
            Strings.toString(fromTimestamp),
            ",",
            Strings.toString(toTimestamp),
            ",'",
            Strings.toHexString(uint256(uint160(msg.sender)), 20),
            "',",
            Strings.toString(block.timestamp)
        );

        if (mapSkinId != 0) {
            columns = string.concat(columns, ",", "mapSkinId");
            values = string.concat(values, ",", Strings.toString(mapSkinId));
        }

        return (columns, values);
    }

    // ------------------------------------------ PRIVATE METHODS ------------------------------------------------

    // ------------------------------------------ Modifiers ------------------------------------------------

    modifier validChallengeId(uint256 _challengeId) {
        require(_challengeId > 0, "invalid challenge id");
        _;
    }

    // ------------------------------------------ Modifiers ------------------------------------------------
}
