// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../interfaces/IOnchainMadnessFactory.sol";
import "../interfaces/IERC20.sol";

interface INftMetadata {
    function buildMetadata(
        uint256 _gameYear,
        uint256 _tokenId
    ) external view returns (string memory);
}

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
}

contract OnchainMadnessTicket is ERC721, ReentrancyGuard {
    event BetPlaced(
        address indexed _player,
        uint256 indexed _gameYear,
        uint256 indexed _tokenId
    );
    event GamePotPlaced(uint256 indexed _gameYear, uint256 _pot);
    event GamePotIncreased(uint256 indexed _gameYear, uint256 _amount);
    event PrizeClaimed(uint256 indexed _tokenId, uint256 _amount);
    event PriceChanged(uint256 _newPrice);

    uint256 private _nextTokenId;
    uint256 public poolNumber;
    uint256 public price;
    address public nftDeployer;
    address public creator;
    bool public isPrivatePool;
    bool public isProtocolPool;
    bytes32 private pin;

    IOnchainMadnessFactory public gameDeployer;
    IPerfectPool private perfectPool;
    IERC20 private USDC;
    struct Game {
        uint256 pot;
        uint256 maxScore;
        uint256 potClaimed;
        bool claimEnabled;
        mapping(uint256 => uint256) scoreBetQty;
        uint256[] tokens; // Array to store all token IDs for this game
        uint256 tokensIterationIndex; // Index to track iteration progress
    }

    mapping(uint256 => Game) private games;

    mapping(uint256 => uint256) private tokenToGameYear;
    mapping(uint256 => uint8[63]) private nftBet;
    mapping(bytes32 => uint256[]) private betCodeToTokenIds;
    mapping(uint256 => uint256) private tokenClaimed;
    mapping(address => uint256) public ppShare;

    modifier onlyNftDeployer() {
        require(msg.sender == nftDeployer, "Caller is not nft deployer");
        _;
    }

    constructor() ERC721("OnchainMadnessTicket", "OMT") {
        _nextTokenId = 1;
        price = 10 * 10 ** USDC.decimals();
    }

    function initialize(
        address _nftDeployer,
        address _gameDeployer,
        address _token,
        uint256 _poolNumber,
        address _creator,
        bool _isProtocolPool,
        bool _isPrivatePool,
        string calldata _pin
    ) public {
        gameDeployer = IOnchainMadnessFactory(_gameDeployer);
        USDC = IERC20(_token);
        poolNumber = _poolNumber;
        nftDeployer = _nftDeployer;
        creator = _creator;
        isProtocolPool = _isProtocolPool;
        isPrivatePool = _isPrivatePool;
        pin = keccak256(abi.encodePacked(_pin));
        perfectPool = IPerfectPool(gameDeployer.contracts("PERFECTPOOL"));
    }

    /**
     * @dev Change the price of the ticket. Only callable by the admin.
     * @param _newPrice The new price of the ticket.
     */
    function changePrice(uint256 _newPrice) external onlyNftDeployer {
        price = _newPrice;
        emit PriceChanged(_newPrice);
    }

    /**
     * @dev Mint a new ticket and place a bet.
     * @param _gameYear The ID of the game to bet on.
     * @param bets The array of bets for the game.
     */
    function safeMint(
        address _player,
        uint256 _gameYear,
        uint8[63] memory bets,
        string calldata _pin
    ) external onlyNftDeployer {
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

        //pool Slice is 10% of the price
        uint256 poolSlice = price / 10;
        uint256 _gamePot = price - poolSlice;

        uint8[] memory percentages = new uint8[](1);
        percentages[0] = 100;

        address[] memory recipients = new address[](1);
        recipients[0] = address(this);

        USDC.approve(address(perfectPool), poolSlice);
        uint256 balanceBefore = perfectPool.balanceOf(address(this));
        perfectPool.increasePool(poolSlice, percentages, recipients);

        uint256 shareAmount = perfectPool.balanceOf(address(this)) -
            balanceBefore;

        ppShare[gameDeployer.contracts("TREASURY")] += (shareAmount / 2);
        ppShare[isProtocolPool ? _player : creator] += (shareAmount -
            (shareAmount / 2));

        games[_gameYear].pot += _gamePot;
        tokenToGameYear[_nextTokenId] = _gameYear;
        nftBet[_nextTokenId] = bets;

        // Add token to game's token array
        games[_gameYear].tokens.push(_nextTokenId);

        _safeMint(_player, _nextTokenId);
        emit BetPlaced(_player, _gameYear, _nextTokenId);
        _nextTokenId++;
    }

    /**
     * @dev Iterates through the next token in a game year, updating score statistics
     * @param _gameYear The year of the game to iterate
     * @return success Whether there are more tokens to iterate
     * @return score The score of the current token
     */
    function iterateNextToken(
        uint256 _gameYear
    ) external onlyNftDeployer returns (bool success, uint8 score) {
        Game storage game = games[_gameYear];

        // Check if we have finished iterating all tokens
        if (game.tokensIterationIndex >= game.tokens.length) {
            return (false, 0);
        }

        // Get the current token ID and validate its bets
        uint256 currentTokenId = game.tokens[game.tokensIterationIndex];
        (, score) = betValidator(currentTokenId);

        // Update score statistics
        game.scoreBetQty[score]++;

        // Update max score if this is higher
        if (score > game.maxScore) {
            game.maxScore = score;
        }

        if (score == 64) {
            perfectPool.increaseWinnersQty(_gameYear);
        }

        // Move to next token
        game.tokensIterationIndex++;

        // Check if we have finished iterating all tokens and activates claim
        if (game.tokensIterationIndex >= game.tokens.length) {
            game.claimEnabled = true;
        }

        return (true, score);
    }

    /**
     * @dev Claim the tokens won by a ticket. Only callable by the owner of the ticket.
     * @param _tokenId The ID of the ticket to claim tokens from.
     */
    function claimPrize(address _player, uint256 _tokenId) external nonReentrant onlyNftDeployer {
        require(!gameDeployer.paused(), "Game paused.");
        require(tokenClaimed[_tokenId] == 0, "Tokens already claimed.");
        require(
            games[tokenToGameYear[_tokenId]].claimEnabled,
            "Game not finished."
        );

        (, uint8 status) = abi.decode(
            gameDeployer.getGameStatus(tokenToGameYear[_tokenId]),
            (uint8, uint8)
        );
        require(status == 3, "Game not finished.");

        uint256 _gameYear = tokenToGameYear[_tokenId];
        (, uint8 tokenScore) = betValidator(_tokenId);

        require(
            games[_gameYear].maxScore != tokenScore,
            "You are not a winner"
        );

        uint256 amount = games[_gameYear].pot /
            games[_gameYear].scoreBetQty[tokenScore];
        uint256 availableClaim = games[_gameYear].pot -
            games[_gameYear].potClaimed;

        // This is to avoid rounding errors that could leave some tokens unclaimed
        if (availableClaim < amount) {
            amount = availableClaim;
        }

        games[_gameYear].potClaimed += amount;
        USDC.transfer(_player, amount);
        tokenClaimed[_tokenId] = amount;

        emit PrizeClaimed(_tokenId, amount);
    }

    /**
     * @dev Claim the ppShare tokens owned by the caller. Only callable by the caller itself
     */
    function claimPPShare(address _player) external onlyNftDeployer{
        require(ppShare[_player] > 0, "No ppShare tokens to claim.");
        perfectPool.transfer(_player, ppShare[_player]);
        ppShare[_player] = 0;
    }

    /**
     * @dev Increase the pot by a certain amount. Only callable by the admin.
     * @param _gameYear The ID of the game to set the pot for.
     * @param _amount The amount to increase the pot by.
     */
    function increaseGamePot(
        uint256 _gameYear,
        uint256 _amount
    ) public {
        USDC.transferFrom(msg.sender, address(this), _amount);
        games[_gameYear].pot += _amount;
        emit GamePotIncreased(_gameYear, _amount);
    }

    /**
     * @dev Get the token URI for a specific token.
     * @param _tokenId The ID of the token.
     * @return The token URI.
     */
    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(ownerOf(_tokenId) != address(0), "ERC721: invalid token ID");

        INftMetadata nftMetadata = INftMetadata(
            gameDeployer.contracts("MM_METADATA")
        );
        return nftMetadata.buildMetadata(tokenToGameYear[_tokenId], _tokenId);
    }

    /**
     * @dev Get the bet data for a specific token.
     * @param _tokenId The ID of the token.
     * @return The array of bets for the token.
     */
    function getBetData(
        uint256 _tokenId
    ) public view returns (uint8[63] memory) {
        return nftBet[_tokenId];
    }

    /**
     * @dev Get the game ID for a specific token.
     * @param _tokenId The ID of the token.
     * @return The ID of the game the token is betting on.
     */
    function getGameYear(uint256 _tokenId) public view returns (uint256) {
        return tokenToGameYear[_tokenId];
    }

    /**
     * @dev Validate the bets for a specific token.
     * @param _tokenId The ID of the token.
     * @return validator The array of validation results for the bets.
     * @return points The number of points won by the player
     */
    function betValidator(
        uint256 _tokenId
    ) public view returns (uint8[63] memory validator, uint8 points) {
        uint8[63] memory bets = nftBet[_tokenId];
        uint8[63] memory results = gameDeployer.getFinalResult(tokenToGameYear[_tokenId]);

        for (uint256 i = 0; i < 63; i++) {
            if (results[i] == 0) {
                validator[i] = 0;
            } else {
                if (bets[i] == results[i]) {
                    points++;
                    validator[i] = 1;
                } else {
                    validator[i] = 2;
                }
            }
        }
        return (validator, points);
    }

    /**
     * @dev Get the symbols for the tokens bet on a specific token.
     * @param _tokenId The ID of the token.
     */
    function getTeamSymbols(
        uint256 _tokenId
    ) public view returns (string[63] memory) {
        return
            gameDeployer.getTeamSymbols(tokenToGameYear[_tokenId], nftBet[_tokenId]);
    }

    /**
     * @dev Get the amount to claim and the amount claimed for a specific token.
     * @param _tokenId The ID of the token.
     * @return amountToClaim The amount of tokens to claim.
     * @return amountClaimed The amount of tokens already claimed.
     */
    function amountPrizeClaimed(
        uint256 _tokenId
    ) public view returns (uint256 amountToClaim, uint256 amountClaimed) {
        uint256 _gameYear = tokenToGameYear[_tokenId];
        (, uint8 score) = betValidator(_tokenId);
        return (
            games[_gameYear].pot / games[_gameYear].scoreBetQty[score],
            tokenClaimed[_tokenId]
        );
    }

    /**
     * @dev Get the potential payout for a specific game.
     * @param gameYear The ID of the game
     */
    function potentialPayout(
        uint256 gameYear
    ) public view returns (uint256 payout) {
        return games[gameYear].pot;
    }

    /**
     * @dev Get the quantity of players for a specific game.
     * @param gameYear The ID of the game
     */
    function playerQuantity(
        uint256 gameYear
    ) public view returns (uint256 players) {
        return games[gameYear].tokens.length;
    }

    /**
     * @dev Get the token IDs for a specific bet code.
     * @param betCode The bet code to get the token IDs for.
     * @return The array of token IDs for the bet code.
     */
    function getBetCodeToTokenIds(
        bytes32 betCode
    ) public view returns (uint256[] memory) {
        return betCodeToTokenIds[betCode];
    }
}
