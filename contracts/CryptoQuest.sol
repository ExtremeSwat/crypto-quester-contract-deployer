// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./CryptoQuestDeployer.sol";

contract CryptoQuest is CryptoQuestDeployer {
    constructor(address registry) CryptoQuestDeployer(registry) {}

    /**
     * @dev Generates a checkpoint for a given challengeId
     *
     */
    function createCheckpoint(
        uint256 checkpointId,
        uint256 challengeId,
        uint256 ordering,
        string memory title,
        string memory iconUrl,
        uint256 iconId,
        string memory lat,
        string memory lng
    ) external payable {
        string memory values = string.concat(
            getUintInQuotes(checkpointId, true),
            getUintInQuotes(challengeId, true),
            getUintInQuotes(ordering, true),
            getStringInQuotes(title, true),
            getStringInQuotes(iconUrl, true),
            getUintInQuotes(iconId, true),
            getStringInQuotes(lat, true),
            getStringInQuotes(lng, true),
            getUintInQuotes(block.timestamp, false)
        );

        _tableland.runSQL(
            address(this),
            challengeCheckpointsTableId,
            SQLHelpers.toInsert(
                challengeCheckpointsPrefix,
                challengeCheckpointsTableId,
                "id,challengeId,ordering,title,iconUrl,iconId,lat,lng,creationTimestamp",
                values
            )
        );
    }

    function createCheckpointTrigger(
        uint256 checkpointTriggerId,
        uint256 checkpointId,
        string memory title,
        string memory imageUrl,
        uint8 isPhotoRequired,
        string memory photoDescription,
        uint8 isUserInputRequired,
        string memory userInputDescription,
        string memory userInputAnswer
    ) external payable {
        string memory values = string.concat(
            getUintInQuotes(checkpointTriggerId, true),
            getUintInQuotes(checkpointId, true),
            getStringInQuotes(title, true),
            getStringInQuotes(imageUrl, true),
            getUintInQuotes(isPhotoRequired, true),
            getStringInQuotes(photoDescription, true),
            getUintInQuotes(isUserInputRequired, true),
            getStringInQuotes(userInputDescription, true),
            getStringInQuotes(userInputAnswer, false)
        );

        _tableland.runSQL(
            address(this),
            challengeCheckpointTriggersTableId,
            SQLHelpers.toInsert(
                challengeCheckpointTriggerPrefix,
                challengeCheckpointTriggersTableId,
                "id,checkpointId,title,imageUrl,isPhotoRequired,photoDescription,isUserInputRequired,userInputDescription,userInputAnswer",
                values
            )
        );
    }

    function removeCheckpointTrigger(uint256 challengeCheckpointId)
        external
        payable
    {
        _tableland.runSQL(
            address(this),
            challengeCheckpointId,
            SQLHelpers.toDelete(
                challengeCheckpointsPrefix,
                challengeCheckpointsTableId,
                string.concat("id=", Strings.toString(challengeCheckpointId))
            )
        );
    }

    /**
     * @dev Removes a checkpoint
     */
    function removeCheckpoint(uint256 checkpointId) external payable {
        _tableland.runSQL(
            address(this),
            challengeCheckpointsTableId,
            SQLHelpers.toDelete(
                challengeCheckpointsPrefix,
                challengeCheckpointsTableId,
                string.concat("id = ", Strings.toString(checkpointId))
            )
        );
    }

    function archiveChallenge(uint256 challengeId, uint256 archiveEnum)
        external
        payable
    {
        _tableland.runSQL(
            address(this),
            challengesTableId,
            SQLHelpers.toUpdate(
                challengesPrefix,
                challengesTableId,
                string.concat(
                    "challengeStatus = ",
                    Strings.toString(archiveEnum)
                ),
                string.concat("id = ", Strings.toString(challengeId))
            )
        );
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
        uint256 id,
        string memory title,
        string memory description,
        uint256 fromTimestamp,
        uint256 toTimestamp,
        uint256 mapSkinId,
        address owner,
        string memory imagePreviewURL
    ) external payable {
        // preventing jumbled timestamps
        string memory values = string.concat(
            getUintInQuotes(id, true),
            getStringInQuotes(title, true),
            getStringInQuotes(description, true),
            getUintInQuotes(fromTimestamp, true),
            getUintInQuotes(toTimestamp, true),
            getUserAddressAsString(owner, true),
            getUintInQuotes(block.timestamp, true),
            getUintInQuotes(mapSkinId, true),
            getUintInQuotes(0, true),
            getStringInQuotes(imagePreviewURL, false)
        );

        _tableland.runSQL(
            address(this),
            challengesTableId,
            SQLHelpers.toInsert(
                challengesPrefix,
                challengesTableId,
                "id,title,description,fromTimestamp,toTimestamp,userAddress,creationTimestamp,mapSkinId,challengeStatus,imagePreviewURL",
                values
            )
        );
    }

    /**
     * @dev Allows a user to participate in a challenge
     *
     * challengeId - id of the challenge [mandatory]
     */

    function participateInChallenge(
        uint256 challengeId,
        address participantAddress
    ) external payable {
        string memory insertStatement = SQLHelpers.toInsert(
            participantsPrefix,
            participantsTableId,
            "userAddress, joinTimestamp, challengeId",
            string.concat(
                getUserAddressAsString(participantAddress, true),
                getUintInQuotes(block.timestamp, true),
                Strings.toString(challengeId)
            )
        );

        _tableland.runSQL(address(this), participantsTableId, insertStatement);
    }

    /**
     * @dev Allows an owner to start his own challenge
     *
     * challengeId - id of the challenge [mandatory]
     */
    function triggerChallengeStart(uint256 challengeId, uint256 challengeStatus)
        external
        payable
    {
        _tableland.runSQL(
            address(this),
            challengesTableId,
            SQLHelpers.toUpdate(
                challengesPrefix,
                challengesTableId,
                string.concat(
                    "triggerTimestamp= ",
                    Strings.toString(block.timestamp),
                    ",challengeStatus=",
                    Strings.toString(challengeStatus)
                ),
                string.concat("id=", Strings.toString(challengeId))
            )
        );
    }

    function setChallengeWinner(
        uint256 challengeId,
        address challengeWinner,
        uint256 challengeStatus
    ) external payable {
        _tableland.runSQL(
            address(this),
            challengesTableId,
            SQLHelpers.toUpdate(
                challengesPrefix,
                challengesTableId,
                string.concat(
                    "challengeStatus=",
                    Strings.toString(challengeStatus),
                    ",winnerAddress=",
                    getUserAddressAsString(challengeWinner, false)
                ),
                string.concat("id =", Strings.toString(challengeId))
            )
        );
    }

    function participantProgressCheckIn(
        uint256 challengeCheckpointId,
        address participantAddress
    ) external payable {
        _tableland.runSQL(
            address(this),
            participantsProgressTableId,
            SQLHelpers.toInsert(
                participantProgressPrefix,
                participantsProgressTableId,
                "userAddress, challengeCheckpointId, visitTimestamp",
                string.concat(
                    getUserAddressAsString(participantAddress, true),
                    getUintInQuotes(challengeCheckpointId, true),
                    getUintInQuotes(block.timestamp, false)
                )
            )
        );
    }

    function createNewUser(address userAddress, string memory nickName)
        public
        payable
    {
        _tableland.runSQL(
            address(this),
            usersTableId,
            SQLHelpers.toInsert(
                usersPrefix,
                usersTableId,
                "userAddress, nickname, registeredDate",
                string.concat(
                    getUserAddressAsString(userAddress, true),
                    getStringInQuotes(nickName, true),
                    getUintInQuotes(block.timestamp, false)
                )
            )
        );
    }

    // ------------------------------------------ PRIVATE METHODS ------------------------------------------------

    function getUserAddressAsString(address sender, bool attachComma)
        private
        pure
        returns (string memory)
    {
        string memory toRet = string.concat(
            "'",
            Strings.toHexString(uint256(uint160(sender)), 20),
            "'"
        );
        
        if (attachComma) {
            toRet = string.concat(toRet, ",");
        }
        
        return toRet;
    }

    function getUintInQuotes(uint256 value, bool attachComma)
        private
        pure
        returns (string memory)
    {
        string memory toRet = string.concat(Strings.toString(value));
        if (attachComma) {
            toRet = string.concat(toRet, ",");
        }

        return toRet;
    }

    function getStringInQuotes(string memory value, bool attachComma)
        private
        pure
        returns (string memory)
    {
        string memory toRet = string.concat("'", value, "'");
        if (attachComma) {
            toRet = string.concat(toRet, ",");
        }

        return toRet;
    }
}
