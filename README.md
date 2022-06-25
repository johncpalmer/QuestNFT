# QuestNFT
NFTs that can beat quests and earn XP. On-chain save states.

### Quest NFTs
Each QuestNFT keeps track of its current XP and which quests it has beaten. Beating quests earns XP.

XP is saved based on a given pair of token ID + owner. This allows transferring of the NFTs in a way where
a new owner has 0 XP, but previous owners can recover their XP if they gain the same NFT back in the future.

### Adding Quests
- The owner of the QuestNFT contract can add new quests
- Quests implement a function that allows an NFT owner to beat the quest
- Each quest is worth a specific amount of XP


