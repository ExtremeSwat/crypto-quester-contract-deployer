// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./CryptoQuestDeployer.sol";

abstract contract CryptoQuest is CryptoQuestDeployer {
    //maybe add structs

    // Events
    event ChallengeCreated(address indexed _challengeOwner, string title);
    event ParticipantJoined(address indexed _participant, uint256 challengeId);

    function participateInChallenge(uint256 challengeId) public payable {
        require(challengeId < 0 || challengeId == 0, "invalid challenge id");

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
            " join challenges c on v.column3 = c.id",
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
}
