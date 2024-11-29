# PerfectPool

An ERC20 token contract that allows USDC deposits, token minting, burning, and withdrawal mechanisms with advanced permission controls. Designed to support Onchain Madness prize distribution and token value management.

## Events

- **PoolIncreased**: Emitted when new USDC is deposited and tokens are minted
    - `amountUSDC`: `uint256` - Amount of USDC deposited
    - `tokensMinted`: `uint256` - Amount of tokens minted

- **TokensBurned**: Emitted when tokens are voluntarily burned
    - `burner`: `address` - Address of the account burning tokens
    - `amount`: `uint256` - Amount of tokens burned

- **USDCWithdrawn**: Emitted when USDC is withdrawn by burning tokens
    - `user`: `address` - Address of the withdrawing account
    - `amount`: `uint256` - Amount of USDC withdrawn

- **PerfectPrizeAwarded**: Emitted when a perfect prize is awarded to a winner
    - `winner`: `address` - Address of the prize winner
    - `amount`: `uint256` - Amount of USDC awarded

- **WinnersQtyIncreased**: Emitted when the number of winners for a year increases
    - `year`: `uint256` - Tournament year
    - `qty`: `uint256` - New total number of winners

## State Variables

- **USDC**: `IERC20 public immutable` - The USDC token contract used for deposits and withdrawals
- **lockPermit**: `bool public` - Controls whether minting requires authorization
- **lockWithdrawal**: `bool public` - Controls whether token withdrawals are allowed
- **lockMint**: `bool public` - Controls whether token minting is temporarily paused
- **definitiveLockMint**: `bool public` - When true, permanently disables all token minting
- **totalUSDCDeposited**: `uint256 public` - Total amount of USDC deposited into the contract
- **withdrawalBlockedTimestamp**: `uint256 public` - Timestamp until which withdrawals are blocked (except for winners)
- **authorizedMinters**: `mapping(address => bool) public` - Addresses authorized to mint tokens when lockPermit is true
- **onchainMadnessContracts**: `mapping(address => bool) public` - Addresses of authorized Onchain Madness game contracts
- **yearToWinnersQty**: `mapping(uint256 => uint256) public` - Number of winners per tournament year
- **yearToPrize**: `mapping(uint256 => uint256) public` - Total prize amount per tournament year

## Functions

### Constructor

- Description: Initializes the PerfectPool token with USDC integration
- Arguments:
    - `_usdc`: `address` - Address of the USDC token contract
    - `name`: `string` - Name of the ERC20 token
    - `symbol`: `string` - Symbol of the ERC20 token

### increasePool

- Description: Increases the pool by depositing USDC and minting tokens at a 2:1 ratio
- Arguments:
    - `amountUSDC`: `uint256` - Amount of USDC to deposit
    - `percentage`: `uint8[]` - Array of percentage allocations for token distribution (must sum to 100)
    - `receivers`: `address[]` - Array of addresses to receive tokens based on percentages
- Modifiers:
    - `nonReentrant`: Prevents reentrancy attacks

### withdraw

- Description: Allows token holders to withdraw USDC by burning tokens
- Arguments:
    - `amount`: `uint256` - Number of tokens to burn for USDC withdrawal
- Modifiers:
    - `nonReentrant`: Prevents reentrancy attacks

### burnTokens

- Description: Allows voluntary burning of tokens to increase token value
- Arguments:
    - `amount`: `uint256` - Number of tokens to burn
- Modifiers:
    - `nonReentrant`: Prevents reentrancy attacks

### increaseWinnersQty

- Description: Increases the winner count for a specific tournament year
- Arguments:
    - `year`: `uint256` - The tournament year to increase winners for
- Modifiers:
    - `nonReentrant`: Prevents reentrancy attacks

### resetData

- Description: Resets tournament data for a new season
- Arguments:
    - `year`: `uint256` - The tournament year to reset
- Modifiers:
    - `nonReentrant`: Prevents reentrancy attacks

### perfectPrize

- Description: Awards the perfect prize to tournament winners
- Arguments:
    - `year`: `uint256` - The tournament year for prize distribution
    - `gameContract`: `address` - The Onchain Madness contract to receive the prize
- Modifiers:
    - `nonReentrant`: Prevents reentrancy attacks

### setAuthorizedMinter

- Description: Manages addresses authorized to mint tokens
- Arguments:
    - `minter`: `address` - Address to modify permissions for
    - `authorized`: `bool` - True to grant minting permission, false to revoke
- Modifiers:
    - `onlyOwner`: Restricted to contract owner

### setOnchainMadnessContract

- Description: Manages authorized Onchain Madness game contracts
- Arguments:
    - `gameContract`: `address` - Address of the game contract
    - `authorized`: `bool` - True to authorize, false to revoke
- Modifiers:
    - `onlyOwner`: Restricted to contract owner

### setLockPermit

- Description: Sets whether minting requires authorization
- Arguments:
    - `_lockPermit`: `bool` - New lock permit state
- Modifiers:
    - `onlyOwner`: Restricted to contract owner

### setLockWithdrawal

- Description: Sets whether token withdrawals are allowed
- Arguments:
    - `_lockWithdrawal`: `bool` - New lock withdrawal state
- Modifiers:
    - `onlyOwner`: Restricted to contract owner

### setLockMint

- Description: Sets whether token minting is temporarily paused
- Arguments:
    - `_lockMint`: `bool` - New lock mint state
- Modifiers:
    - `onlyOwner`: Restricted to contract owner

### setDefinitiveLockMint

- Description: Permanently disables all token minting
- Arguments:
    - `_definitiveLockMint`: `bool` - Must be true to lock minting permanently
- Modifiers:
    - `onlyOwner`: Restricted to contract owner

### setWithdrawalBlockedTimestamp

- Description: Sets the timestamp until which withdrawals are blocked
- Arguments:
    - `_withdrawalBlockedTimestamp`: `uint256` - New withdrawal blocked timestamp
- Modifiers:
    - `onlyOwner`: Restricted to contract owner
