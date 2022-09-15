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
    }

    function initializeBaseTables() public payable onlyOwner {
        mapSkinsTableName = SQLHelpers.toCreateFromSchema(
            "mapSkins",
            "(id integer primary key not null, skinName text not null, ipfsHash text not null)"
        );
        challengesTableName = SQLHelpers.toCreateFromSchema(
            "challenges",
            "(id integer primary key not null, skinName text not null, ipfsHash text not null)"
        );
        challengeLocationsTableName = SQLHelpers.toCreateFromSchema(
            "challenge_locations",
            "(id integer primary key not null, skinName text not null, ipfsHash text not null)"
        );
        participantsTableName = SQLHelpers.toCreateFromSchema(
            "participants",
            "(id integer primary key not null, skinName text not null, ipfsHash text not null)"
        );
        participantProgressTableName = SQLHelpers.toCreateFromSchema(
            "participant_progress",
            "(id integer primary key not null, skinName text not null, ipfsHash text not null)"
        );
    }

    function create(string memory prefix, string memory createStatement)
        public
        payable
        onlyOwner
        returns (string memory)
    {
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
