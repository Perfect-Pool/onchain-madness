// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title FakeLending
 * @author PerfectPool
 * @notice A mock contract that simulates Aave V3's Pool behavior for testing purposes.
 * When USDC is supplied, it mints aUSDC tokens to the supplier.
 * When withdrawn, it burns aUSDC tokens and returns USDC to the withdrawer.
 */
contract FakeLending {
    IERC20 public immutable USDC;
    AToken public immutable aUSDC;

    /**
     * @dev Constructor that initializes the USDC token address and creates the aUSDC token
     * @param _usdc The address of the USDC token contract
     */
    constructor(address _usdc) {
        USDC = IERC20(_usdc);
        aUSDC = new AToken("Fake aUSDC", "aUSDC");
    }

    /**
     * @dev Supplies USDC and mints aUSDC tokens to the specified address
     * @param asset The address of the asset to supply (must be USDC)
     * @param amount The amount to supply
     * @param onBehalfOf The address that will receive the aTokens
     * @param referralCode The referral code (unused)
     */
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external {
        require(asset == address(USDC), "Only USDC deposits allowed");
        require(amount > 0, "Amount must be greater than 0");
        
        // Transfer USDC from user to this contract
        require(USDC.transferFrom(msg.sender, address(this), amount), "USDC transfer failed");
        
        // Mint equivalent amount of aUSDC to onBehalfOf
        aUSDC.mint(onBehalfOf, amount);
    }

    /**
     * @dev Withdraws USDC by burning aUSDC tokens
     * @param asset The address of the underlying asset to withdraw (must be USDC)
     * @param amount The amount of underlying asset to withdraw
     * @param to The address that will receive the USDC
     * @return The amount withdrawn
     */
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256) {
        require(asset == address(USDC), "Only USDC withdrawals allowed");
        require(amount > 0, "Amount must be greater than 0");
        
        // Burn aUSDC tokens from sender
        aUSDC.burnFrom(msg.sender, amount);
        
        // Transfer USDC to recipient
        require(USDC.transfer(to, amount), "USDC transfer failed");
        
        return amount;
    }
}

/**
 * @title AToken
 * @author PerfectPool
 * @notice A simple ERC20 token that represents the aUSDC token for testing purposes
 */
contract AToken is ERC20 {
    address public immutable lendingPool;

    /**
     * @dev Constructor that sets the token name and symbol
     * @param name The name of the token
     * @param symbol The symbol of the token
     */
    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        lendingPool = msg.sender;
    }

    /**
     * @dev Mints new tokens to the specified address
     * @param to The address that will receive the tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external {
        require(msg.sender == lendingPool, "Only lending pool can mint");
        _mint(to, amount);
    }

    /**
     * @dev Burns tokens from the specified address
     * @param from The address to burn tokens from
     * @param amount The amount of tokens to burn
     */
    function burnFrom(address from, uint256 amount) external {
        require(msg.sender == lendingPool, "Only lending pool can burn");
        _burn(from, amount);
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * @return The number of decimals. In this case 6 to match USDC.
     */
    function decimals() public pure virtual override returns (uint8) {
        return 6;
    }
}
