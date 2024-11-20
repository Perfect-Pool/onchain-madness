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
 */
contract PerfectPool is ERC20, Ownable, ReentrancyGuard {
    IERC20 public immutable USDC;

    bool public lockPermit;
    bool public lockWithdrawal;
    bool public lockMint;
    bool public definitiveLockMint;

    uint256 public totalUSDCDeposited;
    uint8 public constant PERFECT_RESULT_PERCENTAGE = 100;

    mapping(address => bool) public authorizedMinters;
    mapping(address => bool) public onchainMadnessContracts;

    event PoolIncreased(uint256 amountUSDC, uint256 tokensMinted);
    event TokensBurned(address indexed burner, uint256 amount);
    event USDCWithdrawn(address indexed user, uint256 amount);
    event PerfectPrizeAwarded(address winner, uint256 amount);

    /**
     * @dev Initializes the PerfectPool token with USDC integration
     * @param _usdc Address of the USDC token contract
     * @param name Name of the ERC20 token
     * @param symbol Symbol of the ERC20 token
     */
    constructor(
        address _usdc,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) Ownable(msg.sender) {
        require(_usdc != address(0), "Invalid USDC address");
        USDC = IERC20(_usdc);
    }

    /**
     * @notice Increases the pool by depositing USDC and minting tokens
     * @dev Mints tokens at a 2:1 ratio, with half going to the team and half distributed per percentages
     * @param amountUSDC Amount of USDC to deposit
     * @param percentage Array of percentage allocations for token distribution
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

        uint256 tokensToMint = amountUSDC * 2;
        uint256 halfTokens = tokensToMint / 2;

        _mint(owner(), halfTokens);

        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 receiverAmount = (halfTokens * percentage[i]) / 100;
            _mint(receivers[i], receiverAmount);
        }

        totalUSDCDeposited += amountUSDC;
        emit PoolIncreased(amountUSDC, tokensToMint);
    }

    /**
     * @notice Allows token holders to withdraw USDC by burning tokens
     * @dev Calculates USDC withdrawal amount based on token supply and total USDC deposited
     * @param amount Number of tokens to burn for USDC withdrawal
     */
    function withdraw(uint256 amount) external nonReentrant {
        require(!lockWithdrawal, "Withdrawals are locked");
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        uint256 usdcAmount = (amount * totalUSDCDeposited) / totalSupply();
        require(
            USDC.balanceOf(address(this)) >= usdcAmount,
            "Insufficient USDC in contract"
        );

        _burn(msg.sender, amount);
        require(USDC.transfer(msg.sender, usdcAmount), "USDC transfer failed");

        totalUSDCDeposited -= usdcAmount;
        emit USDCWithdrawn(msg.sender, usdcAmount);
    }

    /**
     * @notice Allows voluntary burning of tokens to increase token value
     * @dev Burns tokens without receiving USDC, effectively increasing value for remaining holders
     * @param amount Number of tokens to burn
     */
    function burnTokens(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    /**
     * @notice Awards the perfect prize to an Onchain Madness winner
     * @dev Transfers a predefined percentage of USDC to the winning address
     * @param winner Address of the Onchain Madness winner receiving the prize
     */
    function perfectPrize(address winner) external nonReentrant {
        require(onchainMadnessContracts[msg.sender], "Not authorized");
        require(winner != address(0), "Invalid winner address");

        uint256 prizeAmount = (USDC.balanceOf(address(this)) *
            PERFECT_RESULT_PERCENTAGE) / 100;
        require(USDC.transfer(winner, prizeAmount), "USDC transfer failed");

        totalUSDCDeposited -= prizeAmount;
        emit PerfectPrizeAwarded(winner, prizeAmount);
    }

    /**
     * @notice Toggles minting permission restrictions
     * @dev Allows owner to enable/disable minting restrictions
     * @param _lockPermit Boolean to set minting permission lock
     */
    function setLockPermit(bool _lockPermit) external onlyOwner {
        lockPermit = _lockPermit;
    }

    /**
     * @notice Toggles withdrawal restrictions
     * @dev Allows owner to enable/disable token withdrawal
     * @param _lockWithdrawal Boolean to set withdrawal lock
     */
    function setLockWithdrawal(bool _lockWithdrawal) external onlyOwner {
        lockWithdrawal = _lockWithdrawal;
    }

    /**
     * @notice Temporarily locks or unlocks token minting
     * @dev Allows owner to pause or resume token minting
     * @param _lockMint Boolean to set temporary minting lock
     */
    function setLockMint(bool _lockMint) external onlyOwner {
        lockMint = _lockMint;
    }

    /**
     * @notice Permanently locks token minting
     * @dev Once called, no more tokens can ever be minted
     */
    function setDefinitiveLockMint() external onlyOwner {
        definitiveLockMint = true;
    }

    /**
     * @notice Adds or removes addresses from authorized minters list
     * @dev Allows owner to manage addresses with minting permissions
     * @param minter Address to authorize or deauthorize
     * @param authorized Boolean indicating minting permission status
     */
    function setAuthorizedMinter(
        address minter,
        bool authorized
    ) external onlyOwner {
        authorizedMinters[minter] = authorized;
    }

    /**
     * @notice Adds or removes Onchain Madness contract addresses
     * @dev Allows owner to manage contracts authorized to trigger perfect prize
     * @param contractAddress Address of the Onchain Madness contract
     * @param authorized Boolean indicating contract authorization status
     */
    function setOnchainMadnessContract(
        address contractAddress,
        bool authorized
    ) external onlyOwner {
        onchainMadnessContracts[contractAddress] = authorized;
    }
}
