// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../libraries/OnchainMadnessLib.sol";

interface IGamesFactory {
    function isFinished(uint256 year) external view returns (bool);
}

interface ILendingPool {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

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
    /// @dev The initial value of the tokens per USDC
    uint256 public constant INITIAL_TOKEN_PER_USDC = 20;
    /// @dev The USDC token contract used for deposits and withdrawals
    IERC20 public immutable USDC;
    IERC20 public immutable aUSDC;
    ILendingPool public immutable lendingPool;

    /// @dev Controls whether minting requires authorization
    bool public lockPermit;
    /// @dev Controls whether token withdrawals are allowed
    bool public lockWithdrawal;
    /// @dev Controls whether token minting is temporarily paused
    bool public lockMint;
    /// @dev When true, permanently disables all token minting
    bool public definitiveLockMint;
    /// @dev When true, USDC is deposited into aUSDC
    bool public aUSDCDeposit;
    /// @dev The month to block withdrawal
    uint256 public withdrawalMonth;
    /// @dev The day to block withdrawal
    uint256 public withdrawalDay;
    /// @dev Addresses of winner pools
    address[] public winnerPools;
    /// @dev The Game Factory contract
    IGamesFactory public gameFactory;

    /// @dev Addresses authorized to mint tokens when lockPermit is true
    mapping(address => bool) public authorizedMinters;
    /// @dev Addresses of authorized Onchain Madness game contracts
    mapping(address => bool) public onchainMadnessContracts;
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
    event PerfectPrizeAwarded(address[] winners, uint256 amount);
    /// @dev Emitted when the number of winners for a year increases
    event WinnersQtyIncreased(uint256 year, uint256 qty);
    /// @dev Emitted when USDC is transferred to aUSDC
    event aUSDCDeposited(address indexed token, uint256 amount);
    /// @dev Emitted when USDC is transferred from aUSDC
    event aUSDCWithdrawn(
        address indexed token,
        address indexed to,
        uint256 amount
    );

    /** MODIFIERS **/
    modifier onlyGameContract() {
        require(
            onchainMadnessContracts[msg.sender] || msg.sender == owner(),
            "Not authorized"
        );
        _;
    }

    /**
     * @dev Initializes the PerfectPool token with USDC integration
     * @param _usdc Address of the USDC token contract
     * @param _aUSDC Address of the aUSDC token contract
     * @param _lendingPool Address of the Lending Pool contract
     * @param name Name of the ERC20 token
     * @param symbol Symbol of the ERC20 token
     * @param _gameContract Address of the Onchain Madness game contract
     * @param _gameFactory Address of the Game Factory contract
     */
    constructor(
        address _usdc,
        address _aUSDC,
        address _lendingPool,
        string memory name,
        string memory symbol,
        address _gameContract,
        address _gameFactory
    ) ERC20(name, symbol) Ownable(msg.sender) {
        require(_usdc != address(0), "Invalid USDC address");
        USDC = IERC20(_usdc);
        onchainMadnessContracts[_gameContract] = true;
        onchainMadnessContracts[_gameFactory] = true;
        gameFactory = IGamesFactory(_gameFactory);

        aUSDC = IERC20(_aUSDC);
        lendingPool = ILendingPool(_lendingPool);
        withdrawalMonth = 2;
        withdrawalDay = 28;
    }

    /**
     * @notice Shows the USDC added to aUSDC balance
     * @return The balance of the USDC/aUSDC token contract
     */
    function dollarBalance() public view returns (uint256) {
        return USDC.balanceOf(address(this)) + aUSDC.balanceOf(address(this));
    }

    /**
     * @notice Deposits tokens from the contract's balance into AAVE lending pool
     * @dev Uses the contract's own token balance for deposit
     */
    function depositToAave() external nonReentrant onlyOwner {
        uint256 amount = USDC.balanceOf(address(this));
        require(amount > 0, "Amount must be greater than 0");

        _depositToAave(amount);
    }

    /**
     * @dev Internal function to handle AAVE deposits
     * @param amount Amount of USDC to deposit into AAVE
     */
    function _depositToAave(uint256 amount) internal {
        USDC.approve(address(lendingPool), amount);
        lendingPool.deposit(address(USDC), amount, address(this), 0);

        aUSDCDeposit = true;

        emit aUSDCDeposited(address(USDC), amount);
    }

    /**
     * @notice Withdraws tokens from AAVE lending pool to this contract
     * @dev Uses the contract's own aUSDC balance for withdrawal
     * @param amount Amount of aUSDC to withdraw
     */
    function _withdrawFromAave(uint256 amount) internal {
        aUSDC.approve(address(lendingPool), amount);
        lendingPool.withdraw(address(aUSDC), amount, address(this));

        emit aUSDCWithdrawn(address(aUSDC), address(this), amount);
    }

    /**
     * @notice Withdraws all aUSDC tokens from AAVE lending pool to this contract
     */
    function withdrawAllFromAave() external nonReentrant onlyOwner {
        uint256 amount = aUSDC.balanceOf(address(this));
        require(amount > 0, "Amount must be greater than 0");

        _withdrawFromAave(amount);
        aUSDCDeposit = false;
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
        uint256 tokensToMint = amountUSDC * INITIAL_TOKEN_PER_USDC * 10 ** 12;

        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 receiverAmount = (tokensToMint * percentage[i]) / 100;
            _mint(receivers[i], receiverAmount);
        }

        if (aUSDCDeposit) {
            _depositToAave(amountUSDC);
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
        require(isAbleToWithdraw(), "Withdrawals are locked for the moment.");
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        uint256 usdcAmount = (amount * dollarBalance()) / totalSupply();

        if (aUSDCDeposit) {
            //check if the is enough USDC to withdraw, if not withdraw the rest from aUSDC
            if (USDC.balanceOf(address(this)) < usdcAmount) {
                _withdrawFromAave(usdcAmount - USDC.balanceOf(address(this)));
            }
        }

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
     * @param gameContract The game contract to increase winners for
     */
    function increaseWinnersQty(
        uint256 year,
        address gameContract
    ) external nonReentrant {
        require(onchainMadnessContracts[msg.sender], "Not authorized");
        winnerPools.push(gameContract);

        emit WinnersQtyIncreased(year, winnerPools.length);
    }

    /**
     * @notice Resets tournament data for a new season
     * @dev Only callable by authorized Onchain Madness contracts when not time-locked
     * Clears winner count and prize amount for the specified year
     * @param year The tournament year to reset
     */
    function resetData(uint256 year) external nonReentrant {
        require(onchainMadnessContracts[msg.sender], "Not authorized");

        winnerPools = new address[](0);
        yearToPrize[year] = 0;
    }

    /**
     * @notice Awards the perfect prize to tournament winners
     * @dev Distributes USDC equally among all winners for a specific year
     * Prize amount is either the total USDC balance when first claimed
     * or the remaining balance if insufficient funds
     * @param year The tournament year for prize distribution
     */
    function perfectPrize(uint256 year) external nonReentrant {
        require(onchainMadnessContracts[msg.sender], "Not authorized");
        if (winnerPools.length == 0) return;

        // if the prize has not been claimed yet
        if (yearToPrize[year] == 0) {
            yearToPrize[year] = dollarBalance();
        }

        uint256 prizeAmount = yearToPrize[year] / winnerPools.length;
        address[] memory gameContracts = winnerPools;

        if (aUSDCDeposit) {
            _withdrawFromAave(aUSDC.balanceOf(address(this)));
        }

        for (uint256 i = 0; i < gameContracts.length; i++) {
            // to avoid overflows
            if (dollarBalance() < prizeAmount) {
                prizeAmount = dollarBalance();
            }

            require(
                USDC.transfer(gameContracts[i], prizeAmount),
                "USDC transfer failed"
            );
        }
        winnerPools = new address[](0);

        emit PerfectPrizeAwarded(gameContracts, yearToPrize[year]);
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
    function setLockWithdrawal(bool _lockWithdrawal) external onlyGameContract {
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
    ) external onlyGameContract {
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
        require(onchainMadnessContracts[msg.sender], "Not authorized");
        onchainMadnessContracts[contractAddress] = authorized;
    }

    /**
     * @notice Retrieves the current token value in USDC
     * @return The current token value in USDC
     */
    function getTokenValue() public view returns (uint256) {
        return dollarBalance() / totalSupply();
    }

    /**
     * @notice Returns if the user can burn tokens for USDC
     * If the game of the current year is finished, any user can burn tokens.
     */
    function isAbleToWithdraw() public view returns (bool) {
        (uint256 year, uint256 month, uint256 day) = OnchainMadnessLib
            .getCurrentDate();
        if (
            (gameFactory.isFinished(year) ||
                (month <= withdrawalMonth && day <= withdrawalDay)) &&
            !lockWithdrawal
        ) return true;
        return false;
    }

    /**
     * @notice Set date to block withdrawal
     * @param month Month to block withdrawal
     * @param day Day to block withdrawal
     */
    function setWithdrawalDate(uint256 month, uint256 day) external onlyOwner {
        withdrawalMonth = month;
        withdrawalDay = day;
    }
}
