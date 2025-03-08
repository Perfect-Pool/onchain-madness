// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IOnchainMadnessFactory.sol";

contract RegionCheck {
    IOnchainMadnessFactory public factory;

    modifier onlyAdmin() {
        require(factory.owner() == msg.sender, "Caller is not admin");
        _;
    }

    constructor(address _factory) {
        factory = IOnchainMadnessFactory(_factory);
    }

    function setDeployer(address _factory) public onlyAdmin {
        factory = IOnchainMadnessFactory(_factory);
    }

    function regionCheck(
        IOnchainMadnessFactory.Region memory region,
        uint8[63] memory bets,
        uint8[4] memory start,
        uint8 points,
        uint256 year,
        string[63] memory betTeamNames,
        uint8[63] memory betResults
    ) internal view returns (string[63] memory, uint8[63] memory, uint8) {
        uint8[8] memory round2Teams;
        uint8[4] memory round3Teams;
        uint8[2] memory championshipTeams;

        // Process Round 1 (8 matches)
        for (uint8 i = 0; i < 8; i++) {
            (
                betTeamNames[start[0] + i],
                betResults[start[0] + i]
            ) = betResultCalculate(
                factory.getMatch(year, region.matchesRound1[i]),
                bets[start[0] + i],
                region.teams[i * 2],
                region.teams[i * 2 + 1],
                year
            );
            if (betResults[start[0] + i] == 1) points += 1;
            round2Teams[i] = bets[start[0] + i] == 0
                ? region.teams[i * 2]
                : region.teams[i * 2 + 1];
        }

        // Process Round 2 (4 matches)
        for (uint8 i = 0; i < 4; i++) {
            (
                betTeamNames[start[1] + i],
                betResults[start[1] + i]
            ) = betResultCalculate(
                factory.getMatch(year, region.matchesRound2[i]),
                bets[start[1] + i],
                round2Teams[i * 2],
                round2Teams[i * 2 + 1],
                year
            );
            if (betResults[start[1] + i] == 1) points += 1;
            round3Teams[i] = bets[start[1] + i] == 0
                ? round2Teams[i * 2]
                : round2Teams[i * 2 + 1];
        }

        // Process Round 3 (2 matches)
        for (uint8 i = 0; i < 2; i++) {
            (
                betTeamNames[start[2] + i],
                betResults[start[2] + i]
            ) = betResultCalculate(
                factory.getMatch(year, region.matchesRound3[i]),
                bets[start[2] + i],
                round3Teams[i * 2],
                round3Teams[i * 2 + 1],
                year
            );
            if (betResults[start[2] + i] == 1) points += 1;
            championshipTeams[i] = bets[start[2] + i] == 0
                ? round3Teams[i * 2]
                : round3Teams[i * 2 + 1];
        }

        // Process Championship game
        (betTeamNames[start[3]], betResults[start[3]]) = betResultCalculate(
            factory.getMatch(year, region.matchRound4),
            bets[start[3]],
            championshipTeams[0],
            championshipTeams[1],
            year
        );
        if (betResults[start[3]] == 1) points += 1;

        return (betTeamNames, betResults, points);
    }

    function finalFourCheck(
        IOnchainMadnessFactory.FinalFour memory finalFour,
        string[4] memory regionWinners,
        uint8[63] memory bets,
        string[63] memory betTeamNames,
        uint8[63] memory betResults,
        uint8 points,
        uint256 year
    ) internal view returns (string[63] memory, uint8[63] memory, uint8) {
        IOnchainMadnessFactory.Match memory gameMatch;
        string[2] memory finalTeams;

        // Process Final Four semifinals (2 matches)
        for (uint8 i = 0; i < 2; i++) {
            gameMatch = factory.getMatch(year, finalFour.matchesRound1[i]);
            betTeamNames[60 + i] = bets[60 + i] == 0
                ? regionWinners[i * 2] // East/South
                : regionWinners[i * 2 + 1]; // West/Midwest

            betResults[60 + i] = gameMatch.winner == 0
                ? 0
                : (bets[60 + i] == 0 && gameMatch.winner == gameMatch.home) ||
                    (bets[60 + i] == 1 && gameMatch.winner == gameMatch.away)
                ? 1
                : 2;

            if (betResults[60 + i] == 1) points += 1;
            finalTeams[i] = bets[60 + i] == 0
                ? regionWinners[i * 2]
                : regionWinners[i * 2 + 1];
        }

        // Process Championship game
        gameMatch = factory.getMatch(year, finalFour.matchFinal);
        betTeamNames[62] = bets[62] == 0 ? finalTeams[0] : finalTeams[1];
        betResults[62] = gameMatch.winner == 0
            ? 0
            : (bets[62] == 0 && gameMatch.winner == gameMatch.home) ||
                (bets[62] == 1 && gameMatch.winner == gameMatch.away)
            ? 1
            : 2;

        if (betResults[62] == 1) points += 1;

        return (betTeamNames, betResults, points);
    }

    function betResultCalculate(
        IOnchainMadnessFactory.Match memory gameMatch,
        uint8 bet, // from uint8[63] bets as 0 or 1 values
        uint8 player1,
        uint8 player2,
        uint256 year
    ) internal view returns (string memory betTeamName, uint8 betResult) {
        if (bet == 0) {
            betTeamName = factory.getTeamName(year, player1);
            if (gameMatch.winner == 0) betResult = 0;
            else if (gameMatch.winner == gameMatch.home) betResult = 1;
            else betResult = 2;
        } else {
            betTeamName = factory.getTeamName(year, player2);
            if (gameMatch.winner == 0) betResult = 0;
            else if (gameMatch.winner == gameMatch.away) betResult = 1;
            else betResult = 2;
        }
    }
}
