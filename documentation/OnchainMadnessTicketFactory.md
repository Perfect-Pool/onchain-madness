# OnchainMadnessTicketFactory

Factory contract for creating and managing OnchainMadnessTicket pools. Uses the Clones pattern to deploy minimal proxy contracts for each pool, providing efficient pool management and ticket operations.

## Events

- **TicketPoolCreated**: Emitted when a new ticket pool is created
    - `poolId`: `uint256` - ID of the created pool
    - `poolAddress`: `address` - Address of the created pool

- **ContinueIteration**: Emitted when a new iteration starts for a year
    - `year`: `uint256` - Tournament year being iterated

- **IterationFinished**: Emitted when an iteration is completed for a year
    - `year`: `uint256` - Tournament year that finished iteration

- **PrizeClaimed**: Emitted when a prize is claimed for a token
    - `_tokenId`: `uint256` - ID of the token claiming prize
    - `_poolId`: `uint256` - ID of the pool

- **BetPlaced**: Emitted when a bet is placed
    - `_player`: `address` - Address of the player placing the bet
    - `_gameYear`: `uint256` - Year of the tournament
    - `_tokenId`: `uint256` - ID of the minted token

- **GamePotIncreased**: Emitted when the game pot is increased
    - `_gameYear`: `uint256` - Year of the tournament
    - `_amount`: `uint256` - Amount added to the pot

## State Variables

- **pools**: `mapping(uint256 => address) public` - Mapping of pool IDs to pool addresses
- **yearToPoolIdIteration**: `mapping(uint256 => uint256) public` - Mapping of years to their corresponding pool ID iterations
- **onchainMadnessContracts**: `mapping(address => bool) public` - Mapping to track valid OnchainMadness contract addresses
- **implementation**: `address public immutable` - Address of the implementation contract for cloning

## Functions

### Constructor

- Description: Initializes the factory with the implementation contract address
- Arguments:
    - `_implementation`: `address` - Address of the implementation contract
- Modifiers:
    - `Ownable`: Initializes ownership

### createPool

- Description: Creates a new OnchainMadnessTicket pool using the clone pattern
- Arguments:
    - `_gameDeployer`: `address` - Address of the game deployer contract
    - `_isProtocolPool`: `bool` - Whether this is a protocol pool
    - `_isPrivatePool`: `bool` - Whether this is a private pool
    - `_pin`: `string` - Pin for private pools
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
    - `_player`: `address` - Address to mint the NFT to
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
    - `_tokenId`: `uint256` - Token ID representing the bracket
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


### verifyShares

- Description: Verifies the shares for a player
- Arguments:
    - `_poolId`: `uint256` - ID of the pool
    - `_player`: `address` - Address of the player
- Returns: `uint256` - Amount of PP tokens available for the player

### pause

- Description: Pauses the contract
- Modifiers:
    - `onlyOwner`: Restricted to contract owner

### unpause

- Description: Unpauses the contract
- Modifiers:
    - `onlyOwner`: Restricted to contract owner
