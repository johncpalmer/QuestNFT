// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./ILevelChecker.sol";

contract LevelingNFT {
    mapping (uint => ILevelChecker) levels;
    mapping (uint => uint) levelValues;
    mapping (address => mapping (uint => bool)) levelsBeaten;
    
    mapping (uint => uint) scoreByTokenId;

    function calculateScore


}
