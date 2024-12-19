// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/IERC20.sol";
import "./OnchainMadnessEntry.sol";

/**
 * @title OnchainMadnessEntryFactory
 * @author PerfectPool Team
 * @notice Factory contract for creating and managing OnchainMadnessEntry pools
 * @dev Uses the Clones pattern to deploy minimal proxy contracts for each pool
 * Features:
 * - Creates and manages entry pools
 * - Handles pool initialization and configuration
 * - Manages protocol and private pools
 * - Provides wrapper functions for entry operations
 */
contract OnchainMadnessEntryFactory is Pausable, ReentrancyGuard {
    /** EVENTS **/
    /// @notice Emitted when a new entry pool is created
    event EntryPoolCreated(
        uint256 indexed poolId,
        address indexed poolAddress,
        string poolName
    );
    /// @notice Emitted when a new iteration starts for a year
    event ContinueIteration(uint256 indexed year);
    /// @notice Emitted when an iteration is completed for a year
    event IterationFinished(uint256 indexed year);
    /// @notice Emitted when a prize is claimed for a token
    event PrizeClaimed(uint256 indexed _tokenId, uint256 _poolId);
    /// @notice Emitted when a bet is placed
    event BetPlaced(
        uint256 indexed gameYear,
        uint256 indexed poolId,
        uint256 tokenId,
        address player
    );
    /// @notice Emitted when the game pot is increased
    event GamePotIncreased(uint256 indexed _gameYear, uint256 _amount);
    /// @notice Emitted when the game deployer is changed
    event GameDeployerChanged(address _gameDeployer);

    /** STATE VARIABLES **/
    /// @notice Mapping of pool IDs to pool addresses
    mapping(uint256 => address) public pools;
    /// @notice Mapping of pool addresses to their IDs
    mapping(address => uint256) private poolIds;
    /// @notice Mapping of years to their corresponding pool ID iterations
    mapping(uint256 => uint256) public yearToPoolIdIteration;
    /// @notice Mapping to track valid OnchainMadness contract addresses
    mapping(address => bool) public onchainMadnessContracts;

    /// @notice Counter for pool IDs
    uint256 private currentPoolId;
    /// @notice Address of the implementation contract for cloning
    address public immutable implementation;

    /// @notice Reference to the game factory contract
    IOnchainMadnessFactory public gameDeployer;
    /// @notice Reference to the USDC token contract
    IERC20 public USDC;

    /**
     * @notice Checks if the caller is the contract owner
     * @dev Only the contract owner can call this function
     */
    modifier onlyAdmin() {
        require(gameDeployer.owner() == msg.sender, "Caller is not admin");
        _;
    }

    /**
     * @notice Constructor for the OnchainMadnessEntryFactory contract
     * @param _implementation Address of the implementation contract
     */
    constructor(
        address _implementation,
        address _gameDeployer,
        address _token
    ) {
        require(
            _implementation != address(0),
            "Implementation address cannot be zero"
        );
        implementation = _implementation;
        currentPoolId = 0;
        gameDeployer = IOnchainMadnessFactory(_gameDeployer);
        USDC = IERC20(_token);
    }

    /**
     * @notice Sets the game deployer contract
     * @param _gameDeployer Address of the game deployer contract
     */
    function setGameDeployer(address _gameDeployer) external onlyAdmin {
        gameDeployer = IOnchainMadnessFactory(_gameDeployer);
        emit GameDeployerChanged(_gameDeployer);
    }

    /**
     * @notice Creates a new OnchainMadnessEntry pool
     * @dev Deploys a new minimal proxy clone of the implementation contract
     * @param _isProtocolPool Whether this is a protocol pool
     * @param _isPrivatePool Whether this is a private pool
     * @param _pin Pin for private pools
     */
    function createPool(
        bool _isProtocolPool,
        bool _isPrivatePool,
        string calldata _pin,
        string calldata _poolName
    ) external whenNotPaused nonReentrant returns (uint256) {
        // Deploy new pool using clone
        address newPool = Clones.clone(implementation);
        uint256 poolId = currentPoolId;

        // Store pool address and ID mappings
        pools[poolId] = newPool;
        poolIds[newPool] = poolId;
        onchainMadnessContracts[newPool] = true;

        IPerfectPool perfectPool = IPerfectPool(
            gameDeployer.contracts("PERFECTPOOL")
        );
        perfectPool.setAuthorizedMinter(newPool, true);
        perfectPool.setOnchainMadnessContract(newPool, true);
        emit EntryPoolCreated(poolId, newPool, _poolName);

        OnchainMadnessEntry(newPool).initialize(
            poolId,
            address(this),
            msg.sender,
            _isProtocolPool,
            _isPrivatePool,
            _pin,
            _poolName
        );

        currentPoolId++;

        return poolId;
    }

    /**
     * @notice Claims the PP share tokens for a player
     * @dev Wrapper function that calls the corresponding function in the pool contract
     * @param _poolId ID of the pool
     * @param _player Address of the player claiming their share
     */
    function claimPPShare(
        uint256 _poolId,
        address _player
    ) public whenNotPaused nonReentrant {
        OnchainMadnessEntry(getPoolAddress(_poolId)).claimPPShare(_player);
    }

    /**
     * @notice Mints a new NFT representing a bracket prediction
     * @dev Wrapper function that calls safeMint in the pool contract. Validates prediction against actual results.
     * @param _poolId ID of the pool
     * @param _gameYear Tournament year
     * @param bets Array of 63 predictions for the tournament
     * @param _pin PIN for private pools
     */
    function safeMint(
        uint256 _poolId,
        uint256 _gameYear,
        uint8[63] memory bets,
        string calldata _pin
    ) public whenNotPaused nonReentrant {
        //approve USDC for the pool
        address poolAddress = getPoolAddress(_poolId);

        USDC.transferFrom(
            msg.sender,
            poolAddress,
            OnchainMadnessEntry(poolAddress).price()
        );

        uint256 nextTokenId = OnchainMadnessEntry(poolAddress).safeMint(
            msg.sender,
            _gameYear,
            bets,
            _pin
        );

        emit BetPlaced(_gameYear, _poolId, nextTokenId, msg.sender);
    }

    /**
     * @dev Iterates through NFTs across all pools for a given year
     * @param _gameYear The year to iterate
     */
    function iterateYearTokens(
        uint256 _gameYear
    ) public whenNotPaused nonReentrant {
        (, uint8 status) = abi.decode(
            gameDeployer.getGameStatus(_gameYear),
            (uint8, uint8)
        );
        require(status == 3, "Game not finished.");

        uint256 _currentPoolId = yearToPoolIdIteration[_gameYear];
        require(_currentPoolId <= currentPoolId, "No more pools to iterate");
        require(pools[_currentPoolId] != address(0), "Pool does not exist");

        uint256 processedIterations = 0;
        bool hasMoreTokens = false;
        OnchainMadnessEntry pool = OnchainMadnessEntry(pools[_currentPoolId]);

        while (processedIterations < 20) {
            if (pools[_currentPoolId] == address(0)) {
                emit IterationFinished(_gameYear);
                return;
            }

            (hasMoreTokens, ) = pool.iterateNextToken(_gameYear);
            if (!hasMoreTokens) {
                _currentPoolId++;
                pool = OnchainMadnessEntry(pools[_currentPoolId]);
            }
            processedIterations++;
        }

        // Update the current pool ID for this year
        yearToPoolIdIteration[_gameYear] = _currentPoolId;

        // Emit appropriate event based on iteration status
        if (
            hasMoreTokens ||
            (_currentPoolId > currentPoolId &&
                pools[_currentPoolId] != address(0))
        ) {
            emit ContinueIteration(_gameYear);
            return;
        }
        emit IterationFinished(_gameYear);
    }

    /**
     * @notice Claims prize for a winning bracket
     * @dev Wrapper function that calls claimPrize in the pool contract. Validates game completion and transfers prize.
     * @param _poolId ID of the pool
     * @param _tokenId Token ID representing the bracket
     */
    function claimPrize(
        uint256 _poolId,
        uint256 _tokenId
    ) public whenNotPaused nonReentrant {
        OnchainMadnessEntry(getPoolAddress(_poolId)).claimPrize(
            msg.sender,
            _tokenId
        );
        emit PrizeClaimed(_tokenId, _poolId);
    }

    /**
     * @notice Claims prize for multiple tokenIds at the same pool
     * @dev Iterates through the tokenIds and calls claimPrize for each one using claimPrize()
     * @param _poolId ID of the pool
     * @param _tokenIds Token IDs representing the brackets
     */
    function claimAll(
        uint256 _poolId,
        uint256[] memory _tokenIds
    ) public whenNotPaused nonReentrant {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            OnchainMadnessEntry(getPoolAddress(_poolId)).claimPrize(
                msg.sender,
                _tokenIds[i]
            );
            emit PrizeClaimed(_tokenIds[i], _poolId);
        }
    }

    /**
     * @notice Increases the prize pool for a specific game
     * @dev Wrapper function that calls increaseGamePot in the pool contract. Updates the total prize pool.
     * @param _poolId ID of the pool
     * @param _gameYear Tournament year to increase pot for
     * @param _amount Amount of USDC to add to the pot
     */
    function increaseGamePot(
        uint256 _poolId,
        uint256 _gameYear,
        uint256 _amount
    ) public whenNotPaused nonReentrant {
        OnchainMadnessEntry(getPoolAddress(_poolId)).increaseGamePot(
            _gameYear,
            _amount
        );

        emit GamePotIncreased(_gameYear, _amount);
    }

    /**
     * @notice Returns the token URI for a given NFT
     * @dev Wrapper function that calls tokenURI in the pool contract
     * @param _poolId ID of the pool
     * @param _tokenId ID of the NFT
     * @return The token URI
     */
    function tokenURI(
        uint256 _poolId,
        uint256 _tokenId
    ) public view returns (string memory) {
        return OnchainMadnessEntry(getPoolAddress(_poolId)).tokenURI(_tokenId);
    }

    /**
     * @notice Returns the pool address for a given pool ID
     * @param _poolId ID of the pool
     * @return The pool address
     */
    function getPoolAddress(uint256 _poolId) public view returns (address) {
        address poolAddress = pools[_poolId];
        require(poolAddress != address(0), "Pool does not exist");
        return poolAddress;
    }

    /**
     * @notice Returns the total number of pools created
     * @return The total number of pools
     */
    function getTotalPools() public view returns (uint256) {
        return currentPoolId;
    }

    /**
     * @notice Returns the bet data for a given NFT
     * @dev Wrapper function that calls getBetData in the pool contract
     * @param _poolId ID of the pool
     * @param _tokenId ID of the NFT
     * @return The bet data
     */
    function getBetData(
        uint256 _poolId,
        uint256 _tokenId
    ) public view returns (uint8[63] memory) {
        return
            OnchainMadnessEntry(getPoolAddress(_poolId)).getBetData(_tokenId);
    }

    /**
     * @notice Returns the game year for a given NFT
     * @dev Wrapper function that calls getGameYear in the pool contract
     * @param _poolId ID of the pool
     * @param _tokenId ID of the NFT
     * @return The game year
     */
    function getGameYear(
        uint256 _poolId,
        uint256 _tokenId
    ) public view returns (uint256) {
        return
            OnchainMadnessEntry(getPoolAddress(_poolId)).getGameYear(_tokenId);
    }

    /**
     * @notice Validates a bracket prediction and returns its score
     * @dev Wrapper function that calls betValidator in the pool contract. Checks prediction against actual results.
     * @param _poolId ID of the pool
     * @param _tokenId Token ID of the bracket to validate
     * @return validator Validation data for the bracket
     * @return points Total points scored by the bracket
     */
    function betValidator(
        uint256 _poolId,
        uint256 _tokenId
    ) public view returns (uint8[63] memory validator, uint8 points) {
        return
            OnchainMadnessEntry(getPoolAddress(_poolId)).betValidator(_tokenId);
    }

    /**
     * @notice Returns the team symbols for a given NFT
     * @dev Wrapper function that calls getTeamSymbols in the pool contract
     * @param _poolId ID of the pool
     * @param _tokenId ID of the NFT
     * @return The team symbols
     */
    function getTeamSymbols(
        uint256 _poolId,
        uint256 _tokenId
    ) public view returns (string[63] memory) {
        return
            OnchainMadnessEntry(getPoolAddress(_poolId)).getTeamSymbols(
                _tokenId
            );
    }

    /**
     * @notice Returns the amount of prize claimed for a bracket
     * @dev Wrapper function that calls amountPrizeClaimed in the pool contract. Shows how much USDC was claimed.
     * @param _poolId ID of the pool
     * @param _tokenId Token ID of the bracket
     * @return amountToClaim Amount of USDC claimed as prize
     * @return amountClaimed Amount of USDC already claimed
     */
    function amountPrizeClaimed(
        uint256 _poolId,
        uint256 _tokenId
    ) public view returns (uint256 amountToClaim, uint256 amountClaimed) {
        return
            OnchainMadnessEntry(getPoolAddress(_poolId)).amountPrizeClaimed(
                _tokenId
            );
    }

    /**
     * @notice Returns the potential payout for a game year
     * @dev Wrapper function that calls potentialPayout in the pool contract. Calculates maximum possible prize.
     * @param _poolId ID of the pool
     * @param gameYear Tournament year to check
     * @return payout Maximum potential payout in USDC
     */
    function potentialPayout(
        uint256 _poolId,
        uint256 gameYear
    ) public view returns (uint256) {
        return
            OnchainMadnessEntry(getPoolAddress(_poolId)).potentialPayout(
                gameYear
            );
    }

    /**
     * @notice Returns the number of players for a game year
     * @dev Wrapper function that calls playerQuantity in the pool contract. Counts total participants.
     * @param _poolId ID of the pool
     * @param gameYear Tournament year to check
     * @return quantity Number of players participating
     */
    function playerQuantity(
        uint256 _poolId,
        uint256 gameYear
    ) public view returns (uint256) {
        return
            OnchainMadnessEntry(getPoolAddress(_poolId)).playerQuantity(
                gameYear
            );
    }

    /**
     * @notice Returns the pool ID for a given pool address
     * @param _poolAddress The pool address
     * @return The pool ID
     */
    function getPoolId(address _poolAddress) public view returns (uint256) {
        require(_poolAddress != address(0), "Pool address cannot be zero");
        uint256 poolId = poolIds[_poolAddress];
        require(pools[poolId] == _poolAddress, "Pool does not exist");
        return poolId;
    }

    /**
     * @dev Returns the created pool data
     * @param poolId The ID of the pool
     * @return name The name of the pool
     * @return poolAddress The address of the pool
     * @return isPrivate Whether the pool is private
     * @return isProtocol Whether the pool is created by the protocol
     * @return pin The PIN required to join the pool
     * @return creator The address of the creator of the pool
     */
    function getPoolData(
        uint256 poolId
    )
        public
        view
        returns (
            string memory name,
            address poolAddress,
            bool isPrivate,
            bool isProtocol,
            bytes memory pin,
            address creator
        )
    {
        return (
            string(OnchainMadnessEntry(getPoolAddress(poolId)).poolName()),
            getPoolAddress(poolId),
            OnchainMadnessEntry(getPoolAddress(poolId)).isPrivatePool(),
            OnchainMadnessEntry(getPoolAddress(poolId)).isProtocolPool(),
            OnchainMadnessEntry(getPoolAddress(poolId)).pin(),
            OnchainMadnessEntry(getPoolAddress(poolId)).creator()
        );
    }

    /**
     * @notice Returns the address of the game deployer contract
     * @return The game deployer address
     */
    function getGameDeployer() external view returns (address) {
        return address(gameDeployer);
    }

    /**
     * @notice Pauses the contract
     */
    function pause() external onlyAdmin {
        _pause();
    }

    /**
     * @notice Unpauses the contract
     */
    function unpause() external onlyAdmin {
        _unpause();
    }
}
