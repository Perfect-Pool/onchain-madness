// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOnchainMadnessFactory {
    struct Match {
        uint8 home;
        uint8 away;
        uint8 winner;
        uint256 home_points;
        uint256 away_points;
    }

    struct Region {
        uint8[16] teams;
        uint8[8] matchesRound1;
        uint8[4] matchesRound2;
        uint8[2] matchesRound3;
        uint8 matchRound4;
        uint8 winner;
    }

    /**
     * @dev Represents the Final Four round
     * @param matchesRound1 Array of Final Four gameMatch IDs
     * @param matchFinal Championship gameMatch ID
     * @param winner ID of the tournament winner
     */
    struct FinalFour {
        uint8[2] matchesRound1;
        uint8 matchFinal;
        uint8 winner;
    }

    function getRegion(
        uint256 year,
        bytes32 _regionName
    ) external view returns (Region memory);

    function getMatch(
        uint256 year,
        uint8 _matchId
    ) external view returns (Match memory);

    function getTeamName(
        uint256 year,
        uint8 _teamId
    ) external view returns (string memory);

    function getFinalFour(
        uint256 year
    ) external view returns (FinalFour memory);

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
