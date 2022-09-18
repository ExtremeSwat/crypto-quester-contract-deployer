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

        // innitting base entities
        initializeBaseTables();

        // running data seeds
        mapSkinsDataSeed();
    }

    function initializeBaseTables() public payable onlyOwner {
        mapSkinsTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                mapSkinsPrefix,
                "(id integer primary key not null, skinName text not null, imagePreviewUrl text not null, mapUri text not null, unique(mapUri), unique(skinName))"
            )
        );

        challengesTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                challengesPrefix,
                "(id integer primary key NOT NULL,title text not null unique,description text not null,fromTimestamp integer not null,toTimestamp integer not null,triggerTimestamp integer,ownerAddress text not null,creationTimestamp integer not null,mapSkinId integer, challengeStatus integer not null, unique(title))"
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
                "(id integer primary key not null, participantAddress text not null, join_timestamp integer not null, challengeId integer not null, unique(participantAddress, challengeId)"
            )
        );

        participantsProgressTableId = _tableland.createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                "participant_progress",
                "(id integer primary key not null, participantst_id integer not null, challenge_location_id integer not null, visit_timestamp integer not null, unique(challenge_participant_id, challenge_location_id))"
            )
        );
    }

    function mapSkinsDataSeed() public onlyOwner{
        string memory multipleRowsStatement = SQLHelpers.toInsertMultipleRows
        (
            mapSkinsPrefix, 
            mapSkinsTableId, 
            'skinName, imagePreviewUrl, mapUri',
            string.concat
                (
                    "('Standard', 'https://api.mapbox.com/styles/v1/juvie22/cjtizpqis1exb1fqunbiqcw4y/static/26.1025,44[…]iJjajNoN3hzeDEwMDFuMzNxZ2txeXR1ZnIzIn0.2Thoi_xQLD5f9d_R_DD7lg', 'mapbox://styles/juvie22/cjtizpqis1exb1fqunbiqcw4y'),",
                    "('Comics', 'https://api.mapbox.com/styles/v1/juvie22/cjvdxmakw0fqh1fp8z47jqge5/static/26.1025,44[…]iJjajNoN3hzeDEwMDFuMzNxZ2txeXR1ZnIzIn0.2Thoi_xQLD5f9d_R_DD7lg', 'mapbox://styles/juvie22/cjvdxmakw0fqh1fp8z47jqge5'),",
                    "('Neon', 'https://api.mapbox.com/styles/v1/juvie22/cjvuxjxne0l4p1cpjbjwtn0k9/static/26.1025,44[…]iJjajNoN3hzeDEwMDFuMzNxZ2txeXR1ZnIzIn0.2Thoi_xQLD5f9d_R_DD7lg', 'mapbox://styles/juvie22/cjvuxjxne0l4p1cpjbjwtn0k9'),",
                    "('Blueprint', 'https://api.mapbox.com/styles/v1/juvie22/cjvuxaacd3ncv1cqvd6edffc2/static/26.1025,44[…]iJjajNoN3hzeDEwMDFuMzNxZ2txeXR1ZnIzIn0.2Thoi_xQLD5f9d_R_DD7lg', 'mapbox://styles/juvie22/cjvuxaacd3ncv1cqvd6edffc2'),",
                    "('Western', 'https://api.mapbox.com/styles/v1/juvie22/cjvuxaacd3ncv1cqvd6edffc2/static/26.1025,44[…]iJjajNoN3hzeDEwMDFuMzNxZ2txeXR1ZnIzIn0.2Thoi_xQLD5f9d_R_DD7lg', 'mapbox://styles/juvie22/cjvuwejv70iaw1cqnb846caqy'),",
                    "('Candy', 'https://api.mapbox.com/styles/v1/juvie22/cjvuvwhv90rhn1cpbpgactgnm/static/26.1025,44[…]iJjajNoN3hzeDEwMDFuMzNxZ2txeXR1ZnIzIn0.2Thoi_xQLD5f9d_R_DD7lg', 'mapbox://styles/juvie22/cjvuvwhv90rhn1cpbpgactgnm'),",
                    "('Noir', 'https://api.mapbox.com/styles/v1/juvie22/cjtj02zko4xbc1fpkv8dtolu3/static/26.1025,44[…]iJjajNoN3hzeDEwMDFuMzNxZ2txeXR1ZnIzIn0.2Thoi_xQLD5f9d_R_DD7lg', 'mapbox://styles/juvie22/cjtj02zko4xbc1fpkv8dtolu3'),",
                    "('Virus', 'https://api.mapbox.com/styles/v1/juvie22/cj7i2ftv34zpd2smtm3ik41fq/static/26.1025,44[…]iJjajNoN3hzeDEwMDFuMzNxZ2txeXR1ZnIzIn0.2Thoi_xQLD5f9d_R_DD7lg', 'mapbox://styles/juvie22/cj7i2ftv34zpd2smtm3ik41fq')",
                )
         );

         _tableland.runSQL(address(this), mapSkinsTableId, multipleRowsStatement);
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
