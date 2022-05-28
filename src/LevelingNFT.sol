// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./ILevelChecker.sol";
import "solmate/tokens/ERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "base64/base64.sol";

contract LevelingNFT is ERC721, Ownable {
    // Level numbers auto-increment as they are added by the contract owner.
    uint latestLevel;

    // Mapping from level numbers to addresses of their implementations.
    mapping (uint => ILevelChecker) public levels;

    // Mapping from level number to how many points it's worth to complete it.
    mapping (uint => uint) public levelValues;
    
    // Keeps track of the levels beaten by a given tokenId, while owned by a specific address.
    // This allows a previous owner of a token ID to resume if they get the token back.
    mapping (uint256 => mapping (uint => bool)) public levelsBeatenByTokenKey;

    // The current score of each token ID, based on the current owner and how many levels they've beaten with it.
    mapping (uint256 => uint) public scoreByTokenId;

    constructor() ERC721("LevelNFT", "LNFT") public {
        latestLevel = 1;
    }

    // Generate a unique key based on tokenId + owner address.
    function getKey(uint256 tokenId, address owner) internal pure returns(uint) {
        return uint(keccak256(abi.encodePacked(tokenId, owner)));
    }

    // Allows the owner of the contract to add new levels.
    function addLevel(address levelAddress, uint levelValue) public onlyOwner {
        levels[latestLevel] = ILevelChecker(levelAddress);
        levelValues[latestLevel] = levelValue;
        latestLevel++;
    }

    // Helper function to check if this token ID has previously beaten a level.
    function hasTokenIdBeatenLevel(uint256 tokenId, uint level) public view returns(bool) {
        uint key = getKey(tokenId, ownerOf[tokenId]);
        return levelsBeatenByTokenKey[key][level];
    }
    
    // Function to beat a level. If successful, adds to this token's score and tracks as beaten by this owner + tokenID.
    function beatLevel(uint level, uint256 tokenId, bytes memory userData) public returns(bool) {
        // Only the owner can call the function to beat the level.
        require(ownerOf[tokenId] == msg.sender);

        ILevelChecker _level = ILevelChecker(levels[level]);

        if (_level.isCompleted(msg.sender, userData)) {
            
            // Make sure this user has not already beaten this level with this tokenId;
            require(!hasTokenIdBeatenLevel(tokenId, level));
            
            // Mark this level as completed by this token ID.
            uint key = getKey(tokenId, msg.sender);
            levelsBeatenByTokenKey[key][level] = true;
            
            // Increase this token's score.
            scoreByTokenId[tokenId] += levelValues[level];
            return true;
        }
        return false;
    }

    // Override to update the token's score when transferring to another user.
    // TODO: Mint a souvenir token for the from address to remind them of their old save file.
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        require(from == ownerOf[id], "WRONG_FROM");
        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        delete getApproved[id];

        ownerOf[id] = to;

        // When transferring, reset score based on the new owner's previous progress (gas expensive but whatever).
        // Don't need to reset levels because it's also keyed by the owner address.
        resumePreviousHighScore(id);

        emit Transfer(from, to, id);
    }

    // Resets a token's score based on its new owner, and their prior progress.
    // Mapping will still hold all their previous progress bc it's keyed by tokenId + address.
    function resumePreviousHighScore(uint256 tokenId) internal {
        scoreByTokenId[tokenId] = 0;
        for (uint i = 0; i <= latestLevel; i++) {
            if(hasTokenIdBeatenLevel(tokenId, i)) {
                scoreByTokenId[tokenId] += levelValues[i];
            }
        }
    }

    function generateSVG(uint256 tokenId) internal view returns (bytes memory svg) {
        svg = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">"',
            scoreByTokenId[tokenId],
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
                                '{"name":"LevelNFT",',
                                '"image":"data:image/svg+xml;base64,',
                                Base64.encode(bytes(generateSVG(tokenId))),
                                '", "description": "NFT that can beat levels.",',
                                '"score": "',
                                scoreByTokenId[tokenId],
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}
