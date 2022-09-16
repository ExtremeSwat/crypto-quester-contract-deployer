// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./CryptoQuestDeployer.sol";

// todo: re-entrancy attack prevention
// toDo: stop spamming STrings.bs this will cause extra gas units, just extract them to the upper lines of the function into memory vars, cheaper and cleanier

abstract contract CryptoQuest is CryptoQuestDeployer {
    // Events
    event ChallengeCreated(address indexed _challengeOwner, string title);
    event ParticipantJoined(address indexed _participant, uint256 challengeId);
    event ChallengeTriggered();

    event ChallengeLocationCreated(
        address indexed owner,
        uint256 challengeId,
        string latitude,
        string longitude
    );
    event ChallengeLocationRemoved(
        address indexed owner,
        uint256 challengeId,
        uint256 removedChallengeLocationId
    );

    event ParticipantLeft(address indexed _participant, uint256 challengeId);
    event ChallengeLocationRemoved(address indexed _participant);

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
                " and owner=",
                Strings.toHexString(uint256(uint160(msg.sender)), 20),
                // cannot alter an already started challenge
                " and triggerTimestamp is null",
                // cannot be out of bounds
                " and fromTimestamp <=",
                currentTimestamp,
                " and toTimestamp >= ",
                currentTimestamp,
                // at least one challenger has to participate
                " and exists (select 'ex' from ",
                participantsTableName,
                " where challengeId = ",
                Strings.toString(challengeId),
                ")"
            )
        );
    }

    function removeChallengeLocation(
        uint256 challengeId,
        uint256 challengeLocationId
    ) public payable validChallengeId(challengeId) {
        string memory name = SQLHelpers.toNameFromId(
            challengeLocationsPrefix,
            challengeLocationsId
        );

        // removing only if challenge hasn't been started yet and only by it's owner
        string memory removeStatement = string.concat(
            "delete from ",
            name,
            " where challengeId = ",
            Strings.toString(challengeId),
            " and id = ",
            Strings.toString(challengeLocationId),
            " and id in (select id from ",
            name,
            " where id = ",
            Strings.toString(challengeLocationId),
            "and (triggerTimestamp >= ",
            Strings.toString(block.timestamp),
            " or triggerTimestamp is null)",
            " and owner = '",
            Strings.toHexString(uint256(uint160(msg.sender)), 20),
            "')"
        );

        _tableland.runSQL(address(this), challengeLocationsId, removeStatement);
        emit ChallengeLocationRemoved(
            msg.sender,
            challengeId,
            challengeLocationId
        );
    }

    function addChallengeLocation(
        string memory hint,
        string memory latitude,
        string memory longitude,
        uint256 challengeId
    ) public payable validChallengeId(challengeId) {
        string memory name = SQLHelpers.toNameFromId(
            challengeLocationsPrefix,
            challengeLocationsId
        );

        string memory insertStatement = string.concat(
            "insert into ",
            name,
            " (hint,latitude,longitude,creationTimestamp,challengeId)",
            " select v.column1, v.column2, v.column3, v.column4, c.id from (values('",
            hint,
            "',",
            latitude,
            ", ",
            longitude,
            ", ",
            Strings.toString(block.timestamp),
            ",",
            Strings.toString(challengeId),
            " )) v",
            " left join challenges c on c.id = v.column5 and c.owner='",
            Strings.toHexString(uint256(uint160(msg.sender)), 20),
            "'"
        );

        _tableland.runSQL(address(this), challengeLocationsId, insertStatement);
        emit ChallengeLocationCreated(
            msg.sender,
            challengeId,
            latitude,
            longitude
        );
    }

    function participateInChallenge(uint256 challengeId)
        public
        payable
        validChallengeId(challengeId)
    {
        string memory name = SQLHelpers.toNameFromId(
            participantsPrefix,
            participantsTableId
        );

        string memory insertStatement = string.concat(
            "insert into ",
            name,
            " (participant_address, join_timestamp, challengeId)",
            " select case when c.owner == '",
            Strings.toHexString(uint256(uint160(msg.sender)), 20),
            "' or pa.id is not null then null else column1 end, column2, column3",
            " from ( values ( '",
            Strings.toHexString(uint256(uint160(msg.sender)), 20),
            "',",
            Strings.toString(block.timestamp),
            ", ",
            Strings.toString(challengeId),
            ") ) v",
            // we must ensure ppl don't join while thing's started lmao
            " left join challenges c on v.column3 = c.id and (c.triggerTimestamp > ",
            Strings.toString(block.timestamp),
            " or c.triggerTimestamp is null)"
            " left join Participants pa on column1 = pa.participant_address"
        );

        _tableland.runSQL(address(this), challengesTableId, insertStatement);
        emit ParticipantJoined(msg.sender, challengeId);
    }

    function createNewChallenge(
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

    function leaveChallenge(uint256 challengeId)
        public
        payable
        validChallengeId(challengeId)
    {
        // this query isn't proofed with errors that will signal the abuser to screw off, it will run without doing any
        // crap on the DB

        string memory deleteFilter = string.concat(
            "participant_address='",
            Strings.toHexString(uint256(uint160(msg.sender)), 20),
            "'",
            "and challengeId=",
            Strings.toString(challengeId)
        );
        string memory deleteStatement = SQLHelpers.toDelete(
            participantsPrefix,
            participantsTableId,
            deleteFilter
        );

        _tableland.runSQL(address(this), participantsTableId, deleteStatement);
        emit ParticipantLeft(msg.sender, challengeId);
    }

    function addNewSkin(string memory skinName, string memory ipfsHash)
        public
        payable
    {
        string memory insertStatement = SQLHelpers.toInsert(
            mapSkinsPrefix,
            mapSkinsTableId,
            string.concat("skinName,", "ipfsHash"),
            string.concat("'", skinName, "',", "'", ipfsHash, "'")
        );

        _tableland.runSQL(address(this), mapSkinsTableId, insertStatement);
    }

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
            "owner,",
            "creationTimestamp"
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

    modifier validChallengeId(uint256 _challengeId) {
        require(_challengeId > 0, "invalid challenge id");
        _;
    }
}
