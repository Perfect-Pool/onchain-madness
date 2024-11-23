// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IOnchainMadnessTicket.sol";
import "./OnchainMadnessTicket.sol";

contract OnchainMadnessTicketFactory is Ownable, Pausable, ReentrancyGuard {
    event TicketPoolCreated(
        uint256 indexed poolId,
        address indexed poolAddress
    );
    event ContinueIteration(uint256 indexed year);
    event IterationFinished(uint256 indexed year);

    // Mapping from pool ID to pool address
    mapping(uint256 => address) public pools;
    // Mapping to track which pool we're currently processing for each year
    mapping(uint256 => uint256) public yearToPoolIdIteration;
    uint256 private currentPoolId;
    IERC20 private immutable USDC;

    constructor(address _usdc) Ownable(msg.sender) {
        require(_usdc != address(0), "USDC address cannot be zero");
        USDC = IERC20(_usdc);
        currentPoolId = 0;
    }

    /**
     * @dev Creates a new OnchainMadnessTicket pool and initializes it
     * @param _gameDeployer Address of the game deployer contract
     * @param _isProtocolPool Whether this is a protocol pool
     * @param _isPrivatePool Whether this is a private pool
     * @param _pin Pin for private pools
     */
    function createPool(
        address _gameDeployer,
        bool _isProtocolPool,
        bool _isPrivatePool,
        string calldata _pin
    ) external whenNotPaused nonReentrant {
        require(
            _gameDeployer != address(0),
            "Game deployer address cannot be zero"
        );

        // Deploy new pool
        OnchainMadnessTicket newPool = new OnchainMadnessTicket();

        // Initialize the pool
        newPool.initialize(
            address(this),
            _gameDeployer,
            address(USDC),
            currentPoolId,
            msg.sender,
            _isProtocolPool,
            _isPrivatePool,
            _isPrivatePool ? _pin : ""
        );

        // Store pool address
        pools[currentPoolId] = address(newPool);

        emit TicketPoolCreated(currentPoolId, address(newPool));

        currentPoolId++;
    }

    /**
     * @dev Claim the ppShare tokens owned by the caller. Only callable by the caller itself
     */
    function claimPPShare(
        uint256 _poolId,
        address _player
    ) public whenNotPaused nonReentrant {
        getPool(_poolId).claimPPShare(_player);
    }

    /**
     * @dev Gets a pool's interface by its ID
     * @param _poolId The ID of the pool
     * @return The pool's interface
     */
    function getPool(
        uint256 _poolId
    ) public view returns (IOnchainMadnessTicket) {
        address poolAddress = pools[_poolId];
        require(poolAddress != address(0), "Pool does not exist");
        return IOnchainMadnessTicket(poolAddress);
    }

    /**
     * @dev Gets a pool's address by its ID
     * @param poolId The ID of the pool
     * @return The pool's address
     */
    function getPoolAddress(uint256 poolId) public view returns (address) {
        require(pools[poolId] != address(0), "Pool does not exist");
        return pools[poolId];
    }

    /**
     * @dev Gets the total number of pools created
     * @return The total number of pools
     */
    function getTotalPools() public view returns (uint256) {
        return currentPoolId;
    }

    /**
     * @dev Wrapper for changePrice function
     */
    function changePrice(
        uint256 _poolId,
        uint256 _newPrice
    ) public whenNotPaused nonReentrant {
        getPool(_poolId).changePrice(_newPrice);
    }

    /**
     * @dev Wrapper for safeMint function
     */
    function safeMint(
        uint256 _poolId,
        address _player,
        uint256 _gameYear,
        uint8[63] memory bets,
        string calldata _pin
    ) public whenNotPaused nonReentrant {
        getPool(_poolId).safeMint(_player, _gameYear, bets, _pin);
    }

    /**
     * @dev Iterates through NFTs across all pools for a given year
     * @param _year The year to iterate
     */
    function iterateYearTokens(
        uint256 _year
    ) public whenNotPaused nonReentrant {
        uint256 _currentPoolId = yearToPoolIdIteration[_year];
        require(_currentPoolId <= currentPoolId, "No more pools to iterate");
        require(pools[_currentPoolId] != address(0), "Pool does not exist");

        uint256 processedIterations = 0;
        bool hasMoreTokens = false;
        IOnchainMadnessTicket pool = getPool(_currentPoolId);

        while (_currentPoolId <= currentPoolId && processedIterations < 20) {
            if (pools[_currentPoolId] == address(0)) {
                emit IterationFinished(_year);
                return;
            }

            (hasMoreTokens, ) = pool.iterateNextToken(_year);
            if (!hasMoreTokens) {
                _currentPoolId++;
                pool = getPool(_currentPoolId);
            }
            processedIterations++;
        }

        // Update the current pool ID for this year
        yearToPoolIdIteration[_year] = _currentPoolId;

        // Emit appropriate event based on iteration status
        if (
            hasMoreTokens ||
            (_currentPoolId <= currentPoolId &&
                pools[_currentPoolId] != address(0))
        ) {
            emit ContinueIteration(_year);
            return;
        }
        emit IterationFinished(_year);
    }

    /**
     * @dev Wrapper for claimPrize function
     */
    function claimPrize(
        uint256 _poolId,
        address _player,
        uint256 _tokenId
    ) public whenNotPaused nonReentrant {
        getPool(_poolId).claimPrize(_player, _tokenId);
    }

    /**
     * @dev Wrapper for increaseGamePot function
     */
    function increaseGamePot(
        uint256 _poolId,
        uint256 _gameYear,
        uint256 _amount
    ) public whenNotPaused nonReentrant {
        getPool(_poolId).increaseGamePot(_gameYear, _amount);
    }

    /**
     * @dev Wrapper for tokenURI function
     */
    function tokenURI(
        uint256 _poolId,
        uint256 _tokenId
    ) public view returns (string memory) {
        return getPool(_poolId).tokenURI(_tokenId);
    }

    function getBetData(
        uint256 _poolId,
        uint256 _tokenId
    ) public view returns (uint8[63] memory) {
        return getPool(_poolId).getBetData(_tokenId);
    }

    function getGameYear(
        uint256 _poolId,
        uint256 _tokenId
    ) public view returns (uint256) {
        return getPool(_poolId).getGameYear(_tokenId);
    }

    function betValidator(
        uint256 _poolId,
        uint256 _tokenId
    ) public view returns (uint8[63] memory validator, uint8 points) {
        return getPool(_poolId).betValidator(_tokenId);
    }

    function getTeamSymbols(
        uint256 _poolId,
        uint256 _tokenId
    ) public view returns (string[63] memory) {
        return getPool(_poolId).getTeamSymbols(_tokenId);
    }

    function amountPrizeClaimed(
        uint256 _poolId,
        uint256 _tokenId
    ) public view returns (uint256 amountToClaim, uint256 amountClaimed) {
        return getPool(_poolId).amountPrizeClaimed(_tokenId);
    }

    function potentialPayout(
        uint256 _poolId,
        uint256 gameYear
    ) public view returns (uint256 payout) {
        return getPool(_poolId).potentialPayout(gameYear);
    }

    function playerQuantity(
        uint256 _poolId,
        uint256 gameYear
    ) public view returns (uint256 players) {
        return getPool(_poolId).playerQuantity(gameYear);
    }

    /**
     * @dev Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
