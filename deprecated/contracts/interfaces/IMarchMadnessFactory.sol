// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarchMadnessFactory {
    function getGameStatus(
        uint256 _gameYear
    ) external view returns (bytes memory);

    function getFinalResult(
        uint256 _gameYear
    ) external view returns (uint8[63] memory);

    function getTeamSymbols(
        uint256 year,
        uint8[63] memory teamIds
    ) external view returns (string[63] memory);

    function paused() external view returns (bool);
}