// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./ILevelChecker.sol";
import "solmate/tokens/ERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract LevelingNFT is ERC721, Ownable {
    uint latestLevel;
    mapping (uint => ILevelChecker) public levels;
    mapping (uint => uint) public levelValues;
    
    // Keeps track of the levels beaten by a given tokenId, while owned by a specific address.
    mapping (uint256 => mapping (uint => bool)) public levelsBeatenByTokenKey;
    mapping (uint256 => uint) public scoreByTokenId;

    constructor() ERC721("LevelNFT", "LNFT") public {
        latestLevel = 1;
    }

    function addLevel(address levelAddress, uint levelValue) public onlyOwner {
        levels[latestLevel] = ILevelChecker(levelAddress);
        levelValues[latestLevel] = levelValue;
        latestLevel++;
    }

    function hasTokenIdBeatenLevel(uint256 tokenId, uint level) public pure returns(bool) {
        uint key = getKey(tokenId, ownerOf[tokenId]);
        return levelsBeatenByTokenKey(key);
    }
    
    function beatLevel(uint level, uint256 tokenId, bytes memory userData) public returns(bool) {
        // Only the owner can call the function to beat the level.
        require(ownerOf[tokenId] == msg.sender);

        ILevelChecker _level = ILevelChecker(levels[level]);

        if (_level.isCompleted(msg.sender, userData)) {
            
            // Make sure this user has not already beaten this level with this tokenId;
            uint key = getKey(tokenId, msg.sender);
            require(!levelsBeatenByTokenKey[key][level]);
            
            // Mark this level as completed by this token ID.
            levelsBeatenByTokenKey[key][level] = true;
            
            // Increase this token's score.
            scoreByTokenId[tokenId] += levelValues[level];
            return true;
        }
        return false;
    }

    // Override to clear the token's score + levels beaten.
    // TODO: Mint a souvenir token for the from address fossilizing their high score.
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

        // When transferring, reset score to the new owner's previous (gas expensive but whatever).
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
                scoreByTokenId += levelValues[i];
            }
        }
    }

    function getKey(uint256 tokenId, address owner) internal pure returns(uint) {
        return uint(keccak256(abi.encodePacked(tokenId, owner)));
    }

    function generateSVG(uint256 tokenId) internal pure returns (bytes memory svg) {
        svg = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">',
            scoreByTokenId[tokenId],
            '</text></svg>'
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
