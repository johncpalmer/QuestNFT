# LevelNFT
NFTs that can beat levels and earn score. On-chain save states.

### Level NFTs
Each LevelNFT keeps track of its current score and which levels it has beaten. Beating levels adds to score.

Scored is saved for a given pair of token ID + owner.

When a LevelNFT is transferred, the token's score changes based on its new owner. However, if an owner regains possession of the same token ID they were previously using, they resume from their previou score + levels beaten.

### Adding Levels
- The owner of the contract can add new levels
- Levels implement a function to tell if a given address + tokenId have beaten the level
- Each level has its own score


