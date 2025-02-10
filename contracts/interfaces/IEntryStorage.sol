// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IEntryStorage {
    function initialize(uint256 poolId) external;

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
        );

    function updateGame(
        uint256 poolId,
        uint256 gameYear,
        uint256 pot,
        uint256 potClaimed,
        bool claimEnabled
    ) external;

    function setTokenGameYear(
        uint256 poolId,
        uint256 tokenId,
        uint256 gameYear
    ) external;

    function getTokenGameYear(
        uint256 poolId,
        uint256 tokenId
    ) external view returns (uint256);

    function setNftBet(
        uint256 poolId,
        uint256 tokenId,
        uint8[63] memory bets
    ) external;

    function getNftBet(
        uint256 poolId,
        uint256 tokenId
    ) external view returns (uint8[63] memory);

    function setTokenClaimed(
        uint256 poolId,
        uint256 tokenId,
        uint256 amount
    ) external;

    function getTokenClaimed(
        uint256 poolId,
        uint256 tokenId
    ) external view returns (uint256);

    function setPpShare(
        uint256 poolId,
        address user,
        uint256 amount,
        uint256 gameYear
    ) external;

    function getPpShare(
        uint256 poolId,
        address user,
        uint256 gameYear
    ) external view returns (uint256);

    function setScoreBetQty(
        uint256 poolId,
        uint256 gameYear,
        uint256 score,
        uint256 qty
    ) external;

    function getScoreBetQty(
        uint256 poolId,
        uint256 gameYear,
        uint256 score
    ) external view returns (uint256);

    function addGameToken(
        uint256 poolId,
        uint256 gameYear,
        uint256 tokenId
    ) external;

    function getGameTokens(
        uint256 poolId,
        uint256 gameYear
    ) external view returns (uint256[] memory);

    function batchUpdateGameDataAndShares(
        uint256 poolId,
        uint256 gameYear,
        uint256 tokenId,
        uint256 shareAmount,
        address recipient,
        bytes memory dataUpdate
    ) external;

    function getCurrentToken(
        uint256 poolId,
        uint256 gameYear
    ) external returns (uint256 currentTokenId, bool hasNext);

    function updateScore(
        uint256 poolId,
        uint256 gameYear,
        uint8 score
    ) external;

    function hasMoreTokens(
        uint256 poolId,
        uint256 gameYear
    ) external view returns (bool hasNext);
}
