# StacksGuild
## A guild system for lending and borrowing NFTs built on **Stacks**

There are currently four major roles in the blockchain gaming industry: **players**, **guilds**, **developers**, and **investors**. The **players** are at the forefront, steering the direction of the industry, with their attention predominantly towards income potential. Guilds are growing in popularity as a method to attract players and reduce financial barriers to entry. Guild members pool funds together, buy assets and then loan those assets to incoming players in exchange for a percentage of the new players' "earnings"'.

The **guilds** are the enablers of **GameFi**. They remove barriers, build communities, and connect players with the materials needed to be successful in their chosen games. Guilds give members access to NFTs needed for the "play-to-earn" games as well as knowledge from experts in these games.

**Stacks Guild** gives additional functionality to a traditional NFT(SIP-009) to track who is the user, set the user, and validate if the loan already expired.
With a marketplace-like, We list, unlist, and loan an NFT for a fixed price per duration.

## Implementation
Stacks Guild is based on two smart contracts:
1. An NFT smart contract based on SIP009 to add additional functionalities like a dual profile: owner and user; and three functions: getUser, setUser, getExpires; to set a principal as a user, get the current user and the expiration of the loan.
2. And a second smart to manage the NFTs loans, it  lists NFTs to be available for lending, cancel listings, and fulfill listing. It’s important to note that this is a non-custodial approach. For the lending process there is no NFT transfer, only a setup of the user principal and the loan duration based on the block height.

It is the responsibility of the final NFTs utilities implementation to consider the roles and the corresponding rewards.
