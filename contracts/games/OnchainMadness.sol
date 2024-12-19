// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OnchainMadness
 * @author PerfectPool
 * @notice Contract for managing individual NCAA Tournament bracket instances
 * @dev Handles tournament progression, match results, and team management for a specific year
 * Tournament structure:
 * - First Four: 4 play-in matches before Round 1
 * - 4 Regions (South, West, Midwest, East): each with 16 teams
 * - Each region progresses through 4 rounds:
 *   Round 1: 8 matches (16 teams)
 *   Round 2: 4 matches (8 teams)
 *   Round 3: 2 matches (4 teams)
 *   Round 4: 1 match (2 teams)
 * - Final Four: Winners of each region
 * - Championship: Winners of Final Four matches
 *
 * Match progression pattern:
 * - Round 1 to Round 2:
 *   matchesRound1[0].winner -> matchesRound2[0].home
 *   matchesRound1[1].winner -> matchesRound2[0].away
 *   matchesRound1[2].winner -> matchesRound2[1].home
 *   matchesRound1[3].winner -> matchesRound2[1].away
 *   matchesRound1[4].winner -> matchesRound2[2].home
 *   matchesRound1[5].winner -> matchesRound2[2].away
 *   matchesRound1[6].winner -> matchesRound2[3].home
 *   matchesRound1[7].winner -> matchesRound2[3].away
 *
 * Same pattern applies for subsequent rounds:
 * - Round 2 to Round 3
 * - Round 3 to Round 4
 */
contract OnchainMadness {
    /** CONSTANTS **/
    bytes32 public constant SOUTH = keccak256("SOUTH");
    bytes32 public constant WEST = keccak256("WEST");
    bytes32 public constant MIDWEST = keccak256("MIDWEST");
    bytes32 public constant EAST = keccak256("EAST");
    bytes[4] private matchCodes;

    /** STRUCTS AND ENUMS **/
    /**
     * @dev Represents the status of the tournament
     */
    enum Status {
        Disabled,
        BetsOn,
        OnGoing,
        Finished
    }

    /**
     * @dev Represents a match between two teams
     * @param home ID of the home team
     * @param away ID of the away team
     * @param home_points Points scored by the home team
     * @param away_points Points scored by the away team
     * @param winner ID of the winning team
     */
    struct Match {
        uint8 home;
        uint8 away;
        uint8 winner;
        uint256 home_points;
        uint256 away_points;
    }

    /**
     * @dev Represents a region in the tournament
     * @param teams Array of team IDs in the region
     * @param matchesRound1 Array of Round 1 match IDs
     * @param matchesRound2 Array of Round 2 match IDs
     * @param matchesRound3 Array of Round 3 match IDs
     * @param matchRound4 Final match ID for the region
     * @param winner ID of the region winner
     */
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
     * @param matchesRound1 Array of Final Four match IDs
     * @param matchFinal Championship match ID
     * @param winner ID of the tournament winner
     */
    struct FinalFour {
        uint8[2] matchesRound1;
        uint8 matchFinal;
        uint8 winner;
    }

    /** STATE VARIABLES **/
    mapping(bytes32 => Region) private regions;
    mapping(uint8 => Match) private matches;
    mapping(uint8 => bytes) private teams;
    mapping(bytes => uint8) private teamToId;
    mapping(bytes => uint8) private firstFourMatches;
    uint8[4] private firstFourWinners;

    uint256 public year;
    uint8 public currentRound;
    uint8 public playersActualIndex;
    uint8 public matchesActualIndex;

    Status public status;
    FinalFour private finalFour;
    address public gameContract;

    /** MODIFIERS **/
    /**
     * @dev Restricts access to the game contract
     */
    modifier onlyGameContract() {
        require(msg.sender == gameContract, "OM-01");
        _;
    }

    /**
     * @dev Initializes a new tournament instance
     * @param _year The year of the tournament
     * @param _gameContract The address of the factory contract
     */
    function initialize(uint256 _year, address _gameContract) external {
        year = _year;
        gameContract = _gameContract;

        playersActualIndex = 1;
        matchesActualIndex = 1;

        matchCodes = [
            bytes("FFG1"),
            bytes("FFG2"),
            bytes("FFG3"),
            bytes("FFG4")
        ];

        status = Status.BetsOn;
    }

    /**
     * @dev Initializes a First Four match with two teams
     * @param _matchCode The code identifying the First Four match (FFG1-FFG4)
     * @param _home The name of the home team
     * @param _away The name of the away team
     */
    function initFirstFourMatch(
        string memory _matchCode,
        string memory _home,
        string memory _away
    ) external onlyGameContract {
        require(bytes(_home).length > 0 && bytes(_away).length > 0, "OM-02");
        bytes memory matchCode = bytes(_matchCode);
        bytes memory teamHomeHash = bytes(_home);
        bytes memory teamAwayHash = bytes(_away);

        uint8 newId = playersActualIndex;
        teams[newId] = teamHomeHash;
        teamToId[teamHomeHash] = newId;
        matches[matchesActualIndex].home = newId;
        newId++;

        teams[newId] = teamAwayHash;
        teamToId[teamAwayHash] = newId;
        matches[matchesActualIndex].away = newId;
        newId++;

        firstFourMatches[matchCode] = matchesActualIndex;
        matchesActualIndex++;

        playersActualIndex = newId;
    }

    /**
     * @dev Initializes a region with 16 teams and sets up first round matches
     * @param _regionName The name of the region (SOUTH, WEST, MIDWEST, EAST)
     * @param teamNames Array of 16 team names for the region, ordered by seeding
     */
    function initRegion(
        string memory _regionName,
        string[16] memory teamNames
    ) external onlyGameContract {
        bytes32 regionName = keccak256(bytes(_regionName));
        uint8[16] memory teamIds;
        uint8[8] memory matchIds;
        uint8 matchIndex = 0;
        uint8 newId = playersActualIndex;

        for (uint8 i = 0; i < 16; i++) {
            require(bytes(teamNames[i]).length > 0, "OM-02");

            bytes memory teamHash = bytes(teamNames[i]);
            uint8 teamId = teamToId[teamHash];
            if (teamId == 0) {
                teams[newId] = teamHash;
                teamToId[teamHash] = newId;
                teamId = newId;
                newId++;
            }

            teamIds[i] = teamId;

            if (i % 2 == 1) {
                matches[matchesActualIndex].home = teamIds[i - 1];
                matches[matchesActualIndex].away = teamIds[i];
                matchIds[matchIndex] = matchesActualIndex;
                matchIndex++;
                matchesActualIndex++;
            }
        }

        regions[regionName].teams = teamIds;
        regions[regionName].matchesRound1 = matchIds;
        playersActualIndex = newId;
    }

    /**
     * @dev Records the result of a First Four match and sets the winner
     * @param matchCode The code of the First Four match (FFG1-FFG4)
     * @param _homePoints Points scored by the home team
     * @param _awayPoints Points scored by the away team
     * @param _winner Winner of the match (1 for home, 2 for away)
     */
    function determineFirstFourWinner(
        string memory matchCode,
        uint256 _homePoints,
        uint256 _awayPoints,
        uint8 _winner
    ) external onlyGameContract {
        bytes memory _matchCode = bytes(matchCode);
        Match storage currentMatch = matches[firstFourMatches[_matchCode]];

        if (currentMatch.winner != 0) {
            return;
        }

        currentMatch.home_points = _homePoints;
        currentMatch.away_points = _awayPoints;
        currentMatch.winner = _winner == 1
            ? currentMatch.home
            : currentMatch.away;

        if (keccak256(bytes(matchCode)) == keccak256("FFG1")) {
            firstFourWinners[0] = currentMatch.winner;
        } else if (keccak256(bytes(matchCode)) == keccak256("FFG2")) {
            firstFourWinners[1] = currentMatch.winner;
        } else if (keccak256(bytes(matchCode)) == keccak256("FFG3")) {
            firstFourWinners[2] = currentMatch.winner;
        } else if (keccak256(bytes(matchCode)) == keccak256("FFG4")) {
            firstFourWinners[3] = currentMatch.winner;
        }
    }

    /**
     * @dev Closes the betting period and starts the tournament
     */
    function closeBets() external onlyGameContract {
        require(status == Status.BetsOn, "OM-05");
        currentRound = 1;
        status = Status.OnGoing;
    }

    /**
     * @dev Advances the tournament to the next round
     */
    function advanceRound() external onlyGameContract {
        currentRound++;
    }

    /**
     * @dev Records the result of a match and sets up the next round match
     * Match progression pattern:
     * - Even matchIndex winner becomes home team of next round match
     * - Odd matchIndex winner becomes away team of next round match
     * Example: matchesRound1[0].winner -> matchesRound2[0].home
     *         matchesRound1[1].winner -> matchesRound2[0].away
     * @param regionName The name of the region
     * @param winner The name of the winning team
     * @param round Current round number (1-4)
     * @param matchIndex Index of the match in the current round
     * @param homePoints Points scored by home team
     * @param awayPoints Points scored by away team
     */
    function determineMatchWinner(
        string memory regionName,
        string memory winner,
        uint8 round,
        uint8 matchIndex,
        uint256 homePoints,
        uint256 awayPoints
    ) external onlyGameContract {
        require(currentRound == round, "OM-05");
        require(bytes(winner).length > 0, "OM-02");

        bytes32 regionHash = keccak256(bytes(regionName));
        Region storage region = regions[regionHash];

        uint8 matchId;
        if (round == 1) {
            matchId = region.matchesRound1[matchIndex];
        } else if (round == 2) {
            matchId = region.matchesRound2[matchIndex];
        } else if (round == 3) {
            matchId = region.matchesRound3[matchIndex];
        } else if (round == 4) {
            matchId = region.matchRound4;
        } else {
            revert("OM-05");
        }

        Match storage currentMatch = matches[matchId];
        require(currentMatch.winner == 0, "OM-07");

        uint8 winnerId = teamToId[bytes(winner)];
        require(
            winnerId == teamToId[bytes(getTeamName(currentMatch.home))] ||
                winnerId == teamToId[bytes(getTeamName(currentMatch.away))],
            "OM-08"
        );

        // Store match points
        currentMatch.home_points = homePoints;
        currentMatch.away_points = awayPoints;
        currentMatch.winner = winnerId;

        // Set up next round match
        if (round < 4) {
            uint8 nextRoundMatchIndex = matchIndex / 2;
            uint8 nextMatchId;

            if (round == 1) {
                if (region.matchesRound2[nextRoundMatchIndex] == 0) {
                    nextMatchId = matchesActualIndex++;
                    region.matchesRound2[nextRoundMatchIndex] = nextMatchId;
                } else {
                    nextMatchId = region.matchesRound2[nextRoundMatchIndex];
                }
            } else if (round == 2) {
                if (region.matchesRound3[nextRoundMatchIndex] == 0) {
                    nextMatchId = matchesActualIndex++;
                    region.matchesRound3[nextRoundMatchIndex] = nextMatchId;
                } else {
                    nextMatchId = region.matchesRound3[nextRoundMatchIndex];
                }
            } else if (round == 3) {
                if (region.matchRound4 == 0) {
                    nextMatchId = matchesActualIndex++;
                    region.matchRound4 = nextMatchId;
                } else {
                    nextMatchId = region.matchRound4;
                }
            }

            Match storage nextMatch = matches[nextMatchId];
            if (matchIndex % 2 == 0) {
                nextMatch.home = winnerId;
            } else {
                nextMatch.away = winnerId;
            }
        }
    }

    /**
     * @dev Records the result of a region's final match and sets up Final Four match
     * Final Four placement:
     * - WEST region winner -> First Final Four match home team
     * - EAST region winner -> First Final Four match away team
     * - SOUTH region winner -> Second Final Four match home team
     * - MIDWEST region winner -> Second Final Four match away team
     * @param regionName The name of the region
     * @param winner The name of the winning team
     * @param homePoints Points scored by home team
     * @param awayPoints Points scored by away team
     */
    function determineFinalRegionWinner(
        string memory regionName,
        string memory winner,
        uint256 homePoints,
        uint256 awayPoints
    ) external onlyGameContract {
        require(currentRound == 4, "OM-05");
        require(bytes(winner).length > 0, "OM-02");

        bytes32 regionHash = keccak256(bytes(regionName));
        Region storage region = regions[regionHash];
        Match storage currentMatch = matches[region.matchRound4];
        require(currentMatch.winner == 0, "OM-07");

        uint8 winnerId = teamToId[bytes(winner)];
        require(
            winnerId == teamToId[bytes(getTeamName(currentMatch.home))] ||
                winnerId == teamToId[bytes(getTeamName(currentMatch.away))],
            "OM-08"
        );

        // Store match points
        currentMatch.home_points = homePoints;
        currentMatch.away_points = awayPoints;
        currentMatch.winner = winnerId;
        region.winner = winnerId;

        uint8 roundMatchId;
        if (regionHash == WEST) {
            if (finalFour.matchesRound1[0] == 0) {
                finalFour.matchesRound1[0] = matchesActualIndex;
                roundMatchId = matchesActualIndex;
                matchesActualIndex++;
            } else {
                roundMatchId = finalFour.matchesRound1[0];
            }
            matches[roundMatchId].away = winnerId;
        } else if (regionHash == EAST) {
            if (finalFour.matchesRound1[0] == 0) {
                finalFour.matchesRound1[0] = matchesActualIndex;
                roundMatchId = matchesActualIndex;
                matchesActualIndex++;
            } else {
                roundMatchId = finalFour.matchesRound1[0];
            }
            matches[roundMatchId].home = winnerId;
        } else if (regionHash == SOUTH) {
            if (finalFour.matchesRound1[1] == 0) {
                finalFour.matchesRound1[1] = matchesActualIndex;
                roundMatchId = matchesActualIndex;
                matchesActualIndex++;
            } else {
                roundMatchId = finalFour.matchesRound1[1];
            }
            matches[roundMatchId].home = winnerId;
        } else if (regionHash == MIDWEST) {
            if (finalFour.matchesRound1[1] == 0) {
                finalFour.matchesRound1[1] = matchesActualIndex;
                roundMatchId = matchesActualIndex;
                matchesActualIndex++;
            } else {
                roundMatchId = finalFour.matchesRound1[1];
            }
            matches[roundMatchId].away = winnerId;
        }
    }

    /**
     * @dev Records the result of a Final Four match and sets up championship match
     * Championship match is created when both Final Four matches are complete
     * @param gameIndex Index of the Final Four match (0 or 1)
     * @param winners The name of the winning team
     * @param homePoints Points scored by home team
     * @param awayPoints Points scored by away team
     */
    function determineFinalFourWinner(
        uint8 gameIndex,
        string memory winners,
        uint256 homePoints,
        uint256 awayPoints
    ) external onlyGameContract {
        require(currentRound == 5, "OM-05");
        require(gameIndex < 2, "OM-09");

        Match storage currentMatch = matches[
            finalFour.matchesRound1[gameIndex]
        ];
        require(currentMatch.winner == 0, "OM-07");

        uint8 winnerId = teamToId[bytes(winners)];
        require(
            winnerId == teamToId[bytes(getTeamName(currentMatch.home))] ||
                winnerId == teamToId[bytes(getTeamName(currentMatch.away))],
            "OM-08"
        );

        // Store match points
        currentMatch.home_points = homePoints;
        currentMatch.away_points = awayPoints;
        currentMatch.winner = winnerId;

        // Create championship match once both Final Four matches are complete
        if (
            matches[finalFour.matchesRound1[0]].winner != 0 &&
            matches[finalFour.matchesRound1[1]].winner != 0
        ) {
            matches[matchesActualIndex].home = matches[
                finalFour.matchesRound1[0]
            ].winner;
            matches[matchesActualIndex].away = matches[
                finalFour.matchesRound1[1]
            ].winner;
            finalFour.matchFinal = matchesActualIndex;
            matchesActualIndex++;
        }
    }

    /**
     * @dev Records the result of the championship match and completes the tournament
     * @param winner The name of the winning team
     * @param homePoints Points scored by the home team
     * @param awayPoints Points scored by the away team
     */
    function determineChampion(
        string memory winner,
        uint256 homePoints,
        uint256 awayPoints
    ) external onlyGameContract {
        require(currentRound == 6, "OM-05");

        Match storage currentMatch = matches[finalFour.matchFinal];
        require(currentMatch.winner == 0, "OM-07");

        uint8 winnerId = teamToId[bytes(winner)];
        require(
            winnerId == teamToId[bytes(getTeamName(currentMatch.home))] ||
                winnerId == teamToId[bytes(getTeamName(currentMatch.away))],
            "OM-08"
        );

        // Store match points
        currentMatch.home_points = homePoints;
        currentMatch.away_points = awayPoints;
        currentMatch.winner = winnerId;
        finalFour.winner = winnerId;

        status = Status.Finished;
    }

    /**
     * @dev Get the match data for a specific match
     * @param matchId The ID of the match
     * @return The match data in bytes format
     */
    function getMatchData(uint8 matchId) internal view returns (bytes memory) {
        //string home, string away, uint256 home_points, uint256 away_points, string winner
        return
            abi.encode(
                getTeamName(matches[matchId].home),
                getTeamName(matches[matchId].away),
                matches[matchId].home_points,
                matches[matchId].away_points,
                getTeamName(matches[matchId].winner)
            );
    }

    /**
     * @dev Get the data for a specific region
     * @param regionName The name of the region
     * @return The region data in bytes format
     */
    function getRegionData(
        bytes32 regionName
    ) external view returns (bytes memory) {
        bytes[8] memory matchesRound1;
        Region storage region = regions[regionName];

        for (uint8 i = 0; i < 8; i++) {
            matchesRound1[i] = getMatchData(region.matchesRound1[i]);
        }

        bytes[4] memory matchesRound2;
        for (uint8 i = 0; i < 4; i++) {
            matchesRound2[i] = getMatchData(region.matchesRound2[i]);
        }

        bytes[2] memory matchesRound3;
        for (uint8 i = 0; i < 2; i++) {
            matchesRound3[i] = getMatchData(region.matchesRound3[i]);
        }

        bytes memory matchRound4 = getMatchData(region.matchRound4);

        string[16] memory _teams;
        for (uint8 i = 0; i < 16; i++) {
            _teams[i] = getTeamName(region.teams[i]);
        }

        // string[16] teams, bytes[8] matchesRound1, bytes[4] matchesRound2, bytes[2] matchesRound3, bytes matchRound4, string winner
        return
            abi.encode(
                _teams,
                matchesRound1,
                matchesRound2,
                matchesRound3,
                matchRound4,
                getTeamName(region.winner)
            );
    }

    /**
     * @dev Get the data for the First Four
     * @return The First Four data in bytes format
     */
    function getFirstFourData() external view returns (bytes[4] memory) {
        return [
            getMatchData(firstFourMatches[bytes("FFG1")]),
            getMatchData(firstFourMatches[bytes("FFG2")]),
            getMatchData(firstFourMatches[bytes("FFG3")]),
            getMatchData(firstFourMatches[bytes("FFG4")])
        ];
    }

    /**
     * @dev Get the data for the Final Four
     * @return The Final Four data in bytes format
     */
    function getFinalFourData() external view returns (bytes memory) {
        bytes[2] memory matchesRound1;
        for (uint8 i = 0; i < 2; i++) {
            matchesRound1[i] = getMatchData(finalFour.matchesRound1[i]);
        }

        bytes memory matchFinal = getMatchData(finalFour.matchFinal);

        // bytes[2] matchesRound1, bytes matchFinal, string winner
        return
            abi.encode(
                matchesRound1,
                matchFinal,
                getTeamName(finalFour.winner)
            );
    }

    /**
     * @dev Get the ID of a team based on its name
     * @param _team The name of the team
     * @return The ID of the team
     */
    function getTeamId(string memory _team) external view returns (uint8) {
        return teamToId[bytes(_team)];
    }

    /**
     * @dev Get the name of a team based on its ID
     * @param _teamId The ID of the team
     * @return The name of the team
     */
    function getTeamName(uint8 _teamId) public view returns (string memory) {
        if(_teamId == 0) {
            return "";
        }
        
        if (
            teamToId[bytes("FFG1")] == _teamId &&
            matches[firstFourMatches[bytes("FFG1")]].winner != 0
        ) {
            return string(teams[firstFourWinners[0]]);
        } else if (
            teamToId[bytes("FFG2")] == _teamId &&
            matches[firstFourMatches[bytes("FFG2")]].winner != 0
        ) {
            return string(teams[firstFourWinners[1]]);
        } else if (
            teamToId[bytes("FFG3")] == _teamId &&
            matches[firstFourMatches[bytes("FFG3")]].winner != 0
        ) {
            return string(teams[firstFourWinners[2]]);
        } else if (
            teamToId[bytes("FFG4")] == _teamId &&
            matches[firstFourMatches[bytes("FFG4")]].winner != 0
        ) {
            return string(teams[firstFourWinners[3]]);
        }
        return string(teams[_teamId]);
    }

    /**
     * @dev Get all the teams in a specific region
     * @param _region The name of the region
     * @return The names of the teams and their corresponding IDs
     */
    function getAllTeams(bytes32 _region) external view returns (bytes memory) {
        string[16] memory _teams;
        uint8[16] memory _teamIds;

        _teamIds = regions[_region].teams;
        for (uint8 i = 0; i < 16; i++) {
            _teams[i] = getTeamName(_teamIds[i]);
        }

        // string[16] memory, uint8[16] memory
        return abi.encode(_teams, _teamIds);
    }

    /**
     * @dev Get all the teams in a specific region
     * @param _region The name of the region
     * @return The names of the teams and their corresponding IDs
     */
    function getAllTeamIds(
        bytes32 _region
    ) external view returns (uint8[16] memory) {
        return regions[_region].teams;
    }

    /**
     * @dev Gets the winners of all matches in the tournament
     * @return An array of 63 winner IDs representing the winners of all matches in order
     */
    function getFinalResult() public view returns (uint8[63] memory) {
        uint8[63] memory winners;

        for (uint8 i = 0; i < 8; i++) {
            winners[i] = matches[regions[EAST].matchesRound1[i]].winner;
            winners[i + 8] = matches[regions[SOUTH].matchesRound1[i]].winner;
            winners[i + 16] = matches[regions[WEST].matchesRound1[i]].winner;
            winners[i + 24] = matches[regions[MIDWEST].matchesRound1[i]].winner;
        }

        for (uint8 i = 0; i < 4; i++) {
            winners[i + 32] = matches[regions[EAST].matchesRound2[i]].winner;
            winners[i + 36] = matches[regions[SOUTH].matchesRound2[i]].winner;
            winners[i + 40] = matches[regions[WEST].matchesRound2[i]].winner;
            winners[i + 44] = matches[regions[MIDWEST].matchesRound2[i]].winner;
        }

        for (uint8 i = 0; i < 2; i++) {
            winners[i + 48] = matches[regions[EAST].matchesRound3[i]].winner;
            winners[i + 50] = matches[regions[SOUTH].matchesRound3[i]].winner;
            winners[i + 52] = matches[regions[WEST].matchesRound3[i]].winner;
            winners[i + 54] = matches[regions[MIDWEST].matchesRound3[i]].winner;
        }

        winners[56] = matches[regions[EAST].matchRound4].winner;
        winners[57] = matches[regions[SOUTH].matchRound4].winner;
        winners[58] = matches[regions[WEST].matchRound4].winner;
        winners[59] = matches[regions[MIDWEST].matchRound4].winner;

        winners[60] = matches[finalFour.matchesRound1[0]].winner;
        winners[61] = matches[finalFour.matchesRound1[1]].winner;
        winners[62] = finalFour.winner;

        return winners;
    }

    /**
     * @dev Get a team symbol based on its ID
     * @param _teamIds The IDs of the teams
     * @return The symbols of the teams
     */
    function getTeamSymbols(
        uint8[63] memory _teamIds
    ) external view returns (string[63] memory) {
        string[63] memory symbols;

        for (uint8 i = 0; i < 63; i++) {
            symbols[i] = getTeamName(_teamIds[i]);
        }

        return symbols;
    }

    /**
     * @dev Get a Region data based on its name
     * @param _regionName The name of the region
     * @return The data of the region as Region memory
     */
    function getRegion(
        bytes32 _regionName
    ) external view returns (Region memory) {
        return regions[_regionName];
    }

    /**
     * @dev Get a match data based on its ID
     * @param _matchId The ID of the match
     * @return The data of the match as Match memory
     */
    function getMatch(uint8 _matchId) external view returns (Match memory) {
        return matches[_matchId];
    }

    /**
     * @dev Get the getFinalFour data
     * @return The data of the Final Four as FinalFour memory
     */
    function getFinalFour() external view returns (FinalFour memory) {
        return finalFour;
    }
}
