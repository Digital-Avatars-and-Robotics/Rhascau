
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

Rhascau is a turn-based pod racing game which logic lays fully on the blockchain. It can be lunched on any EVM chain, [right now it is available on arbitrum goerli network](https://www.rhascau.com/). Rhascau allows users to decide on the stake of the game, meaning each of the players must provide given amount of ether ( >= 0 ) before entering the match. Winner takes it all (reduced by the provider fee).

## Gameplay

Winning the match requires doing one full lap around 1-D, 40-tile race track, counting from your spawn point. 

***Rules and Restrictions:***
- Vehicles on the board can be destroyed by collision, or DESTROY skill. Vehicle **A** destroys vehicle **B** by moving to the tile occupied by **B**.
- In order to win the race, vehicle must complete one lap, meaning **EXACTLY** 40 tiles. Vehicle can't cross the finishing line in any situation.
- No friendly fire. Player **CAN NOT** destroy his own ships eighter with collision, or offensive skill. 
- There are always 4 participants in the race, each of them starts with 2 vehicles on board, and 2 in base.
- Skills can be used **ONLY** while moving with a vehicle that is already on the board. 

***Game loop:***
1. Rolling the dice
2. Selecting skill to be used, and vehicles to be used on (optional)
3. Moving one of the ships / Putting another vehicle on the board

***Dice:***

Each turn starts with a dice roll (D6). Result indicates how many tiles player can move his vehicle (movement ocurrs only in one direction, towards finish line).
Obtaining 1 or 6 allows player to put another vehicle on the board.

***Skills:***

Rhascau intoduces 4 skills that players can use during the race. Those are put into two categories: offensive (used on enemy vehicles) and defensive (used on friendly ships). Each skill has a certaing cooldown (CD) measured in player's turns:
- Dash: [*Defensive*, *CD = 1*]; Vehicle dashes one tile forward (this movement can finish the race / destroy enemy vehicles) 
- Root: [*Offensive*, *CD = 3*]; Immobilizes one of the vehicles for 1 turn. Immobilized vehicle can't move and can't be a target of Dash.
- Bonus: [*Defensive*, *CD = 4*]; This skill allows player to roll the dice once again in his turn 
- Destroy: [*Offensive*, *CD = once per game*]; Destroys selected vehicle on the board. After 2 players use this ability in given game, race enters the "Rapid mode".

**Rapid mode** - Late game phase, where all the dice results are multipied by 2, hence vehicles cover twice as much distance in a turn.
## Contracts

Whole game is dependent on 3 contracts `RhascauRanks.sol`, `RhascauManager.sol`, and `Rhascau.sol`. The last contract, `PaymentChannel.sol` is used only while playing via front-end client.

**Short system overview** 

`Rhascau.sol` implements and handles the earlier mentioned rules and restrictions, as well as stakes, that players can agree on, before joining the game room. Each user can get a ranking badge (soulbound NFT) and upgrade it accordingly, which is handled by `Ranks.sol`. `RhascauManager.sol` manages the ranking system, as well as payment channels.

Infrastructure is designed is such a way, in order to maintain user ranking progress in case of need for changing the main game contract, `Rhascau.sol`.

### Ranking System

Each of the players can mint an upgradable ranking badge in a form of a soulbound NFT. Upgrades are available after collecting certain amount of ranking points, which are assigned during the game, according to the following table. 

| Activity                 	| Points 	|
|--------------------------	|--------	|
| Participation in a game  	| 50     	|
| Winning a game           	| 150    	|
| Destroying enemy vehicle 	| 20     	|
| First win of the day     	| 150    	|
| First game of the day    	| 50     	|
| each 1 ETH won           	| 4000   	|


Treshholds for consecutive ranks are as follows:

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

Very simple contract, serving as an intermadiary between user's personal wallet and a burner wallet. In order to create such a channel user must have a valid signature, which is generated based on both address of user wallet and address of burner created for him.

User can top up a payment channel with certain minimum amount of funds, while burner wallet (which we then use for better user expierience while playing) treats the channel as a faucet.

In case of loosing access to the burner wallet, each user can destroy the channel, collecting all the funds there were left at the same time.

### Manager

Contract responsible for managing the ranking system, as well as payment channels creation. (Pretty self explanatory, see: `RhascauManager.sol`).

### Rhascau
## Randomness
