// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title PerfectPool
 * @author PerfectPool Team
 * @notice An ERC20 token contract that allows USDC deposits, token minting,
 * burning, and withdrawal mechanisms with advanced permission controls.
 * Designed to support Onchain Madness prize distribution and token value management.
 * @dev Implements ERC20, Ownable, and ReentrancyGuard for enhanced security
 * Features:
 * - USDC deposits and withdrawals
 * - Token minting with configurable distribution
 * - Prize pool management for tournament winners
 * - Controlled access for minting and game contracts
 * - Security features including withdrawal locks and permanent mint locks
 */
contract PerfectPool is ERC20, Ownable, ReentrancyGuard {
    /** STATE VARIABLES **/
    /// @dev The USDC token contract used for deposits and withdrawals
    IERC20 public immutable USDC;

    /// @dev Controls whether minting requires authorization
    bool public lockPermit;
    /// @dev Controls whether token withdrawals are allowed
    bool public lockWithdrawal;
    /// @dev Controls whether token minting is temporarily paused
    bool public lockMint;
    /// @dev When true, permanently disables all token minting
    bool public definitiveLockMint;
    /// @dev Timestamp until which withdrawals are blocked (except for winners)
    uint256 public withdrawalBlockedTimestamp;
    
    /// @dev Addresses authorized to mint tokens when lockPermit is true
    mapping(address => bool) public authorizedMinters;
    /// @dev Addresses of authorized Onchain Madness game contracts
    mapping(address => bool) public onchainMadnessContracts;
    /// @dev Number of winners per tournament year
    mapping(uint256 => uint256) public yearToWinnersQty;
    /// @dev Total prize amount per tournament year
    mapping(uint256 => uint256) public yearToPrize;

    /** EVENTS **/
    /// @dev Emitted when new USDC is deposited and tokens are minted
    event PoolIncreased(uint256 amountUSDC, uint256 tokensMinted);
    /// @dev Emitted when tokens are voluntarily burned
    event TokensBurned(address indexed burner, uint256 amount);
    /// @dev Emitted when USDC is withdrawn by burning tokens
    event USDCWithdrawn(address indexed user, uint256 amount);
    /// @dev Emitted when a perfect prize is awarded to a winner
    event PerfectPrizeAwarded(address winner, uint256 amount);
    /// @dev Emitted when the number of winners for a year increases
    event WinnersQtyIncreased(uint256 year, uint256 qty);

    /**
     * @dev Initializes the PerfectPool token with USDC integration
     * @param _usdc Address of the USDC token contract
     * @param name Name of the ERC20 token
     * @param symbol Symbol of the ERC20 token
     * @param _gameContract Address of the Onchain Madness game contract
     */
    constructor(
        address _usdc,
        string memory name,
        string memory symbol,
        address _gameContract
    ) ERC20(name, symbol) Ownable(msg.sender) {
        require(_usdc != address(0), "Invalid USDC address");
        USDC = IERC20(_usdc);
        onchainMadnessContracts[_gameContract] = true;
    }

    /**
     * @notice Increases the pool by depositing USDC and minting tokens
     * @dev Mints tokens at a 2:1 ratio with the deposited USDC amount
     * All minted tokens are distributed among receivers according to percentages
     * @param amountUSDC Amount of USDC to deposit
     * @param percentage Array of percentage allocations for token distribution (must sum to 100)
     * @param receivers Array of addresses to receive tokens based on percentages
     */
    function increasePool(
        uint256 amountUSDC,
        uint8[] calldata percentage,
        address[] calldata receivers
    ) external nonReentrant {
        require(!lockMint && !definitiveLockMint, "Minting is locked");
        require(!lockPermit || authorizedMinters[msg.sender], "Not authorized");
        require(
            percentage.length > 0 && receivers.length > 0,
            "Arrays cannot be empty"
        );
        require(
            percentage.length == receivers.length,
            "Arrays length mismatch"
        );
        require(amountUSDC > 0, "Amount must be greater than 0");

        uint16 totalPercentage;
        for (uint256 i = 0; i < percentage.length; i++) {
            totalPercentage += percentage[i];
        }
        require(totalPercentage == 100, "Percentage must sum to 100");

        require(
            USDC.transferFrom(msg.sender, address(this), amountUSDC),
            "USDC transfer failed"
        );

        //USDC has 6 decimals and tokens have 18 decimals. Converting USDC to tokens
        uint256 tokensToMint = amountUSDC * 2 * 10**12;

        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 receiverAmount = (tokensToMint * percentage[i]) / 100;
            _mint(receivers[i], receiverAmount);
        }

        emit PoolIncreased(amountUSDC, tokensToMint);
    }

    /**
     * @notice Allows token holders to withdraw USDC by burning tokens
     * @dev The withdrawal amount is proportional to the total USDC deposited and token supply
     * Withdrawals can be locked or restricted to winners during specific periods
     * @param amount Number of tokens to burn for USDC withdrawal
     */
    function withdraw(uint256 amount) external nonReentrant {
        require(!lockWithdrawal, "Withdrawals are locked");
        require(withdrawalBlockedTimestamp < block.timestamp, "Only the game winner can withdraw for now.");
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        uint256 usdcAmount = (amount * USDC.balanceOf(address(this))) / totalSupply();

        _burn(msg.sender, amount);
        require(USDC.transfer(msg.sender, usdcAmount), "USDC transfer failed");

        emit USDCWithdrawn(msg.sender, usdcAmount);
    }

    /**
     * @notice Allows voluntary burning of tokens to increase token value
     * @dev Burns tokens without USDC withdrawal, effectively increasing value for remaining holders
     * @param amount Number of tokens to burn
     */
    function burnTokens(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    /**
     * @notice Increases the winner count for a specific tournament year
     * @dev Only callable by authorized Onchain Madness contracts
     * Used to track prize distribution for perfect bracket winners
     * @param year The tournament year to increase winners for
     */
    function increaseWinnersQty(uint256 year) external nonReentrant {
        require(onchainMadnessContracts[msg.sender], "Not authorized");
        yearToWinnersQty[year]++;

        emit WinnersQtyIncreased(year, yearToWinnersQty[year]);
    }

    /**
     * @notice Resets tournament data for a new season
     * @dev Only callable by authorized Onchain Madness contracts when not time-locked
     * Clears winner count and prize amount for the specified year
     * @param year The tournament year to reset
     */
    function resetData(uint256 year) external nonReentrant {
        require(onchainMadnessContracts[msg.sender], "Not authorized");
        require(withdrawalBlockedTimestamp < block.timestamp, "Not all game winners have withdrawn.");

        yearToWinnersQty[year] = 0;
        yearToPrize[year] = 0;
    }

    /**
     * @notice Awards the perfect prize to tournament winners
     * @dev Distributes USDC equally among all winners for a specific year
     * Prize amount is either the total USDC balance when first claimed
     * or the remaining balance if insufficient funds
     * @param year The tournament year for prize distribution
     * @param _gameContract The Onchain Madness contract to receive the prize
     */
    function perfectPrize(uint256 year, address _gameContract) external nonReentrant {
        require(onchainMadnessContracts[msg.sender], "Not authorized");
        require(yearToWinnersQty[year] > 0, "No winners");

        // if the prize has not been claimed yet
        if(yearToPrize[year] == 0) {
            yearToPrize[year] = USDC.balanceOf(address(this));
        }

        uint256 prizeAmount = yearToPrize[year] / yearToWinnersQty[year];

        // if there is not enough USDC in the contract
        if(USDC.balanceOf(address(this)) < prizeAmount) {
            prizeAmount = USDC.balanceOf(address(this));
        }
        
        require(USDC.transfer(_gameContract, prizeAmount), "USDC transfer failed");

        emit PerfectPrizeAwarded(_gameContract, prizeAmount);
    }

    /**
     * @notice Controls minting permission requirements
     * @dev When locked, only authorized addresses can mint tokens
     * @param _lockPermit True to require authorization, false to allow anyone
     */
    function setLockPermit(bool _lockPermit) external onlyOwner {
        lockPermit = _lockPermit;
    }

    /**
     * @notice Controls token withdrawal capability
     * @dev Allows owner to enable/disable USDC withdrawals
     * @param _lockWithdrawal True to disable withdrawals, false to enable
     */
    function setLockWithdrawal(bool _lockWithdrawal) external onlyOwner {
        lockWithdrawal = _lockWithdrawal;
    }

    /**
     * @notice Controls temporary minting capability
     * @dev Allows owner to pause/resume token minting
     * @param _lockMint True to pause minting, false to resume
     */
    function setLockMint(bool _lockMint) external onlyOwner {
        lockMint = _lockMint;
    }

    /**
     * @notice Permanently disables token minting
     * @dev Once called, this action cannot be reversed
     * Used to cap the total token supply permanently
     */
    function setDefinitiveLockMint() external onlyOwner {
        definitiveLockMint = true;
    }

    /**
     * @notice Manages addresses authorized to mint tokens
     * @dev Only relevant when lockPermit is true
     * @param minter Address to modify permissions for
     * @param authorized True to grant minting permission, false to revoke
     */
    function setAuthorizedMinter(
        address minter,
        bool authorized
    ) external {
        require(
            msg.sender == owner() || onchainMadnessContracts[msg.sender],
            "Not authorized"
        );
        authorizedMinters[minter] = authorized;
    }

    /**
     * @notice Manages authorized Onchain Madness contracts
     * @dev Authorized contracts can call winner-related functions
     * @param contractAddress Address of the Onchain Madness contract
     * @param authorized True to authorize the contract, false to revoke
     */
    function setOnchainMadnessContract(
        address contractAddress,
        bool authorized
    ) external {
        require(
            msg.sender == owner() || onchainMadnessContracts[msg.sender],
            "Not authorized"
        );
        onchainMadnessContracts[contractAddress] = authorized;
    }
}
