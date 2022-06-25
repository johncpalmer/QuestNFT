// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IQuest.sol";
import "solmate/tokens/ERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "base64/base64.sol";

contract QuestNFT is ERC721, Ownable {
    // Quest numbers auto-increment as they are added by the contract owner.
    uint256 public latestQuest;

    // Mapping from quest numbers to addresses of their implementations.
    mapping (uint256 => IQuest) public quests;

    // Mapping from address to quest number.
    mapping (IQuest => uint256) public questIds;

    // Mapping from quest number to how much XP it's worth to complete it.
    mapping (uint256 => uint256) public questValues;
    
    // Keeps track of the quests completed by a given tokenId, while owned by a specific address.
    // This allows a previous owner of a token ID to resume if they get the token back.
    mapping (bytes32 => mapping (uint256 => bool)) public questsBeatenByTokenKey;

    // The current XP of each key, how many quests a token ID and owner pair has beaten.
    mapping (bytes32 => uint256) public xpByKey;

    constructor() ERC721("QuestNFT", "QNFT") {
        latestQuest = 1;
    }

    // Generate a unique key based on tokenId + owner address.
    function getKey(uint256 tokenId, address owner) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(tokenId, owner));
    }

    function getXp(uint256 tokenId) internal view returns (uint256) {
        return xpByKey[getKey(tokenId, ownerOf[tokenId])];
    }

    // Allows the owner of the contract to add new quest.
    function addQuest(address questAddress, uint256 questValue) public onlyOwner {
        quests[latestQuest] = IQuest(questAddress);
        questValues[latestQuest] = questValue;
        unchecked {
            ++latestQuest;
        }
    }

    // Helper function to check if this token ID has previously beaten a quest.
    function hasTokenIdBeatenQuest(uint256 tokenId, uint256 quest) public view returns(bool) {
        bytes32 key = getKey(tokenId, ownerOf[tokenId]);
        return questsBeatenByTokenKey[key][quest];
    }

    // Function to change the score of a given tokenId. Only called by quests.
    function changeScore(uint256 tokenId, uint256 delta) onlyQuests {
        bytes32 key = getKey(tokenId, ownerOf[tokenId]);
        xpByKey[key] += delta;
    }
    
    // Function to beat a quest. If successful, adds to this token's xp and tracks as beaten by this owner + tokenID.
    function beatQuest(uint256 quest, uint256 tokenId, bytes calldata userData) external returns(bool) {
        // Only the owner can call the function to beat the quest.
        require(ownerOf[tokenId] == msg.sender);

        IQuest _quest = IQuest(quests[quest]);

        if (_quest.isCompleted(msg.sender, userData)) {
            
            // Make sure this user has not already beaten this quest with this tokenId;
            require(!hasTokenIdBeatenQuest(tokenId, quest));
            
            // Mark this quest as completed by this token ID.
            bytes32 key = getKey(tokenId, msg.sender);
            questsBeatenByTokenKey[key][quest] = true;
            
            // Increase this token's xp.
            xpByKey[getKey(tokenId, ownerOf[tokenId])] += questValues[quest];
            return true;
        }
        return false;
    }

    function generateSVG(uint256 tokenId) internal view returns (bytes memory svg) {
        svg = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">"',
            xpByKey[getKey(tokenId, ownerOf[tokenId])],
            '"</text></svg>'
        );
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"QuestNFT",',
                                '"image":"data:image/svg+xml;base64,',
                                Base64.encode(bytes(generateSVG(tokenId))),
                                '", "description": "NFT that can beat quests and earn XP.",',
                                '"xp": "',
                                xpByKey[getKey(tokenId, ownerOf[tokenId])],
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    modifier onlyQuests {
      require(questIds[msg.sender] > 0);
      _;
   }
}
