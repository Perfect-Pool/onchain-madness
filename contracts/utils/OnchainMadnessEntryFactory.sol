// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/IERC20.sol";
import "./OnchainMadnessEntry.sol";
import "../interfaces/IOnchainMadnessFactory.sol";

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
    /// @notice Emitted when a the iteration needs to be continued
    event ContinueIteration(uint256 indexed year);
    /// @notice Emitted when an iteration is completed for a year
    event IterationFinished(uint256 indexed year);
    /// @notice Emitted when a the burn iteration needs to be continued
    event ContinueBurnIteration(uint256 indexed year);
    /// @notice Emitted when a the burn iteration is completed for a year
    event BurnFinished(uint256 indexed year);
    /// @notice Emitted when a the dismiss iteration needs to be continued
    event ContinueDismissIteration(uint256 indexed year);
    /// @notice Emitted when a the dismiss iteration is completed for a year
    event DismissIterationFinished(uint256 indexed year);
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

    /** CONSTANTS **/
    /// @notice Time after tournament to start burning PPS tokens
    uint256 public constant PPS_BURN_DELAY = 30 days;

    /** STATE VARIABLES **/
    /// @notice Mapping of pool IDs to pool addresses
    mapping(uint256 => address) public pools;
    /// @notice Mapping of pool addresses to their IDs
    mapping(address => uint256) private poolIds;
    /// @notice Mapping of years to their corresponding pool ID iterations
    mapping(uint256 => uint256) public yearToPoolIdIteration;
    /// @notice Mapping of years to their corresponding pool ID burn iterations
    mapping(uint256 => uint256) public yearToPoolIdBurnIteration;
    /// @notice Mapping of years to their corresponding pool ID dismiss iterations
    mapping(uint256 => uint256) public yearToPoolIdDismissIteration;
    /// @notice Mapping to track valid OnchainMadness contract addresses
    mapping(address => bool) public onchainMadnessContracts;
    /// @notice Mapping to block duplication of pool names
    mapping(bytes32 => bool) public poolNames;
    /// @notice Mapping to check if the PPS tokens have already been burned for a year
    mapping(uint256 => bool) public yearToPPSBurned;
    /// @notice Mapping to check the date to burn PPS tokens
    mapping(uint256 => uint256) public yearToPPSBurnDate;
    /// @notice Mapping to check if the prizes have already been dismissed for a year
    mapping(uint256 => bool) public yearToPrizeDismissed;

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
     * @notice Only the contract owner can call this function
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
     * @notice Deploys a new minimal proxy clone of the implementation contract
     * @param _isProtocolPool Whether this is a protocol pool
     * @param _isPrivatePool Whether this is a private pool
     * @param _pin Pin for private pools
     * @param _poolName Name of the pool
     * @return The ID of the created pool
     */
    function createPool(
        bool _isProtocolPool,
        bool _isPrivatePool,
        string calldata _pin,
        string calldata _poolName
    ) external whenNotPaused nonReentrant returns (uint256) {
        require(
            poolNames[keccak256(bytes(_poolName))] == false,
            "Pool name already exists"
        );
        poolNames[keccak256(bytes(_poolName))] = true;

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
     * @notice Claims PerfectPool tokens earned from shares
     * @dev Transfers accumulated PP tokens to the player
     * @param _player Address to receive the tokens
     * @param _gameYear Tournament year to check
     */
    function claimPPShare(address _player, uint256 _gameYear) external {
        IEntryStorage entryStorage = IEntryStorage(
            IEntryStorage(gameDeployer.contracts("OM_ENTRY_STORAGE"))
        );
        uint256 amount = entryStorage.getPpShare(_player, _gameYear);
        require(amount > 0, "No ppShare tokens to claim.");
        entryStorage.resetPpShare(_player, _gameYear);
        IPerfectPool(gameDeployer.contracts("PERFECTPOOL")).transfer(
            _player,
            amount
        );
    }

    /**
     * @notice Verifies the shares for a player
     * @dev Checks the amount of PP tokens available for the player to claim
     * @param _player Address to check
     * @param _gameYear Tournament year to check
     * @return Amount of PP tokens available for the player
     */
    function verifyShares(
        address _player,
        uint256 _gameYear
    ) public view returns (uint256) {
        return
            IEntryStorage(
                IEntryStorage(gameDeployer.contracts("OM_ENTRY_STORAGE"))
            ).getPpShare(_player, _gameYear);
    }

    /**
     * @notice Mints a new NFT representing a bracket prediction
     * @notice Wrapper function that calls safeMint in the pool contract. Validates prediction against actual results.
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
        uint256 price = OnchainMadnessEntry(poolAddress).price();

        USDC.transferFrom(msg.sender, poolAddress, price);

        uint256 nextTokenId = OnchainMadnessEntry(poolAddress).safeMint(
            msg.sender,
            _gameYear,
            bets,
            _pin
        );

        uint256 share = (price / 10) *
            IEntryStorage(gameDeployer.contracts("OM_ENTRY_STORAGE"))
                .PPS_PER_USDC() *
            10 ** 12;

        //transfer ppShare to treasury, avoiding underflow / overflow
        IPerfectPool(gameDeployer.contracts("PERFECTPOOL")).transfer(
            gameDeployer.contracts("TREASURY"),
            share - (share / 2)
        );

        emit BetPlaced(_gameYear, _poolId, nextTokenId, msg.sender);
    }

    /**
     * @notice Iterates through NFTs across all pools for a given year
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
        IPerfectPool perfectPool = IPerfectPool(
            gameDeployer.contracts("PERFECTPOOL")
        );

        if (pools[_currentPoolId] == address(0)) {
            emit IterationFinished(_gameYear);
            yearToPPSBurnDate[_gameYear] = block.timestamp + PPS_BURN_DELAY;
            if (!perfectPool.lockWithdrawal()) {
                perfectPool.setLockWithdrawal(true);
            }
            return;
        }

        uint256 processedIterations = 0;
        bool hasMoreTokens = false;
        OnchainMadnessEntry pool = OnchainMadnessEntry(pools[_currentPoolId]);

        while (processedIterations < 10) {
            if (pools[_currentPoolId] == address(0)) {
                emit IterationFinished(_gameYear);
                yearToPPSBurnDate[_gameYear] = block.timestamp + PPS_BURN_DELAY;
                if (!perfectPool.lockWithdrawal()) {
                    perfectPool.setLockWithdrawal(true);
                }
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

        if (pools[_currentPoolId] == address(0)) {
            emit IterationFinished(_gameYear);
            yearToPPSBurnDate[_gameYear] = block.timestamp + PPS_BURN_DELAY;
            if (!perfectPool.lockWithdrawal()) {
                perfectPool.setLockWithdrawal(true);
            }
            return;
        }
        emit ContinueIteration(_gameYear);
    }

    /**
     * @notice Checks if the tokens needs to be burned
     * @param _gameYear The year to check
     * @return True if the tokens need to be burned, false otherwise
     */
    function needsToBeBurned(uint256 _gameYear) public view returns (bool) {
        // return
        //     yearToPPSBurnDate[_gameYear] > 0 &&
        //     !yearToPPSBurned[_gameYear] &&
        //     block.timestamp > yearToPPSBurnDate[_gameYear]; //production
        return true; // for testing
    }

    /**
     * @notice Iterates through the pools to burn PPS tokens for a given year
     * Checks if the burn date has passed and the tokens have not already been burned.
     * If burn date is still 0, denies the burn.
     * @param _gameYear The year to iterate
     */
    function burnYearTokens(
        uint256 _gameYear
    ) public whenNotPaused nonReentrant {
        require(
            needsToBeBurned(_gameYear),
            "The claim period has not ended yet."
        );

        IPerfectPool perfectPool = IPerfectPool(
            gameDeployer.contracts("PERFECTPOOL")
        );
        if (yearToPPSBurned[_gameYear] == false) {
            perfectPool.burnTokens(perfectPool.balanceOf(address(this)));
            emit BurnFinished(_gameYear);
            perfectPool.setLockWithdrawal(false);
            yearToPPSBurned[_gameYear] = true;
        }
    }

    /**
     * @notice Checks if the prize can be dismissed
     * @param _gameYear The year to check
     * @return True if the prize can be dismissed, false otherwise
     */
    function needsToBeDismissed(uint256 _gameYear) public view returns (bool) {
        // (uint256 currentYear,,) = OnchainMadnessLib.getCurrentDate();
        // return
        //     currentYear > _gameYear; //production
        return true; // for testing
    }

    /**
     * @notice Iterates through the pools to dismiss prizes for a given year
     * Checks if the year needs to be dismissed and if it hasn't been dismissed yet.
     * @param _gameYear The year to iterate
     */
    function iterateDismissYear(
        uint256 _gameYear
    ) public whenNotPaused nonReentrant {
        require(
            needsToBeDismissed(_gameYear),
            "This year's prizes cannot be dismissed yet."
        );

        uint256 _currentPoolId = yearToPoolIdDismissIteration[_gameYear];
        uint256 processedIterations = 0;

        while (processedIterations < 10) {
            if (pools[_currentPoolId] == address(0)) {
                emit DismissIterationFinished(_gameYear);
                yearToPrizeDismissed[_gameYear] = true;
                return;
            }

            OnchainMadnessEntry pool = OnchainMadnessEntry(
                pools[_currentPoolId]
            );
            pool.dismissPot();
            _currentPoolId++;
            processedIterations++;
        }

        // Update the current pool ID for this year's dismiss iteration
        yearToPoolIdDismissIteration[_gameYear] = _currentPoolId;

        // Emit appropriate event based on iteration status
        if (
            _currentPoolId > currentPoolId &&
            pools[_currentPoolId] != address(0)
        ) {
            emit ContinueDismissIteration(_gameYear);
            return;
        }
        emit DismissIterationFinished(_gameYear);
        yearToPrizeDismissed[_gameYear] = true;
    }

    /**
     * @notice Claims prize for a winning bracket
     * @notice Wrapper function that calls claimPrize in the pool contract. Validates game completion and transfers prize.
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
     * @notice Iterates through the tokenIds and calls claimPrize for each one using claimPrize()
     * @param _poolId ID of the pool
     * @param _tokenIds Token IDs representing the brackets
     */
    function claimAll(
        uint256 _poolId,
        uint256[] memory _tokenIds
    ) public whenNotPaused nonReentrant {
        IEntryStorage entryStorage = IEntryStorage(
            IEntryStorage(gameDeployer.contracts("OM_ENTRY_STORAGE"))
        );
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 gameYear = entryStorage.getTokenGameYear(
                _poolId,
                _tokenIds[i]
            );
            uint256 amountPPS = entryStorage.getPpShare(msg.sender, gameYear);
            if (amountPPS > 0) {
                IPerfectPool(
                    IPerfectPool(gameDeployer.contracts("PERFECTPOOL"))
                ).transfer(msg.sender, amountPPS);
                entryStorage.resetPpShare(msg.sender, gameYear);
            }
            OnchainMadnessEntry(getPoolAddress(_poolId)).claimPrize(
                msg.sender,
                _tokenIds[i]
            );
            emit PrizeClaimed(_tokenIds[i], _poolId);
        }
    }

    /**
     * @notice Increases the prize pool for a specific game
     * @notice Wrapper function that calls increaseGamePot in the pool contract. Updates the total prize pool.
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
     * @notice Wrapper function that calls tokenURI in the pool contract
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
     * @notice Wrapper function that calls getBetData in the pool contract
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
     * @notice Wrapper function that calls getGameYear in the pool contract
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
     * @notice Wrapper function that calls betValidator in the pool contract. Checks prediction against actual results.
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
     * @notice Returns the amount of prize claimed for a bracket
     * @notice Wrapper function that calls amountPrizeClaimed in the pool contract. Shows how much USDC was claimed.
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
     * @notice Wrapper function that calls potentialPayout in the pool contract. Calculates maximum possible prize.
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
     * @notice Wrapper function that calls playerQuantity in the pool contract. Counts total participants.
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
     * @notice Returns the created pool data
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
     * @notice Returns if the pool name exists
     * @param _poolName The name of the pool
     * @return exists Whether the pool name exists
     */
    function poolNameExists(
        string calldata _poolName
    ) public view returns (bool) {
        return poolNames[keccak256(bytes(_poolName))];
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
