// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOnchainMadnessFactory {
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

    function getAllTeamIds(
        uint256 year,
        bytes32 _region
    ) external view returns (uint8[16] memory);

    function lastCreatedTournament() external view returns (uint256);

    function isFinished(uint256 year) external view returns (bool);

    function paused() external view returns (bool);

    function contracts(string memory _name) external view returns (address);

    function owner() external view returns (address);
}