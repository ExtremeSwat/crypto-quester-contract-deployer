// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./CryptoQuestDeployer.sol";

abstract contract CryptoQuest is CryptoQuestDeployer {
    //Events
    event ChallengeCreated(address indexed _challengeOwner, string skinName);

    function createNewChallenge() public returns (uint256) {
        
    }

    function addNewSkin(string memory skinName, string memory ipfsHash) public payable
    {
        string memory insertStatement = SQLHelpers.toInsert(
            mapSkinsTablePrefix,
            mapSkinsTableId,
            string.concat(
                "skinName,",
                "ipfsHash"
            ),
            string.concat(skinName, ipfsHash)
        );

        _tableland.runSQL(address(this), mapSkinsTableId, insertStatement);
    }
}
