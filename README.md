
## Table of Contents
- [Table of Contents](#table-of-contents)
- [Introduction](#introduction)
- [Gameplay](#gameplay)
- [Contracts](#contracts)
  - [Ranking System](#ranking-system)
  - [Payment Channels](#payment-channels)
  - [Manager](#manager)
  - [Rhascau](#rhascau)
- [Randomness](#randomness)

## Introduction

Rhascau is a strategy racing game written in Solidity, and compatible with any EVM-based blockchain. Rhascau allows users to decide on the stake of the game, meaning each of the players must provide given amount of ether ( >= 0 ) before entering the match. Winner takes it all (reduced by the provider fee).

Current contracts (arbiscan):
- [Rhascau](https://nova.arbiscan.io/address/0xe25b5f52cf174adb3ad85a95bdb1d24eaaf074ae)
- [Rhascau Manager](https://nova.arbiscan.io/address/0x0d120743c02963070eF1ABA05443CF0BB6A9B16D)
- [Rhascau Ranks](https://nova.arbiscan.io/address/0x45b47658298D0A063F7E21E0e93707E80E53a496)

## Gameplay

Winning the match requires doing a one full lap around 40-tile race track, counting from your spawn point. 

***Rules and Restrictions:***
- Vehicles on the board can be destroyed by collision, or DESTROY skill. Vehicle **A** destroys vehicle **B** by moving to the tile occupied by **B**.
- In order to win the race, vehicle must complete one lap, meaning **EXACTLY** 40 tiles. Vehicle can't cross the finish line in any situation.
- No friendly fire. Player **CAN NOT** destroy his own ships either via collision, or offensive skill. 
- There are always 4 participants in the race. Each of them starts with 2 vehicles on the board, and 2 in a base.
- Abilities can be used **ONLY** while moving with a vehicle that is already on the board. 

***Game loop:***
1. Generating a move from a future blockhash (current block + 2), via the commit-reveal scheme (see [Randomness](#randomness))
2. Selecting ability to be used, and vehicles that the ability can be used on (optional)
3. Moving vehicles / deploying another vehicle on the board

***Move generation:***

Each turn starts with a move generation (D6). Result indicates how many tiles player can move one of his vehicles (movement occurs only in one direction, towards the finish line).
Obtaining 1 or 6 allows player to deploy another vehicle on the board. 6 also gives the player a chance to make the extra turn.

***Skills:***

Rhascau introduces 4 abilities that players can use during the race. Those are put into two categories: offensive (used on enemy vehicles) and defensive (used on friendly vehicles). Each ability has a certain cooldown (CD) measured in player's turns:
- Dash: [*Defensive*, *CD = 1*]; Vehicle dashes one tile forward (you can finish the race with Dash / destroy enemy vehicles / you can also move one of the vehicles, and Dash with the other one) 
- Root: [*Offensive*, *CD = 3*]; Immobilizes one of the vehicles for 1 turn. Immobilized vehicle can't move and can't be a target of a self-Dash (other players can Dash into your Rooted vehicle, killing it).
- Bonus: [*Defensive*, *CD = 4*]; This ability allows player to generate the move once again in his turn 
- Destroy: [*Offensive*, *CD = once per game*]; Destroys selected vehicle. If, and only if, 2 players use this ability in a given match, race enters the "Rapid mode".

**Rapid mode** - Late game phase, where all the movement results (except the movement from Dash) are multiplied by 2, hence vehicles cover twice as much distance in a given turn.
## Contracts

Rhascau is dependent on 3 contracts `RhascauRanks.sol`, `RhascauManager.sol`, and `Rhascau.sol`. The last contract, `PaymentChannel.sol` is only used while playing via the front-end client.

**Short system overview** 

`Rhascau.sol` implements and handles the mentioned rules and restrictions, as well as stakes that players can agree on commiting in a match, before joining the match. Each user can get a ranking badge (soulbound NFT) and upgrade it according to their in-game actions, which is handled by `Ranks.sol`. `RhascauManager.sol` manages the ranking system, as well as payment channels.

Infrastructure is designed in such a way, in order to maintain user ranking progress, in case if the main game contract, `Rhascau.sol` would need to be changed.

### Ranking System

Players can mint an upgradable ranking badge in a form of a soulbound NFT. Upgrades are available after collecting certain amount of ranking points, which are assigned during the match, according to the following table. 

| Activity                 	| Points 	|
|--------------------------	|--------	|
| Participation in a match  | 50      |
| Winning a match           | 150    	|
| Destroying enemy vehicle 	| 20     	|
| First win of the day     	| 50    	|
| First game of the day    	| 50     	|
| Each 1 ETH won           	| 4000   	|


Thresholds for consecutive ranks are as follows:

| Rank    	| Points range     	|
|---------	|------------------	|
| SER     	| (0 - 1000]       	|
| DEGEN   	| (1000 - 5000]    	|
| ANALYST 	| (5000 - 10000]   	|
| TRADER  	| (10000 - 20000]  	|
| MINTER  	| (20000 - 50000]  	|
| HODLER  	| (50000 - 150000] 	|
| OG      	| 150000+          	|

### Payment Channels

Very simple contract, serving as an intermediary between user's personal crypto wallet and a burner address (burner addresses are stored in user's personal web browsers, and only they have the access to them). In order to create such a channel user must have a valid signature, which is generated based on both address of user wallet and address of burner created for him.

User can top up a payment channel with certain minimum amount of Ether, while burner wallet (which we then use for better user experience inside the game) treats the channel as a faucet.

In case of loosing the access to the burner address, each user can destroy the channel, collecting all the Ether from it.

### Manager

Contract responsible for managing the ranking system, as well as payment channels creation. (Pretty self explanatory, see: `RhascauManager.sol`).

### Rhascau

Heart of the game. Responsible for handling entire logic, as well as Ether transfers between players. 

**Interfaces**
- `IRhascauManager`: Interface for Rhascau Manager providing all functions necessary to assign ranking points and statistics
- `IArbSys`: Rhascau needs to obtain block data from L2 blockchain, in this particular example we use Arbitrum's [ArbSys](https://developer.arbitrum.io/arbos/precompiles#arbsys). 

**Data Structures**

In this section I will briefly describe data structures, and for the ease of reading they will be denoted as follows: `Struct`, **Array**, *Mapping*  

- `GameRoom`: this struct encapsulates wast majority of the data that each game is composed of. All the game matches are held in the array of this type. Shallow dive into the struct:
  - `GameInfo`: general information about the status of the game
  - **board**: array of 40 structs `Tile`. This is our race track. Each tile has a reference to `Vehicle`, as well as occupation state.
  - *players*: this structure maps each player (address) to each of his four `Vehicle`.
  - *cooldowns*: tracks `SkillsCooldown` for each player (address)
  - *diceRolls*: tracks `DiceRoll` for each player (address) 
  - *classToPlayer*: maps class of the player to his address.
  - *afkRecord*: tracks if given player is marked as AFK. If so, his time for the turn will be 0, hence other players will be able to skip him immediately. Each AFK player can rejoin at any time.
  - queue: keeps track of turns
  - killCount: tracks how many players used their "Destroy" ability (for the purpose of "Rapid Moves")
- *blockHashToBeUsed*: keeps track of the player's movement generations. (see: [Randomness](#randomness))
- *userToRewardTimer*: Maps player (address) to `RewardsTimer`. Keeps track of first win and game of the day.
- *isUserInGame*: Tracks if player is currently in a match.

## Randomness

Rhascau requires a frequent random numbers generation. In order to obtain **fast**, **cheap** and **reliable** (for the sake of our usage) randomness on-chain, we decided to go with well known **commit - reveal scheme**.

In **commit** stage, future block (current block + 2) is assigned to the user (*blockHashToBeUsed* mapping). After the given block arrives, user can reveal the value as long as the time between commit and reveal is less than 256 blocks. **Reveal** stage includes getting hash of the committed block and assigning the final result to the user.


