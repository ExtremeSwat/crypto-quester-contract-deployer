// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @dev Library of helpers for generating SQL statements from common parameters.
 */
library SQLHelpers {
    /**
     * @dev Generates a properly formatted table name from a prefix and table id.
     *
     * prefix - the user generated table prefix as a string
     * tableId - the Tableland generated tableId as a uint256
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toNameFromId(string memory prefix, uint256 tableId)
        public
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    prefix,
                    "_",
                    Strings.toString(block.chainid),
                    "_",
                    Strings.toString(tableId)
                )
            );
    }

    /**
     * @dev Generates a CREATE statement based on a desired schema and table prefix.
     *
     * prefix - the user generated table prefix as a string
     * schema - a comma seperated string indicating the desired prefix. Example: "int id, text name"
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toCreateFromSchema(string memory prefix, string memory schema)
        public
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "CREATE TABLE ",
                    prefix,
                    "_",
                    Strings.toString(block.chainid),
                    " (",
                    schema,
                    ")"
                )
            );
    }

    /**
     * @dev Generates an INSERT statement based on table prefix, tableId, columns, and values.
     *
     * prefix - the user generated table prefix as a string.
     * tableId - the Tableland generated tableId as a uint256.
     * columns - a string encoded ordered list of columns that will be updated. Example: "name, age".
     * values - a string encoded ordered list of values that will be inserted wrapped in parentheses. Example: "'jerry', 24". Values order must match column order.
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toInsert(
        string memory prefix,
        uint256 tableId,
        string memory columns,
        string memory values
    ) public view returns (string memory) {
        string memory name = toNameFromId(prefix, tableId);
        (prefix, tableId);
        return
            string(
                abi.encodePacked(
                    "INSERT INTO ",
                    name,
                    " (",
                    columns,
                    ") VALUES (",
                    values,
                    ")"
                )
            );
    }

    /**
     * @dev Generates an INSERT statement based on table prefix, tableId, columns, and values.
     *
     * name - full name of the table
     * columns - a string encoded ordered list of columns that will be updated. Example: "name, age".
     * values - a string encoded ordered list of values that will be inserted wrapped in parentheses. Example: "'jerry', 24". Values order must match column order.
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toInsertWithFullName(
        string memory name,
        string memory columns,
        string memory values
    ) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "INSERT INTO ",
                    name,
                    " (",
                    columns,
                    ") VALUES (",
                    values,
                    ")"
                )
            );
    }

    /**
     * @dev Generates an Update statement based on table prefix, tableId, setters, and filters.
     *
     * prefix - the user generated table prefix as a string
     * tableId - the Tableland generated tableId as a uint256
     * setters - a string encoded set of updates. Example: "name='tom', age=26"
     * filters - a string encoded list of filters or "" for no filters. Example: "id<2 and name!='jerry'"
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toUpdate(
        string memory prefix,
        uint256 tableId,
        string memory setters,
        string memory filters
    ) public view returns (string memory) {
        string memory name = toNameFromId(prefix, tableId);
        (prefix, tableId);
        string memory filter = "";
        if (bytes(filters).length > 0) {
            filter = string(abi.encodePacked(" WHERE ", filters));
        }
        return
            string(abi.encodePacked("UPDATE ", name, " SET ", setters, filter));
    }

     /**
     * @dev Generates an Update statement based on table prefix, tableId, setters, and filters.
     *
     * name - full name of the table
     * setters - a string encoded set of updates. Example: "name='tom', age=26"
     * filters - a string encoded list of filters or "" for no filters. Example: "id<2 and name!='jerry'"
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toUpdateWithFullName(
        string memory name,
        string memory setters,
        string memory filters
    ) public view returns (string memory) {
        string memory filter = "";
        if (bytes(filters).length > 0) {
            filter = string(abi.encodePacked(" WHERE ", filters));
        }
        return
            string(abi.encodePacked("UPDATE ", name, " SET ", setters, filter));
    }

    /**
     * @dev Generates a Delete statement based on table prefix, tableId, and filters.
     *
     * prefix - the user generated table prefix as a string.
     * tableId - the Tableland generated tableId as a uint256.
     * filters - a string encoded list of filters. Example: "id<2 and name!='jerry'".
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toDelete(
        string memory prefix,
        uint256 tableId,
        string memory filters
    ) public view returns (string memory) {
        string memory name = toNameFromId(prefix, tableId);
        (prefix, tableId);
        return
            string(abi.encodePacked("DELETE FROM ", name, " WHERE ", filters));
    }

    /**
     * @dev Generates a Delete statement based on table prefix, tableId, and filters.
     *
     * name - the user generated table prefix as a string.
     * tableId - the Tableland generated tableId as a uint256.
     * filters - a string encoded list of filters. Example: "id<2 and name!='jerry'".
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toDeleteWithFullName(
        string memory name,
        string memory filters
    ) public view returns (string memory) {
        return
            string(abi.encodePacked("DELETE FROM ", name, " WHERE ", filters));
    }
}