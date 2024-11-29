// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../interfaces/IOnchainMadnessFactory.sol";
import "../interfaces/ITicketStorage.sol";
import "../interfaces/IERC20.sol";
import "../libraries/OnchainMadnessLib.sol";

/**
 * @title IOnchainMadnessTicketFactory
 * @dev Interface for the ticket factory to manage pool IDs
 */
interface IOnchainMadnessTicketFactory {
    function getPoolId(address _gameContract) external view returns (uint256);
}

/**
 * @title INftMetadata
 * @dev Interface for generating NFT metadata
 */
interface INftMetadata {
    function buildMetadata(
        uint256 _poolId,
        uint256 _gameYear,
        uint256 _tokenId
    ) external view returns (string memory);
}

/**
 * @title IPerfectPool
 * @dev Interface for interacting with the PerfectPool contract
 */
interface IPerfectPool {
    function increasePool(
        uint256 amountUSDC,
        uint8[] calldata percentage,
        address[] calldata receivers
    ) external;

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function perfectPrize(uint256 year, address gameContract) external;

    function increaseWinnersQty(uint256 year) external;

    function setAuthorizedMinter(
        address minter,
        bool authorized
    ) external;

    function setOnchainMadnessContract(
        address contractAddress,
        bool authorized
    ) external;
}

/**
 * @title OnchainMadnessTicket
 * @author PerfectPool Team
 * @notice NFT contract representing tournament bracket predictions
 * @dev Implementation contract to be cloned by OnchainMadnessTicketFactory
 * Features:
 * - ERC721 NFT representing bracket predictions
 * - Integration with PerfectPool for prize distribution
 * - Bracket validation and scoring system
 * - Support for private and protocol pools
 * - Prize claiming mechanism
 */
contract OnchainMadnessTicket is ERC721, ReentrancyGuard {
    /** STATE VARIABLES **/
    /// @dev Counter for token IDs
    uint256 private _nextTokenId;
    /// @dev Fixed price in USDC for minting a ticket (20 USDC)
    uint256 public immutable price;
    /// @dev Unique identifier for this pool
    uint256 public poolId;
    /// @dev Address of the factory that deployed this contract
    address public nftDeployer;
    /// @dev Address of the pool creator
    address public creator;
    /// @dev If true, requires PIN for minting
    bool public isPrivatePool;
    /// @dev If true, shares go to players instead of creator
    bool public isProtocolPool;
    /// @dev Hash of the PIN for private pools
    bytes32 private pin;

    /// @dev Reference to the game factory contract
    IOnchainMadnessFactory public gameDeployer;
    /// @dev Reference to the PerfectPool contract
    IPerfectPool private perfectPool;
    /// @dev Reference to the USDC token contract
    IERC20 private immutable USDC;
    /// @dev Reference to the ticket storage contract
    ITicketStorage public ticketStorage;

    /** MODIFIERS **/
    /**
     * @dev Ensures caller is the factory that deployed this contract
     */
    modifier onlyNftDeployer() {
        require(msg.sender == nftDeployer, "Caller is not nft deployer");
        _;
    }

    /**
     * @notice Creates a new OnchainMadnessTicket contract
     * @dev Sets up the NFT with USDC integration and fixed price
     * @param _token Address of the USDC token contract
     */
    constructor(address _token) ERC721("OnchainMadnessTicket", "OMT") {
        _nextTokenId = 1;
        USDC = IERC20(_token);
        price = 20 * (10 ** USDC.decimals());
    }

    /**
     * @notice Initializes a cloned ticket contract
     * @dev Sets up all contract references and pool configuration
     * @param _nftDeployer Address of the factory contract
     * @param _gameDeployer Address of the game factory
     * @param _creator Address of the pool creator
     * @param _isProtocolPool If true, shares go to players instead of creator
     * @param _isPrivatePool If true, requires PIN for minting
     * @param _pin PIN for private pools (empty for public pools)
     */
    function initialize(
        address _nftDeployer,
        address _gameDeployer,
        address _creator,
        bool _isProtocolPool,
        bool _isPrivatePool,
        string calldata _pin
    ) public {
        gameDeployer = IOnchainMadnessFactory(_gameDeployer);
        nftDeployer = _nftDeployer;
        creator = _creator;
        isProtocolPool = _isProtocolPool;
        isPrivatePool = _isPrivatePool;
        pin = keccak256(abi.encodePacked(_pin));
        perfectPool = IPerfectPool(gameDeployer.contracts("PERFECTPOOL"));
        poolId = IOnchainMadnessTicketFactory(_nftDeployer).getPoolId(
            address(this)
        );
        ticketStorage = ITicketStorage(
            gameDeployer.contracts("OM_TICKET_STORAGE")
        );
        ticketStorage.initialize(poolId);
    }

    /**
     * @notice Mints a new ticket NFT with bracket predictions
     * @dev Handles USDC payment, PerfectPool integration, and storage updates
     * @param _player Address to receive the NFT
     * @param _gameYear Tournament year for the predictions
     * @param bets Array of 63 team selections representing the bracket
     * @param _pin PIN for private pools (ignored for public pools)
     * @return The ID of the newly minted token
     */
    function safeMint(
        address _player,
        uint256 _gameYear,
        uint8[63] memory bets,
        string calldata _pin
    ) external onlyNftDeployer returns (uint256) {
        require(!gameDeployer.paused(), "Game paused.");

        (, uint8 status) = abi.decode(
            gameDeployer.getGameStatus(_gameYear),
            (uint8, uint8)
        );
        require(status == 1, "Bets closed.");
        USDC.transferFrom(_player, address(this), price);

        if (isPrivatePool) {
            require(keccak256(abi.encodePacked(_pin)) == pin, "Invalid pin.");
        }

        uint8[] memory percentages = new uint8[](1);
        percentages[0] = 100;

        address[] memory recipients = new address[](1);
        recipients[0] = address(this);

        USDC.approve(address(perfectPool), (price / 10));
        uint256 balanceBefore = perfectPool.balanceOf(address(this));
        perfectPool.increasePool((price / 10), percentages, recipients);

        ticketStorage.batchUpdateGameDataAndShares(
            poolId,
            _gameYear,
            _nextTokenId,
            (perfectPool.balanceOf(address(this)) - balanceBefore),
            (isProtocolPool ? _player : creator),
            abi.encode(price, bets)
        );

        _safeMint(_player, _nextTokenId);
        _nextTokenId++;
        return _nextTokenId - 1;
    }

    /**
     * @notice Processes the next token in score calculation
     * @dev Used for batch processing of bracket validations
     * @param _gameYear Tournament year to process
     * @return success Whether there are more tokens to process
     * @return score Score achieved by the current token
     */
    function iterateNextToken(
        uint256 _gameYear
    ) external onlyNftDeployer returns (bool success, uint8 score) {
        (uint256 currentTokenId, bool hasNext) = ticketStorage.getCurrentToken(
            poolId,
            _gameYear
        );

        if (!hasNext) {
            return (false, 0);
        }

        (, score) = betValidator(currentTokenId);
        ticketStorage.updateScore(poolId, _gameYear, score);
        
        if (score == 64) {
            perfectPool.increaseWinnersQty(_gameYear);
        }

        return (true, score);
    }

    /**
     * @notice Claims prize for a winning bracket
     * @dev Validates game completion and calculates prize amount
     * @param _player Address to receive the prize
     * @param _tokenId Token ID representing the bracket
     */
    function claimPrize(
        address _player,
        uint256 _tokenId
    ) external nonReentrant onlyNftDeployer {
        require(!gameDeployer.paused(), "Game paused.");
        require(
            ticketStorage.getTokenClaimed(poolId, _tokenId) == 0,
            "Tokens already claimed."
        );

        uint256 _gameYear = ticketStorage.getTokenGameYear(poolId, _tokenId);
        (
            uint256 pot,
            uint8 maxScore,
            uint256 potClaimed,
            bool claimEnabled,
            uint256 tokensIterationIndex
        ) = ticketStorage.getGame(poolId, _gameYear);
        require(claimEnabled, "Game not finished.");

        (, uint8 status) = abi.decode(
            gameDeployer.getGameStatus(_gameYear),
            (uint8, uint8)
        );
        require(status == 3, "Game not finished.");

        (, uint8 tokenScore) = betValidator(_tokenId);
        require(maxScore != tokenScore, "You are not a winner");

        uint256 amount = OnchainMadnessLib.calculatePrize(
            pot,
            potClaimed,
            ticketStorage.getScoreBetQty(poolId, _gameYear, tokenScore)
        );

        ticketStorage.updateGame(
            poolId,
            _gameYear,
            pot,
            maxScore,
            potClaimed + amount,
            claimEnabled,
            tokensIterationIndex
        );
        ticketStorage.setTokenClaimed(poolId, _tokenId, amount);

        USDC.transfer(_player, amount);
    }

    /**
     * @notice Claims PerfectPool tokens earned from shares
     * @dev Transfers accumulated PP tokens to the player
     * @param _player Address to receive the tokens
     */
    function claimPPShare(address _player) external onlyNftDeployer {
        uint256 amount = ticketStorage.getPpShare(poolId, _player);
        require(amount > 0, "No ppShare tokens to claim.");
        ticketStorage.setPpShare(poolId, _player, 0);
        perfectPool.transfer(_player, amount);
    }

    /**
     * @notice Increases the prize pool for a specific game
     * @dev Transfers USDC from caller to contract and updates pot
     * @param _gameYear Tournament year to increase pot for
     * @param _amount Amount of USDC to add to the pot
     */
    function increaseGamePot(uint256 _gameYear, uint256 _amount) public {
        USDC.transferFrom(msg.sender, address(this), _amount);

        (
            uint256 pot,
            uint8 maxScore,
            uint256 potClaimed,
            bool claimEnabled,
            uint256 tokensIterationIndex
        ) = ticketStorage.getGame(poolId, _gameYear);

        ticketStorage.updateGame(
            poolId,
            _gameYear,
            pot + _amount,
            maxScore,
            potClaimed,
            claimEnabled,
            tokensIterationIndex
        );
    }

    /**
     * @notice Returns the metadata URI for a token
     * @dev Overrides ERC721 tokenURI function
     * @param _tokenId Token ID to get metadata for
     * @return URI containing the token's metadata
     */
    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        _requireOwned(_tokenId);

        INftMetadata nftMetadata = INftMetadata(
            gameDeployer.contracts("OM_METADATA")
        );
        return
            nftMetadata.buildMetadata(
                poolId,
                ticketStorage.getTokenGameYear(poolId, _tokenId),
                _tokenId
            );
    }

    /**
     * @notice Retrieves the bracket predictions for a token
     * @param _tokenId Token ID to get predictions for
     * @return Array of 63 team selections
     */
    function getBetData(
        uint256 _tokenId
    ) public view returns (uint8[63] memory) {
        return ticketStorage.getNftBet(poolId, _tokenId);
    }

    /**
     * @notice Gets the tournament year for a token
     * @param _tokenId Token ID to query
     * @return Tournament year the token is associated with
     */
    function getGameYear(uint256 _tokenId) public view returns (uint256) {
        return ticketStorage.getTokenGameYear(poolId, _tokenId);
    }

    /**
     * @notice Validates a bracket against tournament results
     * @dev Compares predictions with actual results and calculates score
     * @param _tokenId Token ID to validate
     * @return validator Array indicating correct/incorrect predictions
     * @return points Total score achieved
     */
    function betValidator(
        uint256 _tokenId
    ) public view returns (uint8[63] memory validator, uint8 points) {
        uint8[63] memory bets = ticketStorage.getNftBet(poolId, _tokenId);
        uint8[63] memory results = gameDeployer.getFinalResult(
            ticketStorage.getTokenGameYear(poolId, _tokenId)
        );

        return OnchainMadnessLib.validateAndScore(bets, results);
    }

    /**
     * @notice Gets team symbols for a token's predictions
     * @param _tokenId Token ID to get symbols for
     * @return Array of 63 team symbols
     */
    function getTeamSymbols(
        uint256 _tokenId
    ) public view returns (string[63] memory) {
        return
            gameDeployer.getTeamSymbols(
                ticketStorage.getTokenGameYear(poolId, _tokenId),
                ticketStorage.getNftBet(poolId, _tokenId)
            );
    }

    /**
     * @notice Calculates claimable and claimed amounts for a token
     * @param _tokenId Token ID to check
     * @return amountToClaim Amount available to claim
     * @return amountClaimed Amount already claimed
     */
    function amountPrizeClaimed(
        uint256 _tokenId
    ) public view returns (uint256 amountToClaim, uint256 amountClaimed) {
        uint256 _gameYear = ticketStorage.getTokenGameYear(poolId, _tokenId);
        (, uint8 score) = betValidator(_tokenId);
        (uint256 pot, , uint256 potClaimed, , ) = ticketStorage.getGame(
            poolId,
            _gameYear
        );

        return (
            OnchainMadnessLib.calculatePrize(
                pot,
                potClaimed,
                ticketStorage.getScoreBetQty(poolId, _gameYear, score)
            ),
            ticketStorage.getTokenClaimed(poolId, _tokenId)
        );
    }

    /**
     * @notice Gets total potential payout for a game
     * @param gameYear Tournament year to check
     * @return payout Total amount in the prize pool
     */
    function potentialPayout(
        uint256 gameYear
    ) public view returns (uint256 payout) {
        (uint256 pot, , , , ) = ticketStorage.getGame(poolId, gameYear);
        return pot;
    }

    /**
     * @notice Gets total number of players in a game
     * @param gameYear Tournament year to check
     * @return players Number of minted tickets for the game
     */
    function playerQuantity(
        uint256 gameYear
    ) public view returns (uint256 players) {
        return ticketStorage.getGameTokens(poolId, gameYear).length;
    }

    /**
     * @notice Validates a bracket and returns score
     * @param _tokenId Token ID to validate
     * @return validator Array indicating correct/incorrect predictions
     * @return points Total score achieved
     */
    function validateTicket(
        uint256 _tokenId
    ) public view returns (uint8[63] memory validator, uint8 points) {
        uint8[63] memory bets = ticketStorage.getNftBet(poolId, _tokenId);
        uint8[63] memory results = gameDeployer.getFinalResult(
            ticketStorage.getTokenGameYear(poolId, _tokenId)
        );

        return OnchainMadnessLib.validateAndScore(bets, results);
    }
}
