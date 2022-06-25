// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

// Interface for a new quest, which can be beaten to increase xp.
interface IQueset {

    // Implements logic to tell if this tokenId has beaten this level.
    function isCompleted(
        uint256 tokenId,
        // Optional arbitrary data the user can pass in to verify a level was completed.
        bytes calldata userData
    ) external returns (bool);
}