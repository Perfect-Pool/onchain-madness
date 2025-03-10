// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IOnchainMadnessFactory.sol";
library OnchainMadnessLib {
    /**
     * @dev Get the names of the teams based on the bets
     * @param bets The bets
     * @param teamsEast The names of the teams in the east region
     * @param teamsSouth The names of the teams in the south region
     * @param teamsWest The names of the teams in the west region
     * @param teamsMidwest The names of the teams in the midwest region
     * @return teamNames The names of the teams based on the bets
     */
    function betTeamNames(
        uint8[63] memory bets,
        uint8[16] memory teamsEast,
        uint8[16] memory teamsSouth,
        uint8[16] memory teamsWest,
        uint8[16] memory teamsMidwest
    ) external pure returns (uint8[63] memory teamNames) {
        // EAST
        // ROUND 1
        teamNames[0] = bets[0] == 0 ? teamsEast[0] : teamsEast[1];
        teamNames[1] = bets[1] == 0 ? teamsEast[2] : teamsEast[3];
        teamNames[2] = bets[2] == 0 ? teamsEast[4] : teamsEast[5];
        teamNames[3] = bets[3] == 0 ? teamsEast[6] : teamsEast[7];
        teamNames[4] = bets[4] == 0 ? teamsEast[8] : teamsEast[9];
        teamNames[5] = bets[5] == 0 ? teamsEast[10] : teamsEast[11];
        teamNames[6] = bets[6] == 0 ? teamsEast[12] : teamsEast[13];
        teamNames[7] = bets[7] == 0 ? teamsEast[14] : teamsEast[15];
        // ROUND 2
        teamNames[8] = bets[8] == 0 ? teamNames[0] : teamNames[1];
        teamNames[9] = bets[9] == 0 ? teamNames[2] : teamNames[3];
        teamNames[10] = bets[10] == 0 ? teamNames[4] : teamNames[5];
        teamNames[11] = bets[11] == 0 ? teamNames[6] : teamNames[7];
        // ROUND 3
        teamNames[12] = bets[12] == 0 ? teamNames[8] : teamNames[9];
        teamNames[13] = bets[13] == 0 ? teamNames[10] : teamNames[11];
        // ROUND 4
        teamNames[14] = bets[14] == 0 ? teamNames[12] : teamNames[13];

        // SOUTH
        // ROUND 1
        teamNames[15] = bets[15] == 0 ? teamsSouth[0] : teamsSouth[1];
        teamNames[16] = bets[16] == 0 ? teamsSouth[2] : teamsSouth[3];
        teamNames[17] = bets[17] == 0 ? teamsSouth[4] : teamsSouth[5];
        teamNames[18] = bets[18] == 0 ? teamsSouth[6] : teamsSouth[7];
        teamNames[19] = bets[19] == 0 ? teamsSouth[8] : teamsSouth[9];
        teamNames[20] = bets[20] == 0 ? teamsSouth[10] : teamsSouth[11];
        teamNames[21] = bets[21] == 0 ? teamsSouth[12] : teamsSouth[13];
        teamNames[22] = bets[22] == 0 ? teamsSouth[14] : teamsSouth[15];
        // ROUND 2
        teamNames[23] = bets[23] == 0 ? teamNames[15] : teamNames[16];
        teamNames[24] = bets[24] == 0 ? teamNames[17] : teamNames[18];
        teamNames[25] = bets[25] == 0 ? teamNames[19] : teamNames[20];
        teamNames[26] = bets[26] == 0 ? teamNames[21] : teamNames[22];
        // ROUND 3
        teamNames[27] = bets[27] == 0 ? teamNames[23] : teamNames[24];
        teamNames[28] = bets[28] == 0 ? teamNames[25] : teamNames[26];
        // ROUND 4
        teamNames[29] = bets[29] == 0 ? teamNames[27] : teamNames[28];

        // WEST
        // ROUND 1
        teamNames[30] = bets[30] == 0 ? teamsWest[0] : teamsWest[1];
        teamNames[31] = bets[31] == 0 ? teamsWest[2] : teamsWest[3];
        teamNames[32] = bets[32] == 0 ? teamsWest[4] : teamsWest[5];
        teamNames[33] = bets[33] == 0 ? teamsWest[6] : teamsWest[7];
        teamNames[34] = bets[34] == 0 ? teamsWest[8] : teamsWest[9];
        teamNames[35] = bets[35] == 0 ? teamsWest[10] : teamsWest[11];
        teamNames[36] = bets[36] == 0 ? teamsWest[12] : teamsWest[13];
        teamNames[37] = bets[37] == 0 ? teamsWest[14] : teamsWest[15];
        // Round 2
        teamNames[38] = bets[38] == 0 ? teamNames[30] : teamNames[31];
        teamNames[39] = bets[39] == 0 ? teamNames[32] : teamNames[33];
        teamNames[40] = bets[40] == 0 ? teamNames[34] : teamNames[35];
        teamNames[41] = bets[41] == 0 ? teamNames[36] : teamNames[37];
        // Round 3
        teamNames[42] = bets[42] == 0 ? teamNames[38] : teamNames[39];
        teamNames[43] = bets[43] == 0 ? teamNames[40] : teamNames[41];
        // Round 4
        teamNames[44] = bets[44] == 0 ? teamNames[42] : teamNames[43];

        // MIDWEST
        // Round 1
        teamNames[45] = bets[45] == 0 ? teamsMidwest[0] : teamsMidwest[1];
        teamNames[46] = bets[46] == 0 ? teamsMidwest[2] : teamsMidwest[3];
        teamNames[47] = bets[47] == 0 ? teamsMidwest[4] : teamsMidwest[5];
        teamNames[48] = bets[48] == 0 ? teamsMidwest[6] : teamsMidwest[7];
        teamNames[49] = bets[49] == 0 ? teamsMidwest[8] : teamsMidwest[9];
        teamNames[50] = bets[50] == 0 ? teamsMidwest[10] : teamsMidwest[11];
        teamNames[51] = bets[51] == 0 ? teamsMidwest[12] : teamsMidwest[13];
        teamNames[52] = bets[52] == 0 ? teamsMidwest[14] : teamsMidwest[15];
        // Round 2
        teamNames[53] = bets[53] == 0 ? teamNames[45] : teamNames[46];
        teamNames[54] = bets[54] == 0 ? teamNames[47] : teamNames[48];
        teamNames[55] = bets[55] == 0 ? teamNames[49] : teamNames[50];
        teamNames[56] = bets[56] == 0 ? teamNames[51] : teamNames[52];
        // Round 3
        teamNames[57] = bets[57] == 0 ? teamNames[53] : teamNames[54];
        teamNames[58] = bets[58] == 0 ? teamNames[55] : teamNames[56];
        // Round 4
        teamNames[59] = bets[59] == 0 ? teamNames[57] : teamNames[58];

        // Final Four
        teamNames[60] = bets[60] == 0 ? teamNames[14] : teamNames[44];
        teamNames[61] = bets[61] == 0 ? teamNames[29] : teamNames[59];

        //final
        teamNames[62] = bets[62] == 0 ? teamNames[60] : teamNames[61];
    }

    /**
     * @notice Calculates points and result for a bet on a match
     * @dev Result is 0 for unplayed match, 1 for correct bet, 2 for incorrect bet
     * @param points Current points
     * @param bet Bet made (0 for home, 1 for away)
     * @param gameMatch Match details
     * @return newPoints Points after calculation
     * @return result Bet result (0: not played, 1: correct, 2: incorrect)
     */
    function calculateResults(
        uint8 points,
        uint8 bet,
        IOnchainMadnessFactory.Match memory gameMatch
    ) external pure returns (uint8 newPoints, uint8 result) {
        if (gameMatch.winner == 0) {
            result = 0;
            newPoints = points;
            return (newPoints, result);
        }

        if ((bet == 0 && gameMatch.winner == gameMatch.home) || (bet == 1 && gameMatch.winner == gameMatch.away)) {
            result = 1;
            newPoints = points + 1;
        } else {
            result = 2;
            newPoints = points;
        }
    }

    /**
     * @dev Calculate shares for treasury and recipient
     * @param shareAmount The total share amount to split
     * @return treasuryShare The share amount for treasury
     * @return recipientShare The share amount for the recipient
     */
    function calculateShares(
        uint256 shareAmount
    ) external pure returns (uint256 treasuryShare, uint256 recipientShare) {
        treasuryShare = shareAmount / 2;
        recipientShare = shareAmount - treasuryShare;
        return (treasuryShare, recipientShare);
    }

    /**
     * @notice Get the current day
     * @dev Uses timestamp to calculate current day, optimized for gas
     * @return year The current year (e.g., 2024)
     * @return month The current month (e.g., 1-12)
     * @return day The current day (e.g., 1-31)
     */
    function getCurrentDate()
        public
        view
        returns (uint256 year, uint256 month, uint256 day)
    {
        unchecked {
            uint256 timestamp = block.timestamp;
            uint256 z = timestamp / 86400 + 719468;
            uint256 era = z / 146097;
            uint256 doe = z - era * 146097;
            uint256 yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
            uint256 doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
            uint256 mp = (5 * doy + 2) / 153;

            day = uint8(doy - (153 * mp + 2) / 5 + 1);
            month = uint8(mp < 10 ? mp + 3 : mp - 9);
            year = uint16(yoe + era * 400 + 1);
        }
    }
}
