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
        Match[8] matchesRound1;
        Match[4] matchesRound2;
        Match[2] matchesRound3;
        Match matchRound4;
        uint8 winner;
    }

    /**
     * @dev Represents the Final Four round
     * @param matchesRound1 Array of Final Four match IDs
     * @param matchFinal Championship match ID
     * @param winner ID of the tournament winner
     */
    struct FinalFour {
        Match[2] matchesRound1;
        Match matchFinal;
        uint8 winner;
    }

    /**
     * @dev Represents the First Four team object
     * @param region The region it was allocated
     * @param arrayPosition The position of the team in the region's array
     * @param matchId The match ID it was allocated
     * @position The position of the team in the match
     */
    struct FirstFourTeam {
        bytes32 region;
        uint8 arrayPosition;
        uint8 matchId;
        uint8 position;
    }

    /** STATE VARIABLES **/
    mapping(bytes32 => Region) private regions;
    mapping(uint8 => bytes) private teams;
    mapping(bytes => uint8) private teamToId;
    mapping(bytes => Match) private firstFourMatches;
    mapping(bytes => FirstFourTeam) private firstFourPosition;

    uint256 public year;
    uint8 public currentRound;
    uint8 public playersActualIndex;

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
        require(gameContract == address(0), "OM-00");
        year = _year;
        gameContract = _gameContract;

        playersActualIndex = 1;

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
        require(
            bytes(_home).length > 0 &&
                bytes(_away).length > 0 &&
                _checkIsFfg(bytes(_matchCode)),
            "OM-02"
        );
        bytes memory matchCode = bytes(_matchCode);
        bytes memory teamHomeHash = bytes(_home);
        bytes memory teamAwayHash = bytes(_away);

        Match storage ffMatch = firstFourMatches[matchCode];
        require(ffMatch.home == 0 && ffMatch.away == 0, "OM-07");

        uint8 newId = playersActualIndex;
        teams[newId] = teamHomeHash;
        teamToId[teamHomeHash] = newId;
        ffMatch.home = newId;
        newId++;

        teams[newId] = teamAwayHash;
        teamToId[teamAwayHash] = newId;
        ffMatch.away = newId;
        newId++;

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
                regions[regionName].matchesRound1[matchIndex].home = teamIds[
                    i - 1
                ];
                regions[regionName].matchesRound1[matchIndex].away = teamIds[i];
                if (_checkIsFfg(teamHash)) {
                    firstFourPosition[teamHash] = FirstFourTeam({
                        region: regionName,
                        arrayPosition: i,
                        matchId: matchIndex,
                        position: 1
                    });
                }
                matchIndex++;
            } else if (_checkIsFfg(teamHash)) {
                firstFourPosition[teamHash] = FirstFourTeam({
                    region: regionName,
                    arrayPosition: i,
                    matchId: matchIndex,
                    position: 0
                });
            }
        }

        regions[regionName].teams = teamIds;
        playersActualIndex = newId;
    }

    /**
     * @dev Initializes the Final Four matches
     * @param teamsRound1 Array of team names for the first round of Final Four
     */
    function initFinalFour(
        string[4] memory teamsRound1
    ) external onlyGameContract {
        require(currentRound == 5, "OM-05");
        require(teamsRound1.length == 4, "OM-09");

        for (uint8 i = 0; i < 4; i++) {
            require(bytes(teamsRound1[i]).length > 0, "OM-02");
            require(teamToId[bytes(teamsRound1[i])] != 0, "OM-03");
        }

        Match storage match1 = finalFour.matchesRound1[0];
        match1.home = teamToId[bytes(teamsRound1[0])];
        match1.away = teamToId[bytes(teamsRound1[1])];

        Match storage match2 = finalFour.matchesRound1[1];
        match2.home = teamToId[bytes(teamsRound1[2])];
        match2.away = teamToId[bytes(teamsRound1[3])];
    }

    /**
     * @dev Records the result of a First Four match and sets the winner
     * @param matchCode The code of the First Four match (FFG1-FFG4)
     * @param _homePoints Points scored by the home team
     * @param _awayPoints Points scored by the away team
     * @param winner Name of the winning team
     */
    function determineFirstFourWinner(
        string memory matchCode,
        uint256 _homePoints,
        uint256 _awayPoints,
        string memory winner
    ) external onlyGameContract {
        bytes memory _matchCode = bytes(matchCode);
        Match storage currentMatch = firstFourMatches[_matchCode];

        if (currentMatch.winner != 0) {
            return;
        }

        uint8 winnerId = teamToId[bytes(winner)];

        if (winnerId == currentMatch.home) {
            if (_homePoints > _awayPoints) {
                currentMatch.home_points = _homePoints;
                currentMatch.away_points = _awayPoints;
            } else {
                currentMatch.home_points = _awayPoints;
                currentMatch.away_points = _homePoints;
            }
        } else if (winnerId == currentMatch.away) {
            if (_awayPoints > _homePoints) {
                currentMatch.away_points = _awayPoints;
                currentMatch.home_points = _homePoints;
            } else {
                currentMatch.away_points = _homePoints;
                currentMatch.home_points = _awayPoints;
            }
        } else revert("OM-08");
        currentMatch.winner = winnerId;

        FirstFourTeam memory firstFourTeam = firstFourPosition[_matchCode];

        Match storage bracketMatch = regions[firstFourTeam.region]
            .matchesRound1[firstFourTeam.matchId];
        if (firstFourTeam.position == 0) {
            bracketMatch.home = currentMatch.winner;
        } else {
            bracketMatch.away = currentMatch.winner;
        }

        regions[firstFourTeam.region].teams[
            firstFourTeam.arrayPosition
        ] = currentMatch.winner;
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

        Match storage currentMatch;
        if (round == 1) {
            currentMatch = region.matchesRound1[matchIndex];
        } else if (round == 2) {
            currentMatch = region.matchesRound2[matchIndex];
        } else if (round == 3) {
            currentMatch = region.matchesRound3[matchIndex];
        } else if (round == 4) {
            currentMatch = region.matchRound4;
        } else {
            revert("OM-05");
        }
        require(currentMatch.winner == 0, "OM-07");

        uint8 winnerId = teamToId[bytes(winner)];
        if (winnerId == currentMatch.home) {
            if (homePoints > awayPoints) {
                currentMatch.home_points = homePoints;
                currentMatch.away_points = awayPoints;
            } else {
                currentMatch.home_points = awayPoints;
                currentMatch.away_points = homePoints;
            }
        } else if (winnerId == currentMatch.away) {
            if (awayPoints > homePoints) {
                currentMatch.away_points = awayPoints;
                currentMatch.home_points = homePoints;
            } else {
                currentMatch.away_points = homePoints;
                currentMatch.home_points = awayPoints;
            }
        } else revert("OM-08");
        currentMatch.winner = winnerId;

        // Set up next round match
        if (round < 4) {
            uint8 nextRoundMatchIndex = matchIndex / 2;
            Match storage nextMatch = region.matchesRound2[nextRoundMatchIndex];
            if (round == 2) {
                nextMatch = region.matchesRound3[nextRoundMatchIndex];
            } else if (round == 3) {
                nextMatch = region.matchRound4;
            }

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
        Match storage currentMatch = region.matchRound4;
        require(currentMatch.winner == 0, "OM-07");

        uint8 winnerId = teamToId[bytes(winner)];

        // Store match points
        if (winnerId == currentMatch.home) {
            if (homePoints > awayPoints) {
                currentMatch.home_points = homePoints;
                currentMatch.away_points = awayPoints;
            } else {
                currentMatch.home_points = awayPoints;
                currentMatch.away_points = homePoints;
            }
        } else if (winnerId == currentMatch.away) {
            if (awayPoints > homePoints) {
                currentMatch.away_points = awayPoints;
                currentMatch.home_points = homePoints;
            } else {
                currentMatch.away_points = homePoints;
                currentMatch.home_points = awayPoints;
            }
        } else revert("OM-08");
        currentMatch.winner = winnerId;
        region.winner = winnerId;
    }

    /**
     * @dev Records the result of a Final Four match and sets up championship match
     * Championship match is created when both Final Four matches are complete
     * @param gameIndex Index of the Final Four match (0 or 1)
     * @param winner The name of the winning team
     * @param homePoints Points scored by home team
     * @param awayPoints Points scored by away team
     */
    function determineFinalFourWinner(
        uint8 gameIndex,
        string memory winner,
        uint256 homePoints,
        uint256 awayPoints
    ) external onlyGameContract {
        require(currentRound == 5, "OM-05");
        require(gameIndex < 2, "OM-09");

        Match storage currentMatch = finalFour.matchesRound1[gameIndex];
        require(currentMatch.winner == 0, "OM-07");

        uint8 winnerId = teamToId[bytes(winner)];

        if (winnerId == currentMatch.home) {
            if (homePoints > awayPoints) {
                currentMatch.home_points = homePoints;
                currentMatch.away_points = awayPoints;
            } else {
                currentMatch.home_points = awayPoints;
                currentMatch.away_points = homePoints;
            }
        } else if (winnerId == currentMatch.away) {
            if (awayPoints > homePoints) {
                currentMatch.away_points = awayPoints;
                currentMatch.home_points = homePoints;
            } else {
                currentMatch.away_points = homePoints;
                currentMatch.home_points = awayPoints;
            }
        } else revert("OM-08");

        currentMatch.winner = winnerId;

        if (gameIndex == 0) {
            finalFour.matchFinal.home = winnerId;
        } else {
            finalFour.matchFinal.away = winnerId;
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

        Match storage currentMatch = finalFour.matchFinal;
        require(currentMatch.winner == 0, "OM-07");

        uint8 winnerId = teamToId[bytes(winner)];
        if (winnerId == currentMatch.home) {
            if (homePoints > awayPoints) {
                currentMatch.home_points = homePoints;
                currentMatch.away_points = awayPoints;
            } else {
                currentMatch.home_points = awayPoints;
                currentMatch.away_points = homePoints;
            }
        } else if (winnerId == currentMatch.away) {
            if (awayPoints > homePoints) {
                currentMatch.away_points = awayPoints;
                currentMatch.home_points = homePoints;
            } else {
                currentMatch.away_points = homePoints;
                currentMatch.home_points = awayPoints;
            }
        } else revert("OM-08");
        currentMatch.winner = winnerId;
        finalFour.winner = winnerId;

        status = Status.Finished;
    }

    /**
     * @dev Get the match data for a specific match
     * @param gameMatch The match data
     * @return The match data in bytes format
     */
    function getMatchData(
        Match memory gameMatch
    ) internal view returns (bytes memory) {
        //string home, string away, uint256 home_points, uint256 away_points, string winner
        return
            abi.encode(
                getTeamName(gameMatch.home),
                getTeamName(gameMatch.away),
                gameMatch.home_points,
                gameMatch.away_points,
                getTeamName(gameMatch.winner)
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
        return _teamId == 0 ? "" : string(teams[_teamId]);
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

        // EAST
        // Round 1
        for (uint8 i = 0; i < 8; i++) {
            winners[i] = regions[EAST].matchesRound1[i].winner;
        }
        // Round 2
        for (uint8 i = 8; i < 12; i++) {
            winners[i] = regions[EAST].matchesRound2[i % 4].winner;
        }
        // Round 3
        for (uint8 i = 12; i < 14; i++) {
            winners[i] = regions[EAST].matchesRound3[i % 2].winner;
        }
        // Round 4
        winners[14] = regions[EAST].matchRound4.winner;

        // SOUTH
        // Round 1
        for (uint8 i = 15; i < 23; i++) {
            winners[i] = regions[SOUTH].matchesRound1[(i - 15) % 8].winner;
        }
        // Round 2
        for (uint8 i = 23; i < 27; i++) {
            winners[i] = regions[SOUTH].matchesRound2[(i - 15) % 4].winner;
        }
        // Round 3
        for (uint8 i = 27; i < 29; i++) {
            winners[i] = regions[SOUTH].matchesRound3[(i - 15) % 2].winner;
        }
        // Round 4
        winners[29] = regions[SOUTH].matchRound4.winner;

        // WEST
        // Round 1
        for (uint8 i = 30; i < 38; i++) {
            winners[i] = regions[WEST].matchesRound1[(i - 30) % 8].winner;
        }
        // Round 2
        for (uint8 i = 38; i < 42; i++) {
            winners[i] = regions[WEST].matchesRound2[(i - 30) % 4].winner;
        }
        // Round 3
        for (uint8 i = 42; i < 44; i++) {
            winners[i] = regions[WEST].matchesRound3[(i - 30) % 2].winner;
        }
        // Round 4
        winners[44] = regions[WEST].matchRound4.winner;

        // MIDWEST
        // Round 1
        for (uint8 i = 45; i < 53; i++) {
            winners[i] = regions[MIDWEST].matchesRound1[(i - 45) % 8].winner;
        }
        // Round 2
        for (uint8 i = 53; i < 57; i++) {
            winners[i] = regions[MIDWEST].matchesRound2[(i - 45) % 4].winner;
        }
        // Round 3
        for (uint8 i = 57; i < 59; i++) {
            winners[i] = regions[MIDWEST].matchesRound3[(i - 45) % 2].winner;
        }
        // Round 4
        winners[59] = regions[MIDWEST].matchRound4.winner;

        // Final Four
        winners[60] = finalFour.matchesRound1[0].winner;
        winners[61] = finalFour.matchesRound1[1].winner;
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
     * @dev Get the getFinalFour data
     * @return The data of the Final Four as FinalFour memory
     */
    function getFinalFour() external view returns (FinalFour memory) {
        return finalFour;
    }

    /**
     * @dev Checks if a match code belongs to the First Four
     * @param matchCode The code of the match
     * @return True if the match is part of the First Four, false otherwise
     */
    function _checkIsFfg(bytes memory matchCode) internal pure returns (bool) {
        return
            keccak256(matchCode) == keccak256(bytes("FFG1")) ||
            keccak256(matchCode) == keccak256(bytes("FFG2")) ||
            keccak256(matchCode) == keccak256(bytes("FFG3")) ||
            keccak256(matchCode) == keccak256(bytes("FFG4"));
    }
}
