// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./CryptoQuestDeployer.sol";

// todo: re-entrancy attack prevention
// toDo: stop spamming STrings.bs this will cause extra gas units, just extract them to the upper lines of the function into memory vars, cheaper and cleanier

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
        uint256 challengeId,
        uint256 ordering,
        string memory title,
        string memory iconUrl,
        string memory lat,
        string memory lng
    ) public payable validChallengeId(challengeId) {
        string memory insertStatement = SQLHelpers.toInsert(
            challengeCheckpointsPrefix,
            challengeCheckpointsTableId,
            'challengeId, ordering, title, iconUrl, lat, lng, creationTimestamp',
            string.concat(
                Strings.toString(challengeId),
                ",",
                Strings.toString(ordering),
                ",'",
                title,
                "','",
                iconUrl,
                "',",
                lat,
                ",",
                lng,
                ",",
                Strings.toString(block.timestamp)
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
     * limits --> will not be able to throw errors since I can't make SQLite crash w/ an error :/ on deletes
     * will need to dig deeper once MVP is done
     * title - checkpointId
     *
     */
    function removeCheckpoint(uint256 checkpointId) public payable {
        string memory checkpointIdStr = Strings.toString(checkpointId);

        string memory deleteCheckpointStatement = string.concat(
            "delete from ", getChallengeCheckpointsTableName(),
            " where id =", checkpointIdStr,
            " and challengeId in (select id from ", getChallengesTableName(), " where userAddress='", getUserAddressAsString() ,"')",
            " and id not in (select id from ", getCheckpointTriggersTableName(), " where checkpointId = ", checkpointIdStr, ")"
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

        string memory insertStatement = SQLHelpers.toInsert(
            challengesPrefix,
            challengesTableId,
            'title,description,fromTimestamp,toTimestamp,userAddress,creationTimestamp,mapSkinId,challengeStatus',
            string.concat(
                "'",
                title,
                "','",
                description,
                "',",
                Strings.toString(fromTimestamp),
                ",",
                Strings.toString(toTimestamp),
                ",'",
                getUserAddressAsString(),
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

    function participateInChallenge(uint256 challengeId)
        public
        payable
        validChallengeId(challengeId)
    {
        string memory insertStatement = SQLHelpers.toInsert
                (
                    participantsPrefix, 
                    participantsTableId,
                    'userAddress, joinTimestamp, challengeId',
                    string.concat(
                        "'",
                        getUserAddressAsString(),
                        "',",
                        Strings.toString(block.timestamp), 
                        ",",
                        Strings.toString(challengeId)
                    )
                ) ;

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
        string memory filter = string.concat(
                "id=",
                Strings.toString(challengeId),
                // only the owner can do it
                " and userAddress='",
                getUserAddressAsString(),
                // cannot alter an already started challenge && cannot be out of bounds
                "' and triggerTimestamp is null and fromTimestamp <=", currentTimestamp, " and toTimestamp >= ", currentTimestamp,
                // at least one POI challenge exists
                " and exists (select 'ex' from ", getChallengeCheckpointsTableName(), " where challengeId = ", Strings.toString(challengeId), ")"
                // at least one challenger has to participate
                " and exists (select 'ex' from ", getParticipantsTableName(), " where challengeId = ", Strings.toString(challengeId),")"
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

        _tableland.runSQL(address(this), challengesTableId,  updateStatement);
    }

    function participantProgressCheckIn(uint256 challengeCheckpointId) public payable  {
        string memory userAddress = Strings.toHexString(uint256(uint160(msg.sender)), 20);
        string memory currentTimestamp = Strings.toString(block.timestamp);


        string memory insStatement = string.concat

        string memory insertStatement = SQLHelpers.toInsert(
            participantProgressPrefix,
            participantsProgressTableId,
            'participantId, challengeCheckpointId, visitTimestamp',
            string.concat(
                "'", userAddress, "',", Strings.toString(challengeCheckpointId), ",", currentTimestamp
            )
        );

        _tableland.runSQL(address(this), participantsProgressTableId, insertStatement);
    }

    function createNewUser(string memory nickName) public payable {
        string memory currentTimestamp = Strings.toString(block.timestamp);

        string memory insertStatement = 
            SQLHelpers.toInsert
                (
                    usersPrefix, 
                    usersTableId, 
                    "userAddress, nickname, registeredDate",
                    string.concat("'", getUserAddressAsString(), "', '", nickName, "', ", currentTimestamp)
                );

        _tableland.runSQL(address(this), usersTableId, insertStatement);
    }

    // ------------------------------------------ PRIVATE METHODS ------------------------------------------------

    function getUserAddressAsString() private view returns (string memory) {
         return Strings.toHexString(
            uint256(uint160(msg.sender)),
            20
        );
    }

    // ------------------------------------------ PRIVATE METHODS ------------------------------------------------

    // ------------------------------------------ Modifiers ------------------------------------------------

    modifier validChallengeId(uint256 _challengeId) {
        require(_challengeId > 0, "invalid challenge id");
        _;
    }

    // ------------------------------------------ Modifiers ------------------------------------------------
}
