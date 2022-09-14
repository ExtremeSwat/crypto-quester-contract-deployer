// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@tableland/evm/contracts/ITablelandTables.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract CryptoQuestDeployer is Ownable, ERC721Holder {
    // A mapping that holds `tableName` and its `tableId`
    mapping(string => uint256) public tables;
    // nterface to the `TablelandTables` registry contract
    ITablelandTables private _tableland;

    constructor(address registry) payable {
        _tableland = ITablelandTables(registry);
    }

    receive() external payable {}

    fallback() external payable {}

    function create(string memory prefix, string memory createStatement) onlyOwner() public payable
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

        tables[tableName] = tableId;
    }
}
