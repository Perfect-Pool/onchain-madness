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

- **PerfectPrizeAwarded**: Emitted when a perfect prize is awarded to winners
    - `winners`: `address[]` - Array of winner addresses
    - `amount`: `uint256` - Amount of USDC awarded

- **WinnersQtyIncreased**: Emitted when the number of winners for a year increases
    - `year`: `uint256` - Tournament year
    - `qty`: `uint256` - New total number of winners

- **aUSDCDeposited**: Emitted when USDC is transferred to aUSDC
    - `token`: `address` - Address of the token being deposited
    - `amount`: `uint256` - Amount being deposited

- **aUSDCWithdrawn**: Emitted when USDC is transferred from aUSDC
    - `token`: `address` - Address of the token being withdrawn
    - `to`: `address` - Address receiving the withdrawn tokens
    - `amount`: `uint256` - Amount being withdrawn

## Constants

- **INITIAL_TOKEN_PER_USDC**: `uint256 public` - The initial value of the tokens per USDC (20)

## State Variables

- **USDC**: `IERC20 public immutable` - The USDC token contract used for deposits and withdrawals
- **aUSDC**: `IERC20 public immutable` - The aUSDC token contract for AAVE integration
- **lendingPool**: `ILendingPool public immutable` - The AAVE lending pool contract
- **lockPermit**: `bool public` - Controls whether minting requires authorization
- **lockWithdrawal**: `bool public` - Controls whether token withdrawals are allowed
- **lockMint**: `bool public` - Controls whether token minting is temporarily paused
- **definitiveLockMint**: `bool public` - When true, permanently disables all token minting
- **aUSDCDeposit**: `bool public` - When true, USDC is deposited into aUSDC
- **withdrawalMonth**: `uint256 public` - The month to block withdrawal
- **withdrawalDay**: `uint256 public` - The day to block withdrawal
- **winnerPools**: `address[] public` - Addresses of winner pools
- **gameFactory**: `IGamesFactory public` - The Game Factory contract
- **authorizedMinters**: `mapping(address => bool) public` - Addresses authorized to mint tokens when lockPermit is true
- **onchainMadnessContracts**: `mapping(address => bool) public` - Addresses of authorized Onchain Madness game contracts
- **yearToPrize**: `mapping(uint256 => uint256) public` - Total prize amount per tournament year

## Modifiers

- `onlyGameContract`: Ensures the caller is an authorized game contract or the owner

## Functions

### Constructor

- Description: Initializes the PerfectPool token with USDC integration
- Arguments:
    - `_usdc`: `address` - Address of the USDC token contract
    - `_aUSDC`: `address` - Address of the aUSDC token contract
    - `_lendingPool`: `address` - Address of the Lending Pool contract
    - `name`: `string` - Name of the ERC20 token
    - `symbol`: `string` - Symbol of the ERC20 token
    - `_gameContract`: `address` - Address of the Onchain Madness game contract
    - `_gameFactory`: `address` - Address of the Game Factory contract

### dollarBalance

- Description: Shows the USDC added to aUSDC balance
- Returns: `uint256` - The balance of the USDC/aUSDC token contract

### depositToAave

- Description: Deposits tokens from the contract's balance into AAVE lending pool
- Modifiers:
    - `nonReentrant`: Prevents reentrancy
    - `onlyOwner`: Restricted to contract owner

### withdrawAllFromAave

- Description: Withdraws all aUSDC tokens from AAVE lending pool to this contract
- Modifiers:
    - `nonReentrant`: Prevents reentrancy
    - `onlyOwner`: Restricted to contract owner

### increasePool

- Description: Increases the pool by depositing USDC and minting tokens at a 20:1 ratio
- Arguments:
    - `amountUSDC`: `uint256` - Amount of USDC to deposit
    - `percentage`: `uint8[]` - Array of percentage allocations for token distribution (must sum to 100)
    - `receivers`: `address[]` - Array of addresses to receive tokens based on percentages
- Modifiers:
    - `nonReentrant`: Prevents reentrancy

### withdraw

- Description: Allows token holders to withdraw USDC by burning tokens
- Arguments:
    - `amount`: `uint256` - Number of tokens to burn for USDC withdrawal
- Modifiers:
    - `nonReentrant`: Prevents reentrancy

### burnTokens

- Description: Allows voluntary burning of tokens to increase token value
- Arguments:
    - `amount`: `uint256` - Number of tokens to burn
- Modifiers:
    - `nonReentrant`: Prevents reentrancy

### increaseWinnersQty

- Description: Increases the winner count for a specific tournament year
- Arguments:
    - `year`: `uint256` - The tournament year to increase winners for
    - `gameContract`: `address` - The game contract to increase winners for
- Modifiers:
    - `nonReentrant`: Prevents reentrancy

### resetData

- Description: Resets tournament data for a new season
- Arguments:
    - `year`: `uint256` - The tournament year to reset
- Modifiers:
    - `nonReentrant`: Prevents reentrancy

### perfectPrize

- Description: Awards the perfect prize to tournament winners
- Arguments:
    - `year`: `uint256` - The tournament year for prize distribution
- Modifiers:
    - `nonReentrant`: Prevents reentrancy

### setLockPermit

- Description: Controls minting permission requirements
- Arguments:
    - `_lockPermit`: `bool` - True to require authorization, false to allow anyone
- Modifiers:
    - `onlyOwner`: Restricted to contract owner

### setLockWithdrawal

- Description: Controls token withdrawal capability
- Arguments:
    - `_lockWithdrawal`: `bool` - True to disable withdrawals, false to enable
- Modifiers:
    - `onlyGameContract`: Restricted to game contracts

### setLockMint

- Description: Controls temporary minting capability
- Arguments:
    - `_lockMint`: `bool` - True to pause minting, false to resume
- Modifiers:
    - `onlyOwner`: Restricted to contract owner

### setDefinitiveLockMint

- Description: Permanently disables token minting
- Modifiers:
    - `onlyOwner`: Restricted to contract owner

### setAuthorizedMinter

- Description: Manages addresses authorized to mint tokens
- Arguments:
    - `minter`: `address` - Address to modify permissions for
    - `authorized`: `bool` - True to grant minting permission, false to revoke
- Modifiers:
    - `onlyGameContract`: Restricted to game contracts

### setOnchainMadnessContract

- Description: Manages authorized Onchain Madness contracts
- Arguments:
    - `contractAddress`: `address` - Address of the Onchain Madness contract
    - `authorized`: `bool` - True to authorize the contract, false to revoke

### getTokenValue

- Description: Retrieves the current token value in USDC
- Returns: `uint256` - The current token value in USDC

### isAbleToWithdraw

- Description: Returns if the user can burn tokens for USDC
- Returns: `bool` - True if the game of the current year is finished or within withdrawal period

### setWithdrawalDate

- Description: Set date to block withdrawal
- Arguments:
    - `month`: `uint256` - Month to block withdrawal
    - `day`: `uint256` - Day to block withdrawal
- Modifiers:
    - `onlyOwner`: Restricted to contract owner
