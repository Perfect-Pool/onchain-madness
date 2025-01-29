# OnchainMadnessEntryFactory

Factory contract for creating and managing OnchainMadnessTicket pools. Uses the Clones pattern to deploy minimal proxy contracts for each pool, providing efficient pool management and ticket operations.

## Events

- **EntryPoolCreated**: Emitted when a new entry pool is created
    - `poolId`: `uint256` - ID of the created pool
    - `poolAddress`: `address` - Address of the created pool
    - `poolName`: `string` - Address of the created pool
- **ContinueIteration**: Emitted when a new iteration starts for a year
    - `year`: `uint256` - Tournament year being iterated
- **IterationFinished**: Emitted when an iteration is completed for a year
    - `year`: `uint256` - Tournament year that finished iteration
- **ContinueBurnIteration**: Emitted when a burn iteration needs to be continued
    - `year`: `uint256` - Tournament year being iterated
- **BurnIterationFinished**: Emitted when a burn iteration is completed for a year
    - `year`: `uint256` - Tournament year that finished burn iteration
- **ContinueDismissIteration**: Emitted when a dismiss iteration needs to be continued
    - `year`: `uint256` - Tournament year being iterated
- **DismissIterationFinished**: Emitted when a dismiss iteration is completed for a year
    - `year`: `uint256` - Tournament year that finished dismiss iteration
- **PrizeClaimed**: Emitted when a prize is claimed for a token
    - `_tokenId`: `uint256` - ID of the token claiming prize
    - `_poolId`: `uint256` - ID of the pool
- **BetPlaced**: Emitted when a bet is placed
    - `gameYear`: `uint256` - Year of the tournament
    - `poolId`: `uint256` - ID of the pool
    - `tokenId`: `uint256` - ID of the minted token
    - `player`: `address` - Address of the player placing the bet
- **GamePotIncreased**: Emitted when the game pot is increased
    - `_gameYear`: `uint256` - Year of the tournament
    - `_amount`: `uint256` - Amount added to the pot
- **GameDeployerChanged**: Emitted when the game deployer is changed
    - `_gameDeployer`: `address` - New game deployer address

## Constants

- **PPS_BURN_DELAY**: `uint256 public` - Time after tournament to start burning PPS tokens (30 days)

## State Variables

- **pools**: `mapping(uint256 => address) public` - Mapping of pool IDs to pool addresses
- **yearToPoolIdIteration**: `mapping(uint256 => uint256) public` - Mapping of years to their corresponding pool ID iterations
- **yearToPoolIdBurnIteration**: `mapping(uint256 => uint256) public` - Mapping of years to their corresponding pool ID burn iterations
- **yearToPoolIdDismissIteration**: `mapping(uint256 => uint256) public` - Mapping of years to their corresponding pool ID dismiss iterations
- **onchainMadnessContracts**: `mapping(address => bool) public` - Mapping to track valid OnchainMadness contract addresses
- **poolNames**: `mapping(bytes32 => bool) public` - Mapping to block duplication of pool names
- **yearToPPSBurned**: `mapping(uint256 => bool) public` - Mapping to check if the PPS tokens have already been burned for a year
- **yearToPPSBurnDate**: `mapping(uint256 => uint256) public` - Mapping to check the date to burn PPS tokens
- **yearToPrizeDismissed**: `mapping(uint256 => bool) public` - Mapping to check if the prizes have already been dismissed for a year
- **implementation**: `address public immutable` - Address of the implementation contract for cloning
- **gameDeployer**: `IOnchainMadnessFactory public` - Reference to the game factory contract
- **USDC**: `IERC20 public` - Reference to the USDC token contract

## Functions

### Constructor

- Description: Initializes the factory with the implementation contract address
- Arguments:
    - `_implementation`: `address` - Address of the implementation contract
    - `_gameDeployer`: `address` - Address of the game deployer contract
- Modifiers:
    - `Ownable`: Initializes ownership

### createPool

- Description: Creates a new OnchainMadnessEntry pool using the clone pattern
- Arguments:
    - `_isProtocolPool`: `bool` - Whether this is a protocol pool
    - `_isPrivatePool`: `bool` - Whether this is a private pool
    - `_pin`: `string` - Pin for private pools
    - `_poolName`: `string` - The name of the pool (15 chars maximum)
- Returns: `uint256` - The ID of the newly created pool
- Modifiers:
    - `whenNotPaused`: Only when contract is not paused
    - `nonReentrant`: Prevents reentrancy

### claimPPShare

- Description: Claims the PP share tokens for a player
- Arguments:
    - `_poolId`: `uint256` - ID of the pool
    - `_player`: `address` - Address of the player claiming their share
- Modifiers:
    - `whenNotPaused`: Only when contract is not paused
    - `nonReentrant`: Prevents reentrancy

### safeMint

- Description: Mints a new NFT representing a bracket prediction
- Arguments:
    - `_poolId`: `uint256` - ID of the pool
    - `_gameYear`: `uint256` - Tournament year
    - `bets`: `uint8[63]` - Array of 63 predictions for the tournament
    - `_pin`: `string` - PIN for private pools
- Returns: `uint256` - The ID of the newly minted token
- Modifiers:
    - `whenNotPaused`: Only when contract is not paused
    - `nonReentrant`: Prevents reentrancy

### iterateYearTokens

- Description: Iterates through NFTs across all pools for a given year
- Arguments:
    - `_year`: `uint256` - The year to iterate
- Returns:
    - `success`: `bool` - Whether there are more tokens to process
    - `score`: `uint8` - Score achieved by the current token
- Modifiers:
    - `whenNotPaused`: Only when contract is not paused
    - `nonReentrant`: Prevents reentrancy

### claimPrize

- Description: Claims prize for a winning bracket
- Arguments:
    - `_poolId`: `uint256` - ID of the pool
    - `_player`: `address` - Address to receive the prize
    - `_tokenId`: `uint256` - Token ID of the NFT that will be claimed
- Modifiers:
    - `whenNotPaused`: Only when contract is not paused
    - `nonReentrant`: Prevents reentrancy

### claimAll

- Description: Claims prize for a winning bracket
- Arguments:
    - `_poolId`: `uint256` - ID of the pool
    - `_player`: `address` - Address to receive the prize
    - `_tokenIds` `uint256[]` - Token IDs of the NFTs that will be claimed
- Modifiers:
    - `whenNotPaused`: Only when contract is not paused
    - `nonReentrant`: Prevents reentrancy

### increaseGamePot

- Description: Increases the prize pool for a specific game
- Arguments:
    - `_poolId`: `uint256` - ID of the pool
    - `_gameYear`: `uint256` - Tournament year
    - `_amount`: `uint256` - Amount to increase the pot by
- Modifiers:
    - `whenNotPaused`: Only when contract is not paused
    - `nonReentrant`: Prevents reentrancy

### tokenURI

- Description: Returns the token URI for a given NFT
- Arguments:
    - `_poolId`: `uint256` - ID of the pool
    - `_tokenId`: `uint256` - ID of the NFT
- Returns: `string` - The token URI

### getPoolAddress

- Description: Returns the pool address for a given pool ID
- Arguments:
    - `_poolId`: `uint256` - ID of the pool
- Returns: `address` - The pool address

### getTotalPools

- Description: Returns the total number of pools created
- Returns: `uint256` - The total number of pools

### getBetData

- Description: Returns the bet data for a given NFT
- Arguments:
    - `_poolId`: `uint256` - ID of the pool
    - `_tokenId`: `uint256` - ID of the NFT
- Returns: `uint8[63]` - Array of bet predictions

### getGameYear

- Description: Returns the game year for a given NFT
- Arguments:
    - `_poolId`: `uint256` - ID of the pool
    - `_tokenId`: `uint256` - ID of the NFT
- Returns: `uint256` - The game year

### betValidator

- Description: Validates a bracket prediction and returns its score
- Arguments:
    - `_poolId`: `uint256` - ID of the pool
    - `_tokenId`: `uint256` - Token ID of the bracket to validate
- Returns:
    - `validator`: `uint8[63]` - Array indicating correct/incorrect predictions
    - `points`: `uint8` - Total score achieved

### getTeamSymbols

- Description: Returns the team symbols for a given NFT
- Arguments:
    - `_poolId`: `uint256` - ID of the pool
    - `_tokenId`: `uint256` - ID of the NFT
- Returns: `string[63]` - Array of team symbols

### amountPrizeClaimed

- Description: Returns the amount of prize claimed for a bracket
- Arguments:
    - `_poolId`: `uint256` - ID of the pool
    - `_tokenId`: `uint256` - Token ID of the bracket
- Returns:
    - `amountToClaim`: `uint256` - Amount of USDC that can be claimed
    - `amountClaimed`: `uint256` - Amount of USDC already claimed

### potentialPayout

- Description: Returns the potential payout for a game year
- Arguments:
    - `_poolId`: `uint256` - ID of the pool
    - `gameYear`: `uint256` - Tournament year to check
- Returns: `uint256` - Maximum potential payout in USDC

### playerQuantity

- Description: Returns the number of players for a game year
- Arguments:
    - `_poolId`: `uint256` - ID of the pool
    - `gameYear`: `uint256` - Tournament year to check
- Returns: `uint256` - Number of players participating

### getPoolId

- Description: Returns the pool ID for a given pool address
- Arguments:
    - `_poolAddress`: `address` - The pool address
- Returns: `uint256` - The pool ID

### getPoolData

- Description: Returns the created pool data
- Arguments:
    - `_poolId`: `uint256` - ID of the pool
- Returns:
    - `name`: `string` - The name of the pool
    - `poolAddress`: `adddress` - The pool contract address
    - `isPrivate`: `bool` - Whether the pool is private
    - `isProtocol`: `bool` - Whether the pool is created by the protocol
    - `pin`: `bytes` - The PIN required to join the pool
    - `creator`: `address` - The address of the creator of the pool

### verifyShares

- Description: Verifies the shares for a player
- Arguments:
    - `_poolId`: `uint256` - ID of the pool
    - `_player`: `address` - Address of the player
- Returns: `uint256` - Amount of PP tokens available for the player


### iterateBurnYearTokens

- Description: Iterates through the pools to burn PPS tokens for a given year
- Arguments:
    - `_gameYear`: `uint256` - The year to iterate
- Modifiers:
    - `whenNotPaused`: Only when contract is not paused
    - `nonReentrant`: Prevents reentrancy

### iterateDismissYear

- Description: Iterates through the pools to dismiss prizes for a given year
- Arguments:
    - `_gameYear`: `uint256` - The year to iterate
- Modifiers:
    - `whenNotPaused`: Only when contract is not paused
    - `nonReentrant`: Prevents reentrancy

### needsToBeBurned

- Description: Checks if the tokens need to be burned
- Arguments:
    - `_gameYear`: `uint256` - The year to check
- Returns: `bool` - True if the tokens need to be burned, false otherwise

### needsToBeDismissed

- Description: Checks if the prize can be dismissed
- Arguments:
    - `_gameYear`: `uint256` - The year to check
- Returns: `bool` - True if the prize can be dismissed, false otherwise

### getPoolAddress

- Description: Gets the pool address for a given pool ID
- Arguments:
    - `_poolId`: `uint256` - ID of the pool to query
- Returns: `address` - Address of the pool

### getPoolId

- Description: Gets the pool ID for a given pool address
- Arguments:
    - `_poolAddress`: `address` - Address of the pool to query
- Returns: `uint256` - ID of the pool

### pause

- Description: Pauses the contract
- Modifiers:
    - `onlyOwner`: Restricted to contract owner

### unpause

- Description: Unpauses the contract
- Modifiers:
    - `onlyOwner`: Restricted to contract owner