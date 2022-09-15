// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./CryptoQuestDeployer.sol";

abstract contract CryptoQuest is CryptoQuestDeployer {

    //Events
    event ChallengeCreated(address indexed _challengeOwner);

    function createNewChallenge() public returns (uint256) {

    }

    function checkIfChallengeHasBeenComplete() public returns (uint256) {
        
    }


    function addNewSkin(string memory skinName, string memory ipfsHash) payable {
        string insertStatement = SQLHelpers.toInsert
        (
            mapSkinsTableName, 
            string.concat (
                skinName,
                ipfsHash
            )
        );

        _tableland.runSQL(insertStatement);
    }
}
