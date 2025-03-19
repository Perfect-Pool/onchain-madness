// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IOnchainMadnessFactory.sol";

library OnchainMadnessBetLib {
    /**
     * @dev Get the names of the teams based on the bets
     * @param bets The bets
     * @param teamsEast The names of the teams in the east region
     * @param teamsSouth The names of the teams in the south region
     * @param teamsWest The names of the teams in the west region
     * @param teamsMidwest The names of the teams in the midwest region
     * @return teamIds The names of the teams based on the bets
     */
    function betTeamIds(
        uint8[63] memory bets,
        uint8[16] memory teamsEast,
        uint8[16] memory teamsSouth,
        uint8[16] memory teamsWest,
        uint8[16] memory teamsMidwest,
        uint8[4] memory changedPosition
    ) external pure returns (uint8[63] memory teamIds) {
        uint8[4] memory regionPosition = [14, 29, 44, 59];
        // EAST
        // ROUND 1
        teamIds[0] = bets[0] == 0 ? teamsEast[0] : teamsEast[1];
        teamIds[1] = bets[1] == 0 ? teamsEast[2] : teamsEast[3];
        teamIds[2] = bets[2] == 0 ? teamsEast[4] : teamsEast[5];
        teamIds[3] = bets[3] == 0 ? teamsEast[6] : teamsEast[7];
        teamIds[4] = bets[4] == 0 ? teamsEast[8] : teamsEast[9];
        teamIds[5] = bets[5] == 0 ? teamsEast[10] : teamsEast[11];
        teamIds[6] = bets[6] == 0 ? teamsEast[12] : teamsEast[13];
        teamIds[7] = bets[7] == 0 ? teamsEast[14] : teamsEast[15];
        // ROUND 2
        teamIds[8] = bets[8] == 0 ? teamIds[0] : teamIds[1];
        teamIds[9] = bets[9] == 0 ? teamIds[2] : teamIds[3];
        teamIds[10] = bets[10] == 0 ? teamIds[4] : teamIds[5];
        teamIds[11] = bets[11] == 0 ? teamIds[6] : teamIds[7];
        // ROUND 3
        teamIds[12] = bets[12] == 0 ? teamIds[8] : teamIds[9];
        teamIds[13] = bets[13] == 0 ? teamIds[10] : teamIds[11];
        // ROUND 4
        teamIds[14] = bets[14] == 0 ? teamIds[12] : teamIds[13];

        // SOUTH
        // ROUND 1
        teamIds[15] = bets[15] == 0 ? teamsSouth[0] : teamsSouth[1];
        teamIds[16] = bets[16] == 0 ? teamsSouth[2] : teamsSouth[3];
        teamIds[17] = bets[17] == 0 ? teamsSouth[4] : teamsSouth[5];
        teamIds[18] = bets[18] == 0 ? teamsSouth[6] : teamsSouth[7];
        teamIds[19] = bets[19] == 0 ? teamsSouth[8] : teamsSouth[9];
        teamIds[20] = bets[20] == 0 ? teamsSouth[10] : teamsSouth[11];
        teamIds[21] = bets[21] == 0 ? teamsSouth[12] : teamsSouth[13];
        teamIds[22] = bets[22] == 0 ? teamsSouth[14] : teamsSouth[15];
        // ROUND 2
        teamIds[23] = bets[23] == 0 ? teamIds[15] : teamIds[16];
        teamIds[24] = bets[24] == 0 ? teamIds[17] : teamIds[18];
        teamIds[25] = bets[25] == 0 ? teamIds[19] : teamIds[20];
        teamIds[26] = bets[26] == 0 ? teamIds[21] : teamIds[22];
        // ROUND 3
        teamIds[27] = bets[27] == 0 ? teamIds[23] : teamIds[24];
        teamIds[28] = bets[28] == 0 ? teamIds[25] : teamIds[26];
        // ROUND 4
        teamIds[29] = bets[29] == 0 ? teamIds[27] : teamIds[28];

        // WEST
        // ROUND 1
        teamIds[30] = bets[30] == 0 ? teamsWest[0] : teamsWest[1];
        teamIds[31] = bets[31] == 0 ? teamsWest[2] : teamsWest[3];
        teamIds[32] = bets[32] == 0 ? teamsWest[4] : teamsWest[5];
        teamIds[33] = bets[33] == 0 ? teamsWest[6] : teamsWest[7];
        teamIds[34] = bets[34] == 0 ? teamsWest[8] : teamsWest[9];
        teamIds[35] = bets[35] == 0 ? teamsWest[10] : teamsWest[11];
        teamIds[36] = bets[36] == 0 ? teamsWest[12] : teamsWest[13];
        teamIds[37] = bets[37] == 0 ? teamsWest[14] : teamsWest[15];
        // Round 2
        teamIds[38] = bets[38] == 0 ? teamIds[30] : teamIds[31];
        teamIds[39] = bets[39] == 0 ? teamIds[32] : teamIds[33];
        teamIds[40] = bets[40] == 0 ? teamIds[34] : teamIds[35];
        teamIds[41] = bets[41] == 0 ? teamIds[36] : teamIds[37];
        // Round 3
        teamIds[42] = bets[42] == 0 ? teamIds[38] : teamIds[39];
        teamIds[43] = bets[43] == 0 ? teamIds[40] : teamIds[41];
        // Round 4
        teamIds[44] = bets[44] == 0 ? teamIds[42] : teamIds[43];

        // MIDWEST
        // Round 1
        teamIds[45] = bets[45] == 0 ? teamsMidwest[0] : teamsMidwest[1];
        teamIds[46] = bets[46] == 0 ? teamsMidwest[2] : teamsMidwest[3];
        teamIds[47] = bets[47] == 0 ? teamsMidwest[4] : teamsMidwest[5];
        teamIds[48] = bets[48] == 0 ? teamsMidwest[6] : teamsMidwest[7];
        teamIds[49] = bets[49] == 0 ? teamsMidwest[8] : teamsMidwest[9];
        teamIds[50] = bets[50] == 0 ? teamsMidwest[10] : teamsMidwest[11];
        teamIds[51] = bets[51] == 0 ? teamsMidwest[12] : teamsMidwest[13];
        teamIds[52] = bets[52] == 0 ? teamsMidwest[14] : teamsMidwest[15];
        // Round 2
        teamIds[53] = bets[53] == 0 ? teamIds[45] : teamIds[46];
        teamIds[54] = bets[54] == 0 ? teamIds[47] : teamIds[48];
        teamIds[55] = bets[55] == 0 ? teamIds[49] : teamIds[50];
        teamIds[56] = bets[56] == 0 ? teamIds[51] : teamIds[52];
        // Round 3
        teamIds[57] = bets[57] == 0 ? teamIds[53] : teamIds[54];
        teamIds[58] = bets[58] == 0 ? teamIds[55] : teamIds[56];
        // Round 4
        teamIds[59] = bets[59] == 0 ? teamIds[57] : teamIds[58];

        // Final Four
        teamIds[60] = bets[60] == 0
            ? teamIds[regionPosition[changedPosition[0]]]
            : teamIds[regionPosition[changedPosition[1]]];
        teamIds[61] = bets[61] == 0
            ? teamIds[regionPosition[changedPosition[2]]]
            : teamIds[regionPosition[changedPosition[3]]];

        //final
        teamIds[62] = bets[62] == 0 ? teamIds[60] : teamIds[61];
    }

    /**
     * @notice Calculates points and result for a bet on the tournament
     * @dev Result is 0 for unplayed match, 1 for correct bet, 2 for incorrect bet
     * @param gameResults The results of the tournament
     * @param teamIds The IDs of the teams based on the bets
     * @return newPoints Points after calculation
     * @return betResults Bet result (0: not played, 1: correct, 2: incorrect)
     */
    function calculateResults(
        uint8[63] memory gameResults,
        uint8[63] memory teamIds
    ) external pure returns (uint8 newPoints, uint8[63] memory betResults) {
        for (uint8 i = 0; i < 63; i++) {
            if (gameResults[i] == 0) {
                continue;
            }
            if (teamIds[i] == gameResults[i]) {
                betResults[i] = 1;
                newPoints++;
            } else {
                betResults[i] = 2;
            }
        }
    }
}
