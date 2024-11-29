// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOnchainMadnessTicket {
    // View functions
    function tokenToGameYear(uint256 tokenId) external view returns (uint256);

    function nftBet(uint256 tokenId) external view returns (uint8[63] memory);

    function tokenClaimed(uint256 tokenId) external view returns (uint256);

    function ppShare(address account) external view returns (uint256);

    function betValidator(
        uint256 _tokenId
    ) external view returns (uint8[63] memory validator, uint8 points);

    function getTeamSymbols(
        uint256 _tokenId
    ) external view returns (string[63] memory);

    function amountPrizeClaimed(
        uint256 _tokenId
    ) external view returns (uint256 amountToClaim, uint256 amountClaimed);

    function potentialPayout(
        uint256 gameYear
    ) external view returns (uint256 payout);

    function playerQuantity(
        uint256 gameYear
    ) external view returns (uint256 players);

    function getGameYear(uint256 _tokenId) external view returns (uint256);

    function getBetData(
        uint256 _tokenId
    ) external view returns (uint8[63] memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    // OnlyNftDeployer functions
    function safeMint(
        address _player,
        uint256 _gameYear,
        uint8[63] memory bets,
        string calldata _pin
    ) external;

    function iterateNextToken(
        uint256 _gameYear
    ) external returns (bool success, uint8 score);

    function claimPrize(
        address _player,
        uint256 _tokenId
    ) external;

    function claimPPShare(address _player) external;

    function increaseGamePot(uint256 _gameYear, uint256 _amount) external;

    function initialize(
        address _nftDeployer,
        address _gameDeployer,
        address _token,
        uint256 _poolNumber,
        address _creator,
        bool _isProtocolPool,
        bool _isPrivatePool,
        string calldata _pin
    ) external;
}
