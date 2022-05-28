// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./ILevelChecker.sol";
import "solmate/tokens/ERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";


contract LevelingNFT is ERC721, Ownable {
    uint latestLevel;
    mapping (uint => ILevelChecker) levels;
    mapping (uint => uint) levelValues;
    
    mapping (uint256 => uint) lastLevelBeatenByTokenId;
    mapping (uint256 => uint) scoreByTokenId;

    constructor() ERC721("LevelNFT", "LNFT") public {
        latestLevel = 1;
    }

    function addLevel(address levelAddress, uint levelValue) public onlyOwner {
        levels[latestLevel] = ILevelChecker(levelAddress);
        levelValues[latestLevel] = levelValue;
        latestLevel++;
    }
    

    //TODO: Require that you beat the level before it?
    function beatLevel(uint level, uint256 tokenId, bytes memory userData) public returns(bool) {
        // Only the owner can call the function to beat the level.
        require(ownerOf[tokenId] == msg.sender);

        ILevelChecker _level = ILevelChecker(levels[level]);

        if (_level.isCompleted(msg.sender, userData)) {
            
            // Make sure this user has not beaten this level already.
            require(!lastLevelBeatenByTokenId[tokenId] == (level - 1));
            
            // Mark this level as completed by this token ID.
            levelsBeatenByTokenId[tokenId][level] = true;
            
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

        // Before transferring, reset levels beaten and score.


        // Tried to do this
        delete levelsBeatenByTokenId[id];
        
        // Doing this instead
        for (uint i = 0; i <= latestLevel; i++) {
            levelsBeatenByTokenId[id][i] = false;
        }


        scoreByTokenId[id] = 0;

        emit Transfer(from, to, id);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {

    }

}
