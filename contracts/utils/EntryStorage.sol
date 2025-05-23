// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IOnchainMadnessFactory.sol";

/**
 * @title IOnchainMadnessEntryFactory
 * @dev Interface for validating entry factory contracts
 */
interface IOnchainMadnessEntryFactory {
    function onchainMadnessContracts(address) external view returns (bool);
}

/**
 * @title EntryStorage
 * @author PerfectPool Team
 * @notice Storage contract for OnchainMadnessEntry data
 * @dev Manages game data, token mappings, and prize pool information for NFT entrys
 * Features:
 * - Multiple pool support with unique identifiers
 * - Game data storage including pot amounts and scores
 * - Token to game year mapping
 * - NFT bet tracking
 * - Prize claim management
 * - Perfect Pool share distribution
 */
contract EntryStorage {
    uint256 public constant PPS_PER_USDC = 20;
    /**
     * @dev Represents a single game's data and state
     * @param pot Total amount in the game's prize pool
     * @param maxScore Highest score achieved in the game
     * @param potClaimed Amount of pot that has been claimed
     * @param claimEnabled Whether prize claiming is enabled
     * @param scoreBetQty Number of bets per score
     * @param tokens Array of token IDs participating in the game
     * @param tokensIterationIndex Current iteration index for token processing
     */
    struct Game {
        uint256 pot;
        uint8 maxScore;
        uint256 potClaimed;
        bool claimEnabled;
        mapping(uint256 => uint256) scoreBetQty;
        uint256[] tokens;
    }

    /**
     * @dev Storage structure for a pool's complete data
     * @param games Mapping of game year to game data
     * @param tokenToGameYear Mapping of token ID to its game year
     * @param nftBet Mapping of token ID to its 63 bet selections
     * @param tokenClaimed Mapping of token ID to claimed amount
     * @param ppShare Mapping of address to Perfect Pool share amount
     */
    struct PoolStorage {
        mapping(uint256 => Game) games;
        mapping(uint256 => uint256) tokenToGameYear;
        mapping(uint256 => uint8[63]) nftBet;
        mapping(uint256 => uint256) tokenClaimed;
        uint256[] tokens;
        uint256 tokensIterationIndex;
    }

    /// @dev Mapping of pool ID to its storage data
    mapping(uint256 => PoolStorage) private pools;
    /// @dev Mapping of shares per year per player
    mapping(uint256 => mapping(address => uint256)) private ppShare;
    /// @dev Mapping of pool ID to initialization status
    mapping(uint256 => bool) private initialized;

    /// @dev Reference to the game factory contract
    IOnchainMadnessFactory public gameDeployer;

    /**
     * @dev Ensures caller is an authorized entry contract
     */
    modifier onlyEntryContract() {
        require(
            IOnchainMadnessEntryFactory(
                gameDeployer.contracts("OM_ENTRY_DEPLOYER")
            ).onchainMadnessContracts(msg.sender) ||
                msg.sender == gameDeployer.contracts("OM_ENTRY_DEPLOYER"),
            "You are not an authorized entry contract"
        );
        _;
    }

    /**
     * @notice Checks if the caller is the contract owner
     * @dev Only the contract owner can call this function
     */
    modifier onlyAdmin() {
        require(gameDeployer.owner() == msg.sender, "Caller is not admin");
        _;
    }

    /**
     * @dev Initializes contract with game deployer address
     * @param _gameDeployer Address of the OnchainMadness game factory
     */
    constructor(address _gameDeployer) {
        gameDeployer = IOnchainMadnessFactory(_gameDeployer);
    }

    /**
     * @notice Initializes a new pool
     * @dev Can only be called once per pool ID by the entry contract
     * @param poolId Unique identifier for the pool
     */
    function initialize(uint256 poolId) external onlyEntryContract {
        require(!initialized[poolId], "Pool already initialized");
        initialized[poolId] = true;
    }

    /**
     * @notice Sets the game factory contract address
     * @param _factory Address of the game factory contract
     */
    function setDeployer(address _factory) public onlyAdmin {
        gameDeployer = IOnchainMadnessFactory(_factory);
    }

    /**
     * @notice Updates game data for a specific year and pool
     * @dev Allows modification of all game parameters
     * @param poolId The pool identifier
     * @param gameYear The year of the game
     * @param pot New total pot amount
     * @param potClaimed New claimed amount
     * @param claimEnabled New claim status
     */
    function updateGame(
        uint256 poolId,
        uint256 gameYear,
        uint256 pot,
        uint256 potClaimed,
        bool claimEnabled
    ) external onlyEntryContract {
        Game storage game = pools[poolId].games[gameYear];
        game.pot = pot;
        game.potClaimed = potClaimed;
        game.claimEnabled = claimEnabled;
    }

    /**
     * @notice Increases the pot for a specific year
     * @dev Only the PerfectPool contract can call this function
     * @param poolId The pool identifier
     * @param gameYear The year of the game
     * @param amount The amount to increase the pot by
     */
    function increasePot(
        uint256 poolId,
        uint256 gameYear,
        uint256 amount
    ) external onlyEntryContract {
        Game storage game = pools[poolId].games[gameYear];
        game.pot += amount;
    }

    /**
     * @notice Updates game data and shares in a single transaction
     * @dev Handles token registration, share distribution, and bet storage
     * @param poolId The pool identifier
     * @param gameYear The year of the game
     * @param tokenId Token being registered
     * @param shareAmount Amount to distribute as shares
     * @param recipient Address receiving non-treasury share
     * @param dataUpdate Encoded price and bet data
     */
    function batchUpdateGameDataAndShares(
        uint256 poolId,
        uint256 gameYear,
        uint256 tokenId,
        uint256 shareAmount,
        address recipient,
        bytes memory dataUpdate
    ) external onlyEntryContract {
        // Update game data
        Game storage game = pools[poolId].games[gameYear];

        // // Set token data
        pools[poolId].tokenToGameYear[tokenId] = gameYear;
        game.tokens.push(tokenId);
        pools[poolId].tokens.push(tokenId);

        uint256 share = shareAmount * PPS_PER_USDC * 10 ** 12;
        uint256 treasuryShare = share / 2;
        uint256 price;

        // Update shares
        ppShare[gameYear][recipient] += treasuryShare;
        (price, pools[poolId].nftBet[tokenId]) = abi.decode(
            dataUpdate,
            (uint256, uint8[63])
        );
        game.pot += (price - shareAmount);
    }

    /**
     * @notice Maps a token to its game year
     * @param poolId The pool identifier
     * @param tokenId Token to map
     * @param gameYear Year to associate with token
     */
    function setTokenGameYear(
        uint256 poolId,
        uint256 tokenId,
        uint256 gameYear
    ) external onlyEntryContract {
        pools[poolId].tokenToGameYear[tokenId] = gameYear;
    }

    /**
     * @notice Stores bet selections for a token
     * @param poolId The pool identifier
     * @param tokenId Token to store bets for
     * @param bets Array of 63 bet selections
     */
    function setNftBet(
        uint256 poolId,
        uint256 tokenId,
        uint8[63] memory bets
    ) external onlyEntryContract {
        pools[poolId].nftBet[tokenId] = bets;
    }

    /**
     * @notice Records amount claimed by a token
     * @param poolId The pool identifier
     * @param tokenId Token that claimed
     * @param amount Amount claimed
     */
    function setTokenClaimed(
        uint256 poolId,
        uint256 tokenId,
        uint256 amount
    ) external onlyEntryContract {
        pools[poolId].tokenClaimed[tokenId] = amount;
    }

    /**
     * @notice To set the Perfect Pool share for an address as burned
     * @param user Address to set share for
     * @param gameYear The game year
     */
    function resetPpShare(
        address user,
        uint256 gameYear
    ) external onlyEntryContract {
        ppShare[gameYear][user] = 0;
    }

    /**
     * @notice Updates the number of bets for a score
     * @param poolId The pool identifier
     * @param gameYear The game year
     * @param score Score value
     * @param qty New quantity of bets
     */
    function setScoreBetQty(
        uint256 poolId,
        uint256 gameYear,
        uint256 score,
        uint256 qty
    ) external onlyEntryContract {
        pools[poolId].games[gameYear].scoreBetQty[score] = qty;
    }

    /**
     * @notice Adds a token to a game
     * @param poolId The pool identifier
     * @param gameYear The game year
     * @param tokenId Token to add
     */
    function addGameToken(
        uint256 poolId,
        uint256 gameYear,
        uint256 tokenId
    ) external onlyEntryContract {
        pools[poolId].games[gameYear].tokens.push(tokenId);
    }

    /**
     * @notice Updates score data after validation
     * @param poolId The pool identifier
     * @param gameYear The game year
     * @param score Validated score to update
     */
    function updateScore(
        uint256 poolId,
        uint256 gameYear,
        uint8 score
    ) external onlyEntryContract {
        Game storage game = pools[poolId].games[gameYear];

        if (score > game.maxScore) {
            game.maxScore = score;
        }
        game.scoreBetQty[score]++;
    }

    /** VIEW FUNCTIONS **/

    /**
     * @notice Retrieves game data for a specific year and pool
     * @dev Returns current state of the game including pot and score information
     * @param poolId The pool identifier
     * @param gameYear The year of the game
     * @return pot Total amount in prize pool
     * @return maxScore Highest score achieved
     * @return potClaimed Amount claimed from pot
     * @return claimEnabled Whether claiming is enabled
     */
    function getGame(
        uint256 poolId,
        uint256 gameYear
    )
        external
        view
        returns (
            uint256 pot,
            uint8 maxScore,
            uint256 potClaimed,
            bool claimEnabled
        )
    {
        Game storage game = pools[poolId].games[gameYear];
        return (game.pot, game.maxScore, game.potClaimed, game.claimEnabled);
    }

    /**
     * @notice Retrieves the game year for a token
     * @param poolId The pool identifier
     * @param tokenId Token to query
     * @return The game year associated with the token
     */
    function getTokenGameYear(
        uint256 poolId,
        uint256 tokenId
    ) external view returns (uint256) {
        return pools[poolId].tokenToGameYear[tokenId];
    }

    /**
     * @notice Retrieves bet selections for a token
     * @param poolId The pool identifier
     * @param tokenId Token to query
     * @return Array of 63 bet selections
     */
    function getNftBet(
        uint256 poolId,
        uint256 tokenId
    ) external view returns (uint8[63] memory) {
        return pools[poolId].nftBet[tokenId];
    }

    /**
     * @notice Retrieves amount claimed by a token
     * @param poolId The pool identifier
     * @param tokenId Token to query
     * @return Amount claimed by the token
     */
    function getTokenClaimed(
        uint256 poolId,
        uint256 tokenId
    ) external view returns (uint256) {
        return pools[poolId].tokenClaimed[tokenId];
    }

    /**
     * @notice Retrieves Perfect Pool share for an address
     * @param user Address to query
     * @param gameYear The game year
     * @return Share amount for the address
     */
    function getPpShare(
        address user,
        uint256 gameYear
    ) external view returns (uint256) {
        (uint256 currentYear, , ) = gameDeployer.getCurrentDate();
        if (currentYear > gameYear) return 0;
        return ppShare[gameYear][user];
    }

    /**
     * @notice Retrieves number of bets for a score
     * @param poolId The pool identifier
     * @param gameYear The game year
     * @param score Score to query
     * @return Number of bets for the score
     */
    function getScoreBetQty(
        uint256 poolId,
        uint256 gameYear,
        uint256 score
    ) external view returns (uint256) {
        Game storage game = pools[poolId].games[gameYear];
        return game.maxScore != score ? 0 : game.scoreBetQty[score];
    }

    /**
     * @notice Retrieves tokens for a game
     * @param poolId The pool identifier
     * @param gameYear The game year
     * @return Array of token IDs
     */
    function getGameTokens(
        uint256 poolId,
        uint256 gameYear
    ) external view returns (uint256[] memory) {
        return pools[poolId].games[gameYear].tokens;
    }

    /**
     * @notice Gets current token and prepares for next iteration
     * @param poolId The pool identifier
     * @param gameYear The game year
     * @return currentTokenId Current token being processed
     * @return hasNext Whether there are more tokens to process
     */
    function getCurrentToken(
        uint256 poolId,
        uint256 gameYear
    )
        external
        onlyEntryContract
        returns (uint256 currentTokenId, bool hasNext)
    {
        PoolStorage storage pool = pools[poolId];

        // Get current token
        if (pool.tokensIterationIndex >= pool.tokens.length) {
            return (0, false);
        }
        currentTokenId = pool.tokens[pool.tokensIterationIndex];

        // Update iteration state
        pool.tokensIterationIndex++;
        pool.games[gameYear].claimEnabled = pool.tokensIterationIndex >= pool.tokens.length;

        return (currentTokenId, true);
    }

    /**
     * @notice Checks if there are more tokens to process for a game year
     * @dev View function that checks the current token iteration state without modifying it
     * @param poolId The pool identifier
     * @return hasNext Whether there are more tokens to process
     */
    function hasMoreTokens(
        uint256 poolId
    ) external view returns (bool hasNext) {
        PoolStorage storage pool = pools[poolId];
        return pool.tokensIterationIndex < pool.tokens.length;
    }
}
