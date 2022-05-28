// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

// Interface for a new level, which can be beaten to increase score.
interface ILevelChecker {
    // `data` is any arbitrary bytes12 data needed by the gatekeeper implementation.
    function isCompleted(
        // address of user
        address participant,
        // Optional arbitrary data the user can pass in to verify a level was completed.
        bytes memory userData
    ) external view returns (bool);
}