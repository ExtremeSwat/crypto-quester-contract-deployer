// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@tableland/evm/contracts/ITablelandTables.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./SQLHelpers.sol";

contract CryptoQuestDeployer is Ownable, ERC721Holder {
    // base tables
    string mapSkinsTableName;
    string challengesTableName;
    string challengeLocationsTableName;
    string participantsTableName;
    string participantProgressTableName;

    // additional tables
    mapping(string => uint256) customTables;

    // Interface to the `TablelandTables` registry contract
    ITablelandTables private _tableland;

    constructor(address registry) payable {
        _tableland = ITablelandTables(registry);

        initializeBaseTables();
    }

    function initializeBaseTables() public payable onlyOwner {
        mapSkinsTableName = SQLHelpers.toNameFromId(
            "mapSkins",
            _tableland.createTable(
                address(this),
                SQLHelpers.toCreateFromSchema(
                    "mapSkins",
                    "(id integer primary key not null, skinName text not null, ipfsHash text not null)"
                )
            )
        );

        challengesTableName = SQLHelpers.toNameFromId(
            "challenges",
            _tableland.createTable(
                address(this),
                SQLHelpers.toCreateFromSchema(
                    "challenges",
                    "(id integer primary key NOT NULL,title text not null unique,description text not null,fromTimestamp integer not null,toTimestamp integer not null,triggerTimestamp integer,owner text not null,creationTimestamp integer not null,mapSkinId integer)"
                )
            )
        );

        challengeLocationsTableName = SQLHelpers.toNameFromId(
            "challenge_locations",
            _tableland.createTable(
                address(this),
                SQLHelpers.toCreateFromSchema(
                    "challenge_locations",
                    "(id integer not null primary key,hint TEXT,latitude real not null,longitude real not null,creationTimestamp integer not null,challengeId integer not null)"
                )
            )
        );

        participantsTableName = SQLHelpers.toNameFromId(
            "participants",
            _tableland.createTable(
                address(this),
                SQLHelpers.toCreateFromSchema(
                    "participants",
                    "(id integer primary key not null, participant_address text not null, join_timestamp integer not null, challengeId integer not null, unique(participant_address, challengeId)"
                )
            )
        );

        participantProgressTableName = SQLHelpers.toNameFromId(
            "participant_progress",
            _tableland.createTable(
                address(this),
                SQLHelpers.toCreateFromSchema(
                    "participant_progress",
                    "(id integer primary key not null, challenge_participant_id integer not null, challenge_location_id integer not null, challenge_visit_timestamp integer not null)"
                )
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
