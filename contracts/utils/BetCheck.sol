// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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

    function owner() external view returns (address);
}

contract BetCheck {
    IOnchainMadnessFactory public factory;
    bytes32 public constant EAST = keccak256("EAST");
    bytes32 public constant SOUTH = keccak256("SOUTH");
    bytes32 public constant WEST = keccak256("WEST");
    bytes32 public constant MIDWEST = keccak256("MIDWEST");

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

    function getBetResults(
        uint256 year,
        uint8[63] memory bets
    )
        public
        view
        returns (
            string[63] memory betTeamNames,
            uint8[63] memory betResults,
            uint8 points
        )
    {
        points = 0;
        string[63] memory _betTeamNames;
        uint8[63] memory _betResults;

        points = regionCheck(
            factory.getRegion(year, EAST),
            bets,
            0,
            points,
            year,
            _betTeamNames,
            _betResults
        );
        points = regionCheck(
            factory.getRegion(year, WEST),
            bets,
            15,
            points,
            year,
            _betTeamNames,
            _betResults
        );
        points = regionCheck(
            factory.getRegion(year, SOUTH),
            bets,
            30,
            points,
            year,
            _betTeamNames,
            _betResults
        );
        points = regionCheck(
            factory.getRegion(year, MIDWEST),
            bets,
            45,
            points,
            year,
            _betTeamNames,
            _betResults
        );

        (_betTeamNames, _betResults, points) = finalFourCheck(
            factory.getFinalFour(year),
            [
                _betTeamNames[14],
                _betTeamNames[29],
                _betTeamNames[44],
                _betTeamNames[59]
            ],
            bets,
            _betTeamNames,
            _betResults,
            points,
            year
        );

        betTeamNames = _betTeamNames;
        betResults = _betResults;
    }

    function regionCheck(
        IOnchainMadnessFactory.Region memory region,
        uint8[63] memory bets,
        uint8 start,
        uint8 points,
        uint256 year,
        string[63] memory betTeamNames,
        uint8[63] memory betResults
    ) internal view returns (uint8) {
        uint8[8] memory round2Teams;
        uint8[4] memory round3Teams;
        uint8[2] memory championshipTeams;

        // Process Round 1 (8 matches)
        for (uint8 i = 0; i < 8; i++) {
            (
                betTeamNames[start + i],
                betResults[start + i]
            ) = betResultCalculate(
                factory.getMatch(year, region.matchesRound1[i]),
                bets[start + i],
                region.teams[i * 2],
                region.teams[i * 2 + 1],
                year
            );
            if (betResults[start + i] == 1) points += 1;
            round2Teams[i] = bets[start + i] == 0
                ? region.teams[i * 2]
                : region.teams[i * 2 + 1];
        }

        // Process Round 2 (4 matches)
        for (uint8 i = 0; i < 4; i++) {
            (
                betTeamNames[start + 8 + i],
                betResults[start + 8 + i]
            ) = betResultCalculate(
                factory.getMatch(year, region.matchesRound2[i]),
                bets[start + 8 + i],
                round2Teams[i * 2],
                round2Teams[i * 2 + 1],
                year
            );
            if (betResults[start + 8 + i] == 1) points += 1;
            round3Teams[i] = bets[start + 8 + i] == 0
                ? round2Teams[i * 2]
                : round2Teams[i * 2 + 1];
        }

        // Process Round 3 (2 matches)
        for (uint8 i = 0; i < 2; i++) {
            (
                betTeamNames[start + 12 + i],
                betResults[start + 12 + i]
            ) = betResultCalculate(
                factory.getMatch(year, region.matchesRound3[i]),
                bets[start + 12 + i],
                round3Teams[i * 2],
                round3Teams[i * 2 + 1],
                year
            );
            if (betResults[start + 12 + i] == 1) points += 1;
            championshipTeams[i] = bets[start + 12 + i] == 0
                ? round3Teams[i * 2]
                : round3Teams[i * 2 + 1];
        }

        // Process Championship game
        (betTeamNames[start + 14], betResults[start + 14]) = betResultCalculate(
            factory.getMatch(year, region.matchRound4),
            bets[start + 14],
            championshipTeams[0],
            championshipTeams[1],
            year
        );
        if (betResults[start + 14] == 1) points += 1;

        return points;
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

    /** POINTS CHECK **/
    function getBetPoints(
        uint256 year,
        uint8[63] memory bets
    ) public view returns (uint8[63] memory betResults, uint8 points) {
        points = 0;
        uint8[63] memory _betResults;

        points = regionPointsCheck(
            factory.getRegion(year, EAST),
            bets,
            0,
            points,
            year,
            _betResults
        );
        points = regionPointsCheck(
            factory.getRegion(year, WEST),
            bets,
            15,
            points,
            year,
            _betResults
        );
        points = regionPointsCheck(
            factory.getRegion(year, SOUTH),
            bets,
            30,
            points,
            year,
            _betResults
        );
        points = regionPointsCheck(
            factory.getRegion(year, MIDWEST),
            bets,
            45,
            points,
            year,
            _betResults
        );

        (_betResults, points) = finalFourPointsCheck(
            factory.getFinalFour(year),
            bets,
            _betResults,
            points,
            year
        );

        betResults = _betResults;
    }

    function regionPointsCheck(
        IOnchainMadnessFactory.Region memory region,
        uint8[63] memory bets,
        uint8 start,
        uint8 points,
        uint256 year,
        uint8[63] memory betResults
    ) internal view returns (uint8) {
        uint8[8] memory round2Teams;
        uint8[4] memory round3Teams;
        uint8[2] memory championshipTeams;

        // Process Round 1 (8 matches)
        for (uint8 i = 0; i < 8; i++) {
            betResults[start + i] = betResultCalculatePoints(
                factory.getMatch(year, region.matchesRound1[i]),
                bets[start + i]
            );
            if (betResults[start + i] == 1) points += 1;
            round2Teams[i] = bets[start + i] == 0
                ? region.teams[i * 2]
                : region.teams[i * 2 + 1];
        }

        // Process Round 2 (4 matches)
        for (uint8 i = 0; i < 4; i++) {
            betResults[start + 8 + i] = betResultCalculatePoints(
                factory.getMatch(year, region.matchesRound2[i]),
                bets[start + 8 + i]
            );
            if (betResults[start + 8 + i] == 1) points += 1;
            round3Teams[i] = bets[start + 8 + i] == 0
                ? round2Teams[i * 2]
                : round2Teams[i * 2 + 1];
        }

        // Process Round 3 (2 matches)
        for (uint8 i = 0; i < 2; i++) {
            betResults[start + 12 + i] = betResultCalculatePoints(
                factory.getMatch(year, region.matchesRound3[i]),
                bets[start + 12 + i]
            );
            if (betResults[start + 12 + i] == 1) points += 1;
            championshipTeams[i] = bets[start + 12 + i] == 0
                ? round3Teams[i * 2]
                : round3Teams[i * 2 + 1];
        }

        // Process Championship game
        betResults[start + 14] = betResultCalculatePoints(
            factory.getMatch(year, region.matchRound4),
            bets[start + 14]
        );
        if (betResults[start + 14] == 1) points += 1;

        return points;
    }

    function finalFourPointsCheck(
        IOnchainMadnessFactory.FinalFour memory finalFour,
        uint8[63] memory bets,
        uint8[63] memory betResults,
        uint8 points,
        uint256 year
    ) internal view returns (uint8[63] memory, uint8) {
        IOnchainMadnessFactory.Match memory gameMatch;

        // Process Final Four semifinals (2 matches)
        for (uint8 i = 0; i < 2; i++) {
            gameMatch = factory.getMatch(year, finalFour.matchesRound1[i]);

            betResults[60 + i] = gameMatch.winner == 0
                ? 0
                : (bets[60 + i] == 0 && gameMatch.winner == gameMatch.home) ||
                    (bets[60 + i] == 1 && gameMatch.winner == gameMatch.away)
                ? 1
                : 2;

            if (betResults[60 + i] == 1) points += 1;
        }

        // Process Championship game
        gameMatch = factory.getMatch(year, finalFour.matchFinal);
        betResults[62] = gameMatch.winner == 0
            ? 0
            : (bets[62] == 0 && gameMatch.winner == gameMatch.home) ||
                (bets[62] == 1 && gameMatch.winner == gameMatch.away)
            ? 1
            : 2;

        if (betResults[62] == 1) points += 1;

        return (betResults, points);
    }

    function betResultCalculatePoints(
        IOnchainMadnessFactory.Match memory gameMatch,
        uint8 bet
    ) internal pure returns (uint8 betResult) {
        if (bet == 0) {
            if (gameMatch.winner == 0) betResult = 0;
            else if (gameMatch.winner == gameMatch.home) betResult = 1;
            else betResult = 2;
        } else {
            if (gameMatch.winner == 0) betResult = 0;
            else if (gameMatch.winner == gameMatch.away) betResult = 1;
            else betResult = 2;
        }
    }
}
