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

    function getRegion(uint256 year, bytes32 _regionName) external view returns (Region memory);
    function getMatch(uint256 year, uint8 _matchId) external view returns (Match memory);
    function getTeamName(uint256 year, uint8 _teamId) external view returns (string memory);
    function getFinalFour(uint256 year) external view returns (FinalFour memory);
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
        uint8 matchId;
        IOnchainMadnessFactory.Match memory gameMatch;

        for (uint8 i = 0; i < 8; i++) {
            IOnchainMadnessFactory.Region memory eastRegion = factory.getRegion(year, EAST);
            IOnchainMadnessFactory.Region memory southRegion = factory.getRegion(year, SOUTH);
            IOnchainMadnessFactory.Region memory westRegion = factory.getRegion(year, WEST);
            IOnchainMadnessFactory.Region memory midwestRegion = factory.getRegion(year, MIDWEST);

            matchId = eastRegion.matchesRound1[i];
            gameMatch = factory.getMatch(year, matchId);
            betTeamNames[i] = factory.getTeamName(year, bets[i] == 1 ? gameMatch.home : gameMatch.away);
            if (gameMatch.winner == 0) betResults[i] = 0;
            else if ((gameMatch.winner == gameMatch.home && bets[i] == 1) || 
                    (gameMatch.winner == gameMatch.away && bets[i] == 2)) {
                betResults[i] = 1;
                points++;
            } else betResults[i] = 2;

            matchId = southRegion.matchesRound1[i];
            gameMatch = factory.getMatch(year, matchId);
            betTeamNames[i + 8] = factory.getTeamName(year, bets[i + 8] == 1 ? gameMatch.home : gameMatch.away);
            if (gameMatch.winner == 0) betResults[i + 8] = 0;
            else if ((gameMatch.winner == gameMatch.home && bets[i + 8] == 1) || 
                    (gameMatch.winner == gameMatch.away && bets[i + 8] == 2)) {
                betResults[i + 8] = 1;
                points++;
            } else betResults[i + 8] = 2;

            matchId = westRegion.matchesRound1[i];
            gameMatch = factory.getMatch(year, matchId);
            betTeamNames[i + 16] = factory.getTeamName(year, bets[i + 16] == 1 ? gameMatch.home : gameMatch.away);
            if (gameMatch.winner == 0) betResults[i + 16] = 0;
            else if ((gameMatch.winner == gameMatch.home && bets[i + 16] == 1) || 
                    (gameMatch.winner == gameMatch.away && bets[i + 16] == 2)) {
                betResults[i + 16] = 1;
                points++;
            } else betResults[i + 16] = 2;

            matchId = midwestRegion.matchesRound1[i];
            gameMatch = factory.getMatch(year, matchId);
            betTeamNames[i + 24] = factory.getTeamName(year, bets[i + 24] == 1 ? gameMatch.home : gameMatch.away);
            if (gameMatch.winner == 0) betResults[i + 24] = 0;
            else if ((gameMatch.winner == gameMatch.home && bets[i + 24] == 1) || 
                    (gameMatch.winner == gameMatch.away && bets[i + 24] == 2)) {
                betResults[i + 24] = 1;
                points++;
            } else betResults[i + 24] = 2;
        }

        for (uint8 i = 0; i < 4; i++) {
            IOnchainMadnessFactory.Region memory eastRegion = factory.getRegion(year, EAST);
            IOnchainMadnessFactory.Region memory southRegion = factory.getRegion(year, SOUTH);
            IOnchainMadnessFactory.Region memory westRegion = factory.getRegion(year, WEST);
            IOnchainMadnessFactory.Region memory midwestRegion = factory.getRegion(year, MIDWEST);

            matchId = eastRegion.matchesRound2[i];
            gameMatch = factory.getMatch(year, matchId);
            betTeamNames[i + 32] = factory.getTeamName(year, bets[i + 32] == 1 ? gameMatch.home : gameMatch.away);
            if (gameMatch.winner == 0) betResults[i + 32] = 0;
            else if ((gameMatch.winner == gameMatch.home && bets[i + 32] == 1) || 
                    (gameMatch.winner == gameMatch.away && bets[i + 32] == 2)) {
                betResults[i + 32] = 1;
                points++;
            } else betResults[i + 32] = 2;

            matchId = southRegion.matchesRound2[i];
            gameMatch = factory.getMatch(year, matchId);
            betTeamNames[i + 36] = factory.getTeamName(year, bets[i + 36] == 1 ? gameMatch.home : gameMatch.away);
            if (gameMatch.winner == 0) betResults[i + 36] = 0;
            else if ((gameMatch.winner == gameMatch.home && bets[i + 36] == 1) || 
                    (gameMatch.winner == gameMatch.away && bets[i + 36] == 2)) {
                betResults[i + 36] = 1;
                points++;
            } else betResults[i + 36] = 2;

            matchId = westRegion.matchesRound2[i];
            gameMatch = factory.getMatch(year, matchId);
            betTeamNames[i + 40] = factory.getTeamName(year, bets[i + 40] == 1 ? gameMatch.home : gameMatch.away);
            if (gameMatch.winner == 0) betResults[i + 40] = 0;
            else if ((gameMatch.winner == gameMatch.home && bets[i + 40] == 1) || 
                    (gameMatch.winner == gameMatch.away && bets[i + 40] == 2)) {
                betResults[i + 40] = 1;
                points++;
            } else betResults[i + 40] = 2;

            matchId = midwestRegion.matchesRound2[i];
            gameMatch = factory.getMatch(year, matchId);
            betTeamNames[i + 44] = factory.getTeamName(year, bets[i + 44] == 1 ? gameMatch.home : gameMatch.away);
            if (gameMatch.winner == 0) betResults[i + 44] = 0;
            else if ((gameMatch.winner == gameMatch.home && bets[i + 44] == 1) || 
                    (gameMatch.winner == gameMatch.away && bets[i + 44] == 2)) {
                betResults[i + 44] = 1;
                points++;
            } else betResults[i + 44] = 2;
        }

        for (uint8 i = 0; i < 2; i++) {
            IOnchainMadnessFactory.Region memory eastRegion = factory.getRegion(year, EAST);
            IOnchainMadnessFactory.Region memory southRegion = factory.getRegion(year, SOUTH);
            IOnchainMadnessFactory.Region memory westRegion = factory.getRegion(year, WEST);
            IOnchainMadnessFactory.Region memory midwestRegion = factory.getRegion(year, MIDWEST);

            matchId = eastRegion.matchesRound3[i];
            gameMatch = factory.getMatch(year, matchId);
            betTeamNames[i + 48] = factory.getTeamName(year, bets[i + 48] == 1 ? gameMatch.home : gameMatch.away);
            if (gameMatch.winner == 0) betResults[i + 48] = 0;
            else if ((gameMatch.winner == gameMatch.home && bets[i + 48] == 1) || 
                    (gameMatch.winner == gameMatch.away && bets[i + 48] == 2)) {
                betResults[i + 48] = 1;
                points++;
            } else betResults[i + 48] = 2;

            matchId = southRegion.matchesRound3[i];
            gameMatch = factory.getMatch(year, matchId);
            betTeamNames[i + 50] = factory.getTeamName(year, bets[i + 50] == 1 ? gameMatch.home : gameMatch.away);
            if (gameMatch.winner == 0) betResults[i + 50] = 0;
            else if ((gameMatch.winner == gameMatch.home && bets[i + 50] == 1) || 
                    (gameMatch.winner == gameMatch.away && bets[i + 50] == 2)) {
                betResults[i + 50] = 1;
                points++;
            } else betResults[i + 50] = 2;

            matchId = westRegion.matchesRound3[i];
            gameMatch = factory.getMatch(year, matchId);
            betTeamNames[i + 52] = factory.getTeamName(year, bets[i + 52] == 1 ? gameMatch.home : gameMatch.away);
            if (gameMatch.winner == 0) betResults[i + 52] = 0;
            else if ((gameMatch.winner == gameMatch.home && bets[i + 52] == 1) || 
                    (gameMatch.winner == gameMatch.away && bets[i + 52] == 2)) {
                betResults[i + 52] = 1;
                points++;
            } else betResults[i + 52] = 2;

            matchId = midwestRegion.matchesRound3[i];
            gameMatch = factory.getMatch(year, matchId);
            betTeamNames[i + 54] = factory.getTeamName(year, bets[i + 54] == 1 ? gameMatch.home : gameMatch.away);
            if (gameMatch.winner == 0) betResults[i + 54] = 0;
            else if ((gameMatch.winner == gameMatch.home && bets[i + 54] == 1) || 
                    (gameMatch.winner == gameMatch.away && bets[i + 54] == 2)) {
                betResults[i + 54] = 1;
                points++;
            } else betResults[i + 54] = 2;
        }

        // Round 4
        IOnchainMadnessFactory.Region memory region = factory.getRegion(year, EAST);
        matchId = region.matchRound4;
        gameMatch = factory.getMatch(year, matchId);
        betTeamNames[56] = factory.getTeamName(year, bets[56] == 1 ? gameMatch.home : gameMatch.away);
        if (gameMatch.winner == 0) betResults[56] = 0;
        else if ((gameMatch.winner == gameMatch.home && bets[56] == 1) || 
                (gameMatch.winner == gameMatch.away && bets[56] == 2)) {
            betResults[56] = 1;
            points++;
        } else betResults[56] = 2;

        region = factory.getRegion(year, SOUTH);
        matchId = region.matchRound4;
        gameMatch = factory.getMatch(year, matchId);
        betTeamNames[57] = factory.getTeamName(year, bets[57] == 1 ? gameMatch.home : gameMatch.away);
        if (gameMatch.winner == 0) betResults[57] = 0;
        else if ((gameMatch.winner == gameMatch.home && bets[57] == 1) || 
                (gameMatch.winner == gameMatch.away && bets[57] == 2)) {
            betResults[57] = 1;
            points++;
        } else betResults[57] = 2;

        region = factory.getRegion(year, WEST);
        matchId = region.matchRound4;
        gameMatch = factory.getMatch(year, matchId);
        betTeamNames[58] = factory.getTeamName(year, bets[58] == 1 ? gameMatch.home : gameMatch.away);
        if (gameMatch.winner == 0) betResults[58] = 0;
        else if ((gameMatch.winner == gameMatch.home && bets[58] == 1) || 
                (gameMatch.winner == gameMatch.away && bets[58] == 2)) {
            betResults[58] = 1;
            points++;
        } else betResults[58] = 2;

        region = factory.getRegion(year, MIDWEST);
        matchId = region.matchRound4;
        gameMatch = factory.getMatch(year, matchId);
        betTeamNames[59] = factory.getTeamName(year, bets[59] == 1 ? gameMatch.home : gameMatch.away);
        if (gameMatch.winner == 0) betResults[59] = 0;
        else if ((gameMatch.winner == gameMatch.home && bets[59] == 1) || 
                (gameMatch.winner == gameMatch.away && bets[59] == 2)) {
            betResults[59] = 1;
            points++;
        } else betResults[59] = 2;

        // Final Four
        IOnchainMadnessFactory.Match memory finalMatch = factory.getMatch(year, factory.getFinalFour(year).matchesRound1[0]);
        betTeamNames[60] = factory.getTeamName(year, bets[60] == 1 ? finalMatch.home : finalMatch.away);
        if (finalMatch.winner == 0) betResults[60] = 0;
        else if ((finalMatch.winner == finalMatch.home && bets[60] == 1) || 
                (finalMatch.winner == finalMatch.away && bets[60] == 2)) {
            betResults[60] = 1;
            points++;
        } else betResults[60] = 2;

        finalMatch = factory.getMatch(year, factory.getFinalFour(year).matchesRound1[1]);
        betTeamNames[61] = factory.getTeamName(year, bets[61] == 1 ? finalMatch.home : finalMatch.away);
        if (finalMatch.winner == 0) betResults[61] = 0;
        else if ((finalMatch.winner == finalMatch.home && bets[61] == 1) || 
                (finalMatch.winner == finalMatch.away && bets[61] == 2)) {
            betResults[61] = 1;
            points++;
        } else betResults[61] = 2;

        finalMatch = factory.getMatch(year, factory.getFinalFour(year).matchFinal);
        betTeamNames[62] = factory.getTeamName(year, bets[62] == 1 ? finalMatch.home : finalMatch.away);
        if (finalMatch.winner == 0) betResults[62] = 0;
        else if ((finalMatch.winner == finalMatch.home && bets[62] == 1) || 
                (finalMatch.winner == finalMatch.away && bets[62] == 2)) {
            betResults[62] = 1;
            points++;
        } else betResults[62] = 2;
    }
}