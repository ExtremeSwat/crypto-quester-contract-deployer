// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@tableland/evm/contracts/ITablelandTables.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./SQLHelpers.sol";

contract CryptoQuestDeployer is Ownable, ERC721Holder {
    // base tables
    string mapSkinsPrefix = "mapSkins";
    uint256 mapSkinsTableId;

    string usersPrefix = "users";
    uint256 usersTableId;

    string challengesPrefix = "challenges";
    uint256 challengesTableId;

    string challengeCheckpointsPrefix = "challengeCheckpoints";
    uint256 challengeCheckpointsTableId;

    string challengeCheckpointTriggerPrefix = "challengeCheckpointTriggers";
    uint256 challengeCheckpointTriggersTableId;

    string participantsPrefix = "participants";
    uint256 participantsTableId;

    string participantProgressPrefix = "participantProgress";
    uint256 participantsProgressTableId;

    // additional tables
    mapping(string => uint256) customTables;
    mapping(string => uint256) baseTables;

    // Interface to the `TablelandTables` registry contract
    ITablelandTables internal _tableland;

    constructor(address registry) {
        _tableland = ITablelandTables(registry);
    }
    
    function createBaseTables() public payable onlyOwner {
        mapSkinsTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                mapSkinsPrefix,
                "id integer primary key not null, skinName text not null unique, imagePreviewUrl text not null, mapUri text not null unique"
            )
        );

        usersTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                usersPrefix,
                "userAddress text not null primary key, nickName text not null, registeredDate integer not null, unique(nickName)"
            )
        );

        challengesTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                challengesPrefix,
                "id integer primary key NOT NULL,title text not null unique,description text not null,fromTimestamp integer not null,toTimestamp integer not null,triggerTimestamp integer, userAddress text not null,creationTimestamp integer not null,mapSkinId integer not null, challengeStatus integer not null, winnerAddress text, unique(title)"
            )
        );

        challengeCheckpointsTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                challengeCheckpointsPrefix,
                "id integer primary key not null, challengeId integer not null, ordering integer not null, title text not null, iconUrl text not null, lat real not null, lng real not null, creationTimestamp integer not null, isUserInputRequired integer, userInputAnswer text"
            )
        );

        challengeCheckpointTriggersTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                challengeCheckpointTriggerPrefix,
                "id integer primary key not null, checkpointId integer not null, title text not null, imageUrl text not null, isPhotoRequired integer, photoDescription text, isUserInputRequired integer not null, userInputDescription text, userInputAnswer text"
            )
        );

        participantsTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                participantsPrefix,
                "userAddress text not null, joinTimestamp integer not null, challengeId integer not null, unique(userAddress, challengeId)"
            )
        );

        participantsProgressTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                participantProgressPrefix,
                "userAddress text not null, challengeCheckpointId integer not null, visitTimestamp integer not null, unique(userAddress, challengeCheckpointId)"
            )
        );
    }

    function initiateDataSeed() public payable onlyOwner {
        string memory multipleRowsStatement = SQLHelpers.toInsertMultipleRows(
            mapSkinsPrefix,
            mapSkinsTableId,
            "skinName, imagePreviewUrl, mapUri",
            string.concat(
                "('Standard', 'https://api.mapbox.com/styles/v1/juvie22/cjtizpqis1exb1fqunbiqcw4y/static/26.1025,44.4268,10/512x341?access_token=pk.eyJ1IjoianV2aWUyMiIsImEiOiJjajNoN3hzeDEwMDFuMzNxZ2txeXR1ZnIzIn0.2Thoi_xQLD5f9d_R_DD7lg', 'mapbox://styles/juvie22/cjtizpqis1exb1fqunbiqcw4y'),",
                "('Comics', 'https://api.mapbox.com/styles/v1/juvie22/cjvdxmakw0fqh1fp8z47jqge5/static/26.1025,44.4268,10/512x341?access_token=pk.eyJ1IjoianV2aWUyMiIsImEiOiJjajNoN3hzeDEwMDFuMzNxZ2txeXR1ZnIzIn0.2Thoi_xQLD5f9d_R_DD7lg', 'mapbox://styles/juvie22/cjvdxmakw0fqh1fp8z47jqge5'),",
                "('Neon', 'https://api.mapbox.com/styles/v1/juvie22/cjvuxjxne0l4p1cpjbjwtn0k9/static/26.1025,44.4268,10/512x341?access_token=pk.eyJ1IjoianV2aWUyMiIsImEiOiJjajNoN3hzeDEwMDFuMzNxZ2txeXR1ZnIzIn0.2Thoi_xQLD5f9d_R_DD7lg', 'mapbox://styles/juvie22/cjvuxjxne0l4p1cpjbjwtn0k9'),",
                "('Blueprint', 'https://api.mapbox.com/styles/v1/juvie22/cjvuxaacd3ncv1cqvd6edffc2/static/26.1025,44.4268,10/512x341?access_token=pk.eyJ1IjoianV2aWUyMiIsImEiOiJjajNoN3hzeDEwMDFuMzNxZ2txeXR1ZnIzIn0.2Thoi_xQLD5f9d_R_DD7lg', 'mapbox://styles/juvie22/cjvuxaacd3ncv1cqvd6edffc2'),",
                "('Western', 'https://api.mapbox.com/styles/v1/juvie22/cjvuwejv70iaw1cqnb846caqy/static/26.1025,44.4268,10/512x341?access_token=pk.eyJ1IjoianV2aWUyMiIsImEiOiJjajNoN3hzeDEwMDFuMzNxZ2txeXR1ZnIzIn0.2Thoi_xQLD5f9d_R_DD7lg', 'mapbox://styles/juvie22/cjvuwejv70iaw1cqnb846caqy'),",
                "('Candy', 'https://api.mapbox.com/styles/v1/juvie22/cjvuvwhv90rhn1cpbpgactgnm/static/26.1025,44.4268,10/512x341?access_token=pk.eyJ1IjoianV2aWUyMiIsImEiOiJjajNoN3hzeDEwMDFuMzNxZ2txeXR1ZnIzIn0.2Thoi_xQLD5f9d_R_DD7lg', 'mapbox://styles/juvie22/cjvuvwhv90rhn1cpbpgactgnm'),",
                "('Noir', 'https://api.mapbox.com/styles/v1/juvie22/cjtj02zko4xbc1fpkv8dtolu3/static/26.1025,44.4268,10/512x341?access_token=pk.eyJ1IjoianV2aWUyMiIsImEiOiJjajNoN3hzeDEwMDFuMzNxZ2txeXR1ZnIzIn0.2Thoi_xQLD5f9d_R_DD7lg', 'mapbox://styles/juvie22/cjtj02zko4xbc1fpkv8dtolu3'),",
                "('Virus', 'https://api.mapbox.com/styles/v1/juvie22/cj7i2ftv34zpd2smtm3ik41fq/static/26.1025,44.4268,10/512x341?access_token=pk.eyJ1IjoianV2aWUyMiIsImEiOiJjajNoN3hzeDEwMDFuMzNxZ2txeXR1ZnIzIn0.2Thoi_xQLD5f9d_R_DD7lg', 'mapbox://styles/juvie22/cj7i2ftv34zpd2smtm3ik41fq')"
            )
        );

        _tableland.runSQL(
            address(this),
            mapSkinsTableId,
            multipleRowsStatement
        );
    }

    function createCustomTable(
        string memory prefix,
        string memory createStatement
    ) public payable onlyOwner returns (string memory) {
        uint256 tableId = _tableland.createTable(
            address(this),
            string.concat(
                "CREATE TABLE ",
                prefix,
                "_",
                Strings.toString(block.chainid),
                " (",
                createStatement,
                ")"
            )
        );

        string memory tableName = string.concat(
            prefix,
            "_",
            Strings.toString(block.chainid),
            "_",
            Strings.toString(tableId)
        );

        customTables[tableName] = tableId;

        return tableName;
    }

    function cleanupTables() onlyOwner external {
        _tableland.runSQL(address(this),usersTableId,string.concat('delete from ', getUsersTableName()));
        _tableland.runSQL(address(this),challengesTableId,string.concat('delete from ', getChallengesTableName()));
        _tableland.runSQL(address(this),participantsTableId,string.concat('delete from ', getParticipantsTableName()));
        _tableland.runSQL(address(this),challengeCheckpointsTableId,string.concat('delete from ', getChallengeCheckpointsTableName()));
        _tableland.runSQL(address(this),participantsProgressTableId,string.concat('delete from ', getParticipantProgressTableName()));
        _tableland.runSQL(address(this),mapSkinsTableId,string.concat('delete from ', getMapSkinsTableName()));
        _tableland.runSQL(address(this),challengeCheckpointTriggersTableId,string.concat('delete from ', getCheckpointTriggersTableName()));
    }

    receive() external payable {}

    fallback() external payable {}

    function getCheckpointTriggersTableName()
        internal
        view
        returns (string memory)
    {
        return
            SQLHelpers.toNameFromId(
                challengeCheckpointTriggerPrefix,
                challengeCheckpointTriggersTableId
            );
    }

    function getUsersTableName() internal view returns (string memory) {
        return SQLHelpers.toNameFromId(usersPrefix, usersTableId);
    }

    function getChallengesTableName() internal view returns (string memory) {
        return SQLHelpers.toNameFromId(challengesPrefix, challengesTableId);
    }

    function getParticipantsTableName() internal view returns (string memory) {
        return SQLHelpers.toNameFromId(participantsPrefix, participantsTableId);
    }

    function getChallengeCheckpointsTableName()
        internal
        view
        returns (string memory)
    {
        return
            SQLHelpers.toNameFromId(
                challengeCheckpointsPrefix,
                challengeCheckpointsTableId
            );
    }

    function getParticipantProgressTableName()
        internal
        view
        returns (string memory)
    {
        return
            SQLHelpers.toNameFromId(
                participantProgressPrefix,
                participantsProgressTableId
            );
    }

    function getMapSkinsTableName() internal view returns (string memory) {
        return SQLHelpers.toNameFromId(mapSkinsPrefix, mapSkinsTableId);
    }
}
