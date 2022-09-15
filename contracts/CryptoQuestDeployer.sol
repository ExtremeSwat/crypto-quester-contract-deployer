// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@tableland/evm/contracts/ITablelandTables.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./SQLHelpers.sol";

contract CryptoQuestDeployer is Ownable, ERC721Holder {
    // base tables
    string mapSkinsTablePrefix = "mapSkins";
    uint256 mapSkinsTableId;

    string challengesPrefix = "challenges";
    uint256 challengesTableId;

    string challengeLocationsPrefix = "challenge_locations";
    uint256 challengeLocationsId;

    string participantsPrefix = "participants";
    uint256 participantsTableId;

    string participantProgressPrefix = "participant_progress";
    uint256 participantsProgressTableId;

    // additional tables
    mapping(string => uint256) customTables;

    // Interface to the `TablelandTables` registry contract
    ITablelandTables internal _tableland;

    constructor(address registry) payable {
        _tableland = ITablelandTables(registry);

        initializeBaseTables();
    }

    function initializeBaseTables() public payable onlyOwner {
        mapSkinsTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                mapSkinsTablePrefix,
                "(id integer primary key not null, skinName text not null, ipfsHash text not null, unique(ipfsHash), unique(skinName))"
            )
        );

        challengesTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                challengesPrefix,
                "(id integer primary key NOT NULL,title text not null unique,description text not null,fromTimestamp integer not null,toTimestamp integer not null,triggerTimestamp integer,owner text not null,creationTimestamp integer not null,mapSkinId integer, unique(title))"
            )
        );

        challengeLocationsId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                challengeLocationsPrefix,
                "(id integer not null primary key,hint TEXT,latitude real not null,longitude real not null,creationTimestamp integer not null,challengeId integer not null)"
            )
        );

        participantsTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                participantsPrefix,
                "(id integer primary key not null, participant_address text not null, join_timestamp integer not null, challengeId integer not null, unique(participant_address, challengeId)"
            )
        );

        participantsProgressTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                "participant_progress",
                "(id integer primary key not null, challenge_participant_id integer not null, challenge_location_id integer not null, challenge_visit_timestamp integer not null, unique(challenge_participant_id, challenge_location_id))"
            )
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
                " ",
                createStatement
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

    receive() external payable {}

    fallback() external payable {}
}
