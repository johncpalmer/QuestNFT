// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./QuestNFT.sol";

// Interface for a new quest, which can be beaten to increase xp.
interface IQuest {

    // Implements logic to tell if this tokenId has beaten this level. Has ability to call changeScore() in parent.
    function beatQuest(
        uint256 tokenId,
        // Optional arbitrary data the user can pass in to verify a level was completed.
        bytes calldata userData
    ) external payable returns (bool);
}