// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../interfaces/IMarchMadnessFactory.sol";
import "../interfaces/IGamesHub.sol";

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);
}

interface INftMetadata {
    function buildMetadata(
        uint256 _gameYear,
        uint256 _tokenId
    ) external view returns (string memory);
}

contract OnchainMadnessTicket is ERC721, ReentrancyGuard {
    event BetPlaced(
        address indexed _player,
        uint256 indexed _gameYear,
        uint256 indexed _tokenId,
        bytes32 _betCode
    );
    event GamePotPlaced(uint256 indexed _gameYear, uint256 _pot);
    event GamePotDismissed(uint256 indexed _gameYear);
    event NoWinners(uint256 indexed _gameYear);
    event PrizeClaimed(uint256 indexed _tokenId, uint256 _amount);
    event PriceChanged(uint256 _newPrice);
    event ProtocolFeeChanged(uint8 _newFee);

    uint256 private _nextTokenId;
    IGamesHub public gamesHub;
    IERC20 public token;

    uint256 public jackpot;
    uint256 public price;
    uint8 public protocolFee = 100;

    mapping(uint256 => uint256) private tokenToGameYear;
    mapping(uint256 => uint8[63]) private nftBet;
    mapping(bytes32 => uint256[]) private betCodeToTokenIds;
    mapping(bytes32 => uint256) private betQty;
    mapping(bytes32 => uint256) private gamePot;
    mapping(uint256 => uint256) private gameYearPot;
    mapping(bytes32 => uint256) private gamePotClaimed;
    mapping(uint256 => uint256) private gameAllBets;
    mapping(uint256 => uint256) private tokenClaimed;

    modifier onlyAdmin() {
        require(
            gamesHub.checkRole(gamesHub.ADMIN_ROLE(), msg.sender),
            "Caller is not admin"
        );
        _;
    }

    modifier onlyGameContract() {
        require(
            msg.sender == gamesHub.games(keccak256("MM_DEPLOYER")),
            "Caller is not game contract"
        );
        _;
    }

    constructor(address _gamesHub) ERC721("OnchainMadnessTicket", "OMT") {
        gamesHub = IGamesHub(_gamesHub);
        token = IERC20(gamesHub.helpers(keccak256("TOKEN")));

        _nextTokenId = 1;
        jackpot = 0;
        price = 10 * 10 ** token.decimals();
    }

    /**
     * @dev Change the token and the price of the ticket. Only callable by the admin.
     * @param _token The address of the new token contract.
     * @param _newPrice The new price of the ticket.
     */
    function changeToken(address _token, uint256 _newPrice) public onlyAdmin {
        token = IERC20(_token);
        price = _newPrice;
    }

    /**
     * @dev Change the price of the ticket. Only callable by the admin.
     * @param _newPrice The new price of the ticket.
     */
    function changePrice(uint256 _newPrice) public onlyAdmin {
        price = _newPrice;
        emit PriceChanged(_newPrice);
    }

    /**
     * @dev Change the protocol fee. Only callable by the admin.
     * @param _newFee The new protocol fee.
     */
    function changeProtocolFee(uint8 _newFee) public onlyAdmin {
        protocolFee = _newFee;
        emit ProtocolFeeChanged(_newFee);
    }

    /**
     * @dev Change the GamesHub contract address. Only callable by the admin.
     * @param _gamesHub The address of the new GamesHub contract.
     */
    function changeGamesHub(address _gamesHub) public onlyAdmin {
        gamesHub = IGamesHub(_gamesHub);
    }

    /**
     * @dev Mint a new ticket and place a bet.
     * @param _gameYear The ID of the game to bet on.
     * @param bets The array of bets for the game.
     */
    function safeMint(uint256 _gameYear, uint8[63] memory bets) public {
        IMarchMadnessFactory madnessContract = IMarchMadnessFactory(
            gamesHub.games(keccak256("MM_DEPLOYER"))
        );
        require(!madnessContract.paused(), "Game paused.");
        
        (, uint8 status) = abi.decode(
            madnessContract.getGameStatus(_gameYear),
            (uint8, uint8)
        );
        require(status == 1, "Bets closed.");

        uint256 _fee = (price * protocolFee) / 1000;
        uint256 _gamePot = price - _fee;
        token.transferFrom(msg.sender, address(this), _gamePot);
        token.transfer(gamesHub.helpers(keccak256("TREASURY")), _fee);

        bytes32 betCode = keccak256(abi.encodePacked(_gameYear, bets));
        gamePot[betCode] += _gamePot;
        gameYearPot[_gameYear] += _gamePot;
        tokenToGameYear[_nextTokenId] = _gameYear;
        nftBet[_nextTokenId] = bets;
        betQty[betCode]++;
        gameAllBets[_gameYear]++;
        betCodeToTokenIds[betCode].push(_nextTokenId);

        _safeMint(msg.sender, _nextTokenId);
        emit BetPlaced(msg.sender, _gameYear, _nextTokenId, betCode);
        _nextTokenId++;
    }

    /**
     * @dev Claim the tokens won by a ticket. Only callable by the owner of the ticket.
     * @param _tokenId The ID of the ticket to claim tokens from.
     */
    function claimTokens(uint256 _tokenId) public nonReentrant {
        IMarchMadnessFactory madnessContract = IMarchMadnessFactory(
            gamesHub.games(keccak256("MM_DEPLOYER"))
        );
        require(!madnessContract.paused(), "Game paused.");
        require(tokenClaimed[_tokenId] == 0, "Tokens already claimed.");

        (, uint8 status) = abi.decode(
            madnessContract.getGameStatus(tokenToGameYear[_tokenId]),
            (uint8, uint8)
        );
        require(status == 3, "Game not finished.");

        uint256 _gameYear = tokenToGameYear[_tokenId];
        bytes32 betCode = keccak256(
            abi.encodePacked(
                _gameYear,
                madnessContract.getFinalResult(_gameYear)
            )
        );

        require(betQty[betCode] > 0, "No winners.");
        require(
            gamePotClaimed[betCode] < gamePot[betCode],
            "Game pot dismissed."
        );

        uint256 amount = gamePot[betCode] / betQty[betCode];
        uint256 availableClaim = gamePot[betCode] - gamePotClaimed[betCode];

        // This is to avoid rounding errors that could leave some tokens unclaimed
        if (availableClaim < amount) {
            amount = availableClaim;
        }

        gamePotClaimed[betCode] += amount;
        token.transfer(msg.sender, amount);
        tokenClaimed[_tokenId] = amount;

        emit PrizeClaimed(_tokenId, amount);
    }

    /**
     * @dev Set the game pot for a specific game. Only callable by the game contract.
     * @param _gameYear The ID of the game to set the pot for.
     * @param betCode The bet code for the game.
     */
    function setGamePot(
        uint256 _gameYear,
        bytes32 betCode
    ) public onlyGameContract {
        if (betQty[betCode] > 0) {
            gamePot[betCode] += jackpot;
            jackpot = 0;
            emit GamePotPlaced(_gameYear, gamePot[betCode]);
            return;
        }
        jackpot += gamePot[betCode];
        gamePot[betCode] = 0;
        emit NoWinners(_gameYear);
    }

    /**
     * @dev Dismiss the game pot for a specific game. Only callable by the game contract.
     * @param _gameYear The ID of the game to dismiss the pot for.
     */
    function dismissGamePot(
        uint256 _gameYear,
        bytes32 betCode
    ) public onlyGameContract {
        uint256 availableClaim = gamePot[betCode] - gamePotClaimed[betCode];
        if (availableClaim == 0) {
            return;
        }

        uint256 protocolSlice = availableClaim / 2;
        if (protocolSlice > 0) {
            token.transfer(
                gamesHub.helpers(keccak256("TREASURY")),
                protocolSlice
            );
        }

        jackpot += (availableClaim - protocolSlice);
        gamePotClaimed[betCode] = gamePot[betCode];

        emit GamePotDismissed(_gameYear);
    }

    /**
     * @dev Increase the pot by a certain amount. Only callable by the admin.
     * @param _amount The amount to increase the pot by.
     */
    function increaseJackpot(uint256 _amount) public onlyAdmin {
        token.transferFrom(msg.sender, address(this), _amount);
        jackpot += _amount;
    }

    /**
     * @dev Get the token URI for a specific token.
     * @param _tokenId The ID of the token.
     * @return The token URI.
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(_exists(_tokenId), "Token not minted.");

        INftMetadata nftMetadata = INftMetadata(
            gamesHub.helpers(keccak256("MM_METADATA"))
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
     * @return The array of validation results for the bets.
     */
    function betValidator(
        uint256 _tokenId
    ) public view returns (uint8[63] memory) {
        uint8[63] memory bets = nftBet[_tokenId];
        uint8[63] memory results = IMarchMadnessFactory(
            gamesHub.games(keccak256("MM_DEPLOYER"))
        ).getFinalResult(
            tokenToGameYear[_tokenId]
        );
        uint8[63] memory validator;

        for (uint256 i = 0; i < 63; i++) {
            if (results[i] == 0) {
                validator[i] = 0;
            } else {
                validator[i] = bets[i] == results[i] ? 1 : 2;
            }
        }
        return validator;
    }

    /**
     * @dev Get the symbols for the tokens bet on a specific token.
     * @param _tokenId The ID of the token.
     */
    function getTeamSymbols(
        uint256 _tokenId
    ) public view returns (string[63] memory) {
        return IMarchMadnessFactory(
            gamesHub.games(keccak256("MM_DEPLOYER"))
        ).getTeamSymbols(
                tokenToGameYear[_tokenId],
                nftBet[_tokenId]
            );
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
        IMarchMadnessFactory madnessContract = IMarchMadnessFactory(
            gamesHub.games(keccak256("MM_DEPLOYER"))
        );
        return (
            gamePot[
                keccak256(
                    abi.encodePacked(
                        tokenToGameYear[_tokenId],
                        madnessContract.getFinalResult(
                            tokenToGameYear[_tokenId]
                        )
                    )
                )
            ] /
                betQty[
                    keccak256(
                        abi.encodePacked(
                            tokenToGameYear[_tokenId],
                            madnessContract.getFinalResult(
                                tokenToGameYear[_tokenId]
                            )
                        )
                    )
                ],
            tokenClaimed[_tokenId]
        );
    }

    /**
     * #dev Get the potential payout for a specific game.
     * @param gameYear The ID of the game
     */
    function potentialPayout(
        uint256 gameYear
    ) public view returns (uint256 payout) {
        return jackpot + gameYearPot[gameYear];
    }

    /**
     * @dev Get the quantity of players for a specific game.
     * @param gameYear The ID of the game
     */
    function playerQuantity(
        uint256 gameYear
    ) public view returns (uint256 players) {
        return gameAllBets[gameYear];
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
