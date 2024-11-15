// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title MarchMadness
 * @dev Contract for managing NCAA March Madness tournament brackets
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
contract MarchMadness {
    /** CONSTANTS **/
    bytes32 public constant SOUTH = keccak256("SOUTH");
    bytes32 public constant WEST = keccak256("WEST");
    bytes32 public constant MIDWEST = keccak256("MIDWEST");
    bytes32 public constant EAST = keccak256("EAST");
    bytes[4] private matchCodes;

    /** STRUCTS AND ENUMS **/
    enum Status {
        Disabled,
        BetsOn,
        OnGoing,
        Finished
    }

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
    modifier onlyGameContract() {
        require(msg.sender == gameContract, "MM-01");
        _;
    }

    /**
     * @dev Initializes the MarchMadness contract with tournament year and game contract.
     * @param _year The year of the tournament
     * @param _gameContract The address of the game contract that manages this tournament
     */
    function initialize(
        uint256 _year,
        address _gameContract
    ) external {
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
     * @dev Initializes a First Four match with two teams.
     * @param _matchCode The code identifying the First Four match (FFG1-FFG4)
     * @param _home The name of the home team
     * @param _away The name of the away team
     */
    function initFirstFourMatch(
        string memory _matchCode,
        string memory _home,
        string memory _away
    ) external onlyGameContract {
        require(bytes(_home).length > 0 && bytes(_away).length > 0, "MM-02");
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
     * @dev Initializes a region with 16 teams and sets up first round matches.
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
            require(bytes(teamNames[i]).length > 0, "MM-02");

            bytes memory teamHash = bytes(teamNames[i]);
            uint8 teamId = teamToId[teamHash];
            if (teamId == 0) {
                teams[newId] = teamHash;
                teamToId[teamHash] = newId;
                teamId = newId;
                newId++;
            }

            teamIds[i] = teamId;

            bytes32 teamNameHash = keccak256(bytes(teamNames[i]));

            if (teamNameHash == keccak256("FFG1")) {
                firstFourWinners[0] = teamId;
            } else if (teamNameHash == keccak256("FFG2")) {
                firstFourWinners[1] = teamId;
            } else if (teamNameHash == keccak256("FFG3")) {
                firstFourWinners[2] = teamId;
            } else if (teamNameHash == keccak256("FFG4")) {
                firstFourWinners[3] = teamId;
            }

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
     * @dev Records the result of a First Four match and sets the winner.
     * @param matchCode The code of the First Four match (FFG1-FFG4)
     * @param _homeId ID of the home team
     * @param _awayId ID of the away team
     * @param _homePoints Points scored by the home team
     * @param _awayPoints Points scored by the away team
     * @param _winner Winner of the match (1 for home, 2 for away)
     */
    function determineFirstFourWinner(
        string memory matchCode,
        uint8 _homeId,
        uint8 _awayId,
        uint256 _homePoints,
        uint256 _awayPoints,
        uint8 _winner
    ) external onlyGameContract {
        bytes memory _matchCode = bytes(matchCode);
        Match storage currentMatch = matches[firstFourMatches[_matchCode]];

        if (currentMatch.winner != 0) {
            return;
        }

        if (currentMatch.home == _awayId && currentMatch.away == _homeId) {
            currentMatch.home_points = _awayPoints;
            currentMatch.away_points = _homePoints;
        } else {
            currentMatch.home_points = _homePoints;
            currentMatch.away_points = _awayPoints;
        }

        currentMatch.home = _homeId;
        currentMatch.away = _awayId;

        currentMatch.winner = _winner;
    }

    /**
     * @dev Closes the betting period and starts the tournament.
     */
    function closeBets() external onlyGameContract {
        require(status == Status.BetsOn, "MM-05");
        currentRound = 1;
        status = Status.OnGoing;
    }

    /**
     * @dev Advances the tournament to the next round.
     */
    function advanceRound() external onlyGameContract {
        currentRound++;
    }

    /**
     * @dev Records the result of a match and sets up the next round match.
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
    ) external onlyGameContract{
        require(currentRound == round, "MM-05");
        require(bytes(winner).length > 0, "MM-02");

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
            revert("MM-05");
        }

        Match storage currentMatch = matches[matchId];
        require(currentMatch.winner == 0, "MM-07");

        uint8 winnerId = teamToId[bytes(winner)];
        require(winnerId == currentMatch.home || winnerId == currentMatch.away, "MM-08");
        
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
     * @dev Records the result of a region's final match and sets up Final Four match.
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
    ) external onlyGameContract{
        require(currentRound == 4, "MM-05");
        require(bytes(winner).length > 0, "MM-02");

        bytes32 regionHash = keccak256(bytes(regionName));
        Region storage region = regions[regionHash];
        Match storage currentMatch = matches[region.matchRound4];
        require(currentMatch.winner == 0, "MM-07");

        uint8 winnerId = teamToId[bytes(winner)];
        require(winnerId == currentMatch.home || winnerId == currentMatch.away, "MM-08");

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
            matches[roundMatchId].home = winnerId;
        } else if (regionHash == EAST) {
            if (finalFour.matchesRound1[0] == 0) {
                finalFour.matchesRound1[0] = matchesActualIndex;
                roundMatchId = matchesActualIndex;
                matchesActualIndex++;
            } else {
                roundMatchId = finalFour.matchesRound1[0];
            }
            matches[roundMatchId].away = winnerId;
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
     * @dev Records the result of a Final Four match and sets up championship match.
     * Championship match is created when both Final Four matches are complete.
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
    ) external onlyGameContract{
        require(currentRound == 5, "MM-05");
        require(gameIndex < 2, "MM-09");

        Match storage currentMatch = matches[finalFour.matchesRound1[gameIndex]];
        require(currentMatch.winner == 0, "MM-07");

        uint8 winnerId = teamToId[bytes(winners)];
        require(winnerId == currentMatch.home || winnerId == currentMatch.away, "MM-08");

        // Store match points
        currentMatch.home_points = homePoints;
        currentMatch.away_points = awayPoints;
        currentMatch.winner = winnerId;

        // Create championship match once both Final Four matches are complete
        if (matches[finalFour.matchesRound1[0]].winner != 0 && 
            matches[finalFour.matchesRound1[1]].winner != 0) {
            
            matches[matchesActualIndex].home = matches[finalFour.matchesRound1[0]].winner;
            matches[matchesActualIndex].away = matches[finalFour.matchesRound1[1]].winner;
            finalFour.matchFinal = matchesActualIndex;
            matchesActualIndex++;

            currentRound++;
        }
    }

    /**
     * @dev Records the result of the championship match and completes the tournament.
     * @param winner The name of the winning team
     * @param homePoints Points scored by home team
     * @param awayPoints Points scored by away team
     */
    function determineChampion(
        string memory winner,
        uint256 homePoints,
        uint256 awayPoints
    ) external onlyGameContract{
        require(currentRound == 6, "MM-05");

        Match storage currentMatch = matches[finalFour.matchFinal];
        require(currentMatch.winner == 0, "MM-07");

        uint8 winnerId = teamToId[bytes(winner)];
        require(winnerId == currentMatch.home || winnerId == currentMatch.away, "MM-08");

        // Store match points
        currentMatch.home_points = homePoints;
        currentMatch.away_points = awayPoints;
        currentMatch.winner = winnerId;
        finalFour.winner = winnerId;

        status = Status.Finished;
    }

    /**
     * @dev Get the match data for a specific match.
     * @param matchId The ID of the match.
     * @return The match data in bytes format.
     */
    function getMatchData(uint8 matchId) internal view returns (bytes memory) {
        //string home, string away, uint256 home_points, uint256 away_points, string winner
        return
            abi.encode(
                teams[matches[matchId].home],
                teams[matches[matchId].away],
                matches[matchId].home_points,
                matches[matchId].away_points,
                teams[matches[matchId].winner]
            );
    }

    /**
     * @dev Get the data for a specific region.
     * @param regionName The name of the region.
     * @return The region data in bytes format.
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
            _teams[i] = string(teams[region.teams[i]]);
        }

        // string[16] teams, bytes[8] matchesRound1, bytes[4] matchesRound2, bytes[2] matchesRound3, bytes matchRound4, string winner
        return
            abi.encode(
                _teams,
                matchesRound1,
                matchesRound2,
                matchesRound3,
                matchRound4,
                string(teams[region.winner])
            );
    }

    /**
     * @dev Get the data for the First Four.
     * @return The First Four data in bytes format.
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
     * @dev Get the data for the Final Four.
     * @return The Final Four data in bytes format.
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
                string(teams[finalFour.winner])
            );
    }

    /**
     * @dev Get the ID of a team based on its name.
     * @param _team The name of the team.
     * @return The ID of the team.
     */
    function getTeamId(string memory _team) external view returns (uint8) {
        return teamToId[bytes(_team)];
    }

    /**
     * @dev Get the name of a team based on its ID.
     * @param _teamId The ID of the team.
     * @return The name of the team.
     */
    function getTeamName(uint8 _teamId) external view returns (string memory) {
        return string(teams[_teamId]);
    }

    /**
     * @dev Get all the teams in a specific region.
     * @param _region The name of the region.
     * @return The names of the teams and their corresponding IDs.
     */
    function getAllTeams(bytes32 _region) external view returns (bytes memory) {
        string[16] memory _teams;
        uint8[16] memory _teamIds;

        _teamIds = regions[_region].teams;
        for (uint8 i = 0; i < 16; i++) {
            _teams[i] = string(teams[_teamIds[i]]);
        }

        // string[16] memory, uint8[16] memory
        return abi.encode(_teams, _teamIds);
    }

    /**
     * @dev Build a single array of all winners IDs for all regions, in the order: East, South, West, Midwest and the Final Four
     * @return The full array of winners IDs.
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
     * @dev Get a team symbol based on its ID.
     * @param _teamIds The IDs of the teams.
     * @return The symbols of the teams.
     */
    function getTeamSymbols(
        uint8[63] memory _teamIds
    ) external view returns (string[63] memory) {
        string[63] memory symbols;

        for (uint8 i = 0; i < 63; i++) {
            symbols[i] = string(teams[_teamIds[i]]);
        }

        return symbols;
    }
}
