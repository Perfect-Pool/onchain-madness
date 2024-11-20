// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./OnchainMadness.sol";

contract OnchainMadnessFactory is Ownable {
    /** EVENTS **/
    event BetsClosed(uint256 year);
    event FirstFourDecided(uint256 year, string[4] winners);
    event RoundAdvanced(uint256 year, uint8 round);
    event TournamentFinished(uint256 year);
    event OnchainMadnessCreated(address indexed proxy, uint256 year);
    event ExecutorChanged(address indexed executor);
    event TournamentReset(uint256 indexed year);
    event Paused(bool paused);

    /** STRUCTS AND ENUMS **/
    enum Status {
        Disabled,
        BetsOn,
        OnGoing,
        Finished
    }

    /** STATE VARIABLES **/
    address public immutable implementation;
    address public executor;
    bool public paused = false;

    mapping(uint256 => address) public tournaments;

    constructor(address _implementation, address _executor) Ownable(msg.sender) {
        implementation = _implementation;
        executor = _executor;
    }

    modifier onlyExecutor() {
        require(msg.sender == executor, "MF-01");
        _;
    }

    function createOnchainMadness(
        uint256 year
    ) public onlyExecutor returns (address) {
        address clone = Clones.clone(implementation);
        OnchainMadness(clone).initialize(
            year,
            address(this)
        );
        emit OnchainMadnessCreated(clone, year);
        tournaments[year] = clone;
        return clone;
    }

    /**
     * @dev Sets a new executor address.
     * @param _executor The address of the executor.
     */
    function setExecutor(address _executor) public onlyOwner {
        executor = _executor;

        emit ExecutorChanged(_executor);
    }

    /**
     * @dev Resets the address of the OnchainMadness contract for a specific year.
     * @param year The year of the tournament.
     */
    function resetGame(uint256 year) public onlyExecutor {
        tournaments[year] = address(0);

        emit TournamentReset(year);
    }

    /**
     * @dev Pause / unpause the contract.
     * @param _paused The new paused state.
     */
    function pause(bool _paused) public onlyOwner {
        paused = _paused;
        emit Paused(_paused);
    }

    /**
     * @dev Initializes a First Four match with two teams.
     * @param year The year of the tournament
     * @param _matchCode The code identifying the First Four match (FFG1-FFG4)
     * @param _home The name of the home team
     * @param _away The name of the away team
     */
    function initFirstFourMatch(
        uint256 year,
        string memory _matchCode,
        string memory _home,
        string memory _away
    ) external onlyExecutor {
        require(!paused, "Contract is paused");
        OnchainMadness(tournaments[year]).initFirstFourMatch(_matchCode, _home, _away);
    }

    /**
     * @dev Initializes a region with 16 teams and sets up first round matches.
     * @param year The year of the tournament
     * @param _regionName The name of the region (SOUTH, WEST, MIDWEST, EAST)
     * @param teamNames Array of 16 team names for the region, ordered by seeding
     */
    function initRegion(
        uint256 year,
        string memory _regionName,
        string[16] memory teamNames
    ) external onlyExecutor {
        require(!paused, "Contract is paused");
        OnchainMadness(tournaments[year]).initRegion(_regionName, teamNames);
    }

    /**
     * @dev Records the result of a First Four match and sets the winner.
     * @param year The year of the tournament
     * @param matchCode The code of the First Four match (FFG1-FFG4)
     * @param _homeId ID of the home team
     * @param _awayId ID of the away team
     * @param _homePoints Points scored by the home team
     * @param _awayPoints Points scored by the away team
     * @param _winner Winner of the match (1 for home, 2 for away)
     */
    function determineFirstFourWinner(
        uint256 year,
        string memory matchCode,
        uint8 _homeId,
        uint8 _awayId,
        uint256 _homePoints,
        uint256 _awayPoints,
        uint8 _winner
    ) external onlyExecutor {
        require(!paused, "Contract is paused");
        OnchainMadness(tournaments[year]).determineFirstFourWinner(
            matchCode,
            _homeId,
            _awayId,
            _homePoints,
            _awayPoints,
            _winner
        );
    }

    /**
     * @dev Closes the betting period and starts the tournament.
     * @param year The year of the tournament
     */
    function closeBets(uint256 year) external onlyExecutor {
        require(!paused, "Contract is paused");
        OnchainMadness(tournaments[year]).closeBets();
        emit BetsClosed(year);
    }

    /**
     * @dev Advances the tournament to the next round.
     * @param year The year of the tournament
     */
    function advanceRound(uint256 year) external onlyExecutor {
        require(!paused, "Contract is paused");
        OnchainMadness(tournaments[year]).advanceRound();
        emit RoundAdvanced(year, OnchainMadness(tournaments[year]).currentRound());
    }

    /**
     * @dev Records the result of a match and sets up the next round match.
     * @param year The year of the tournament
     * @param regionName The name of the region
     * @param winner The name of the winning team
     * @param round Current round number (1-4)
     * @param matchIndex Index of the match in the current round
     * @param homePoints Points scored by home team
     * @param awayPoints Points scored by away team
     */
    function determineMatchWinner(
        uint256 year,
        string memory regionName,
        string memory winner,
        uint8 round,
        uint8 matchIndex,
        uint256 homePoints,
        uint256 awayPoints
    ) external onlyExecutor {
        require(!paused, "Contract is paused");
        OnchainMadness(tournaments[year]).determineMatchWinner(
            regionName,
            winner,
            round,
            matchIndex,
            homePoints,
            awayPoints
        );
    }

    /**
     * @dev Records the result of a region's final match and sets up Final Four match.
     * @param year The year of the tournament
     * @param regionName The name of the region
     * @param winner The name of the winning team
     * @param homePoints Points scored by home team
     * @param awayPoints Points scored by away team
     */
    function determineFinalRegionWinner(
        uint256 year,
        string memory regionName,
        string memory winner,
        uint256 homePoints,
        uint256 awayPoints
    ) external onlyExecutor {
        require(!paused, "Contract is paused");
        OnchainMadness(tournaments[year]).determineFinalRegionWinner(
            regionName,
            winner,
            homePoints,
            awayPoints
        );
    }

    /**
     * @dev Records the result of a Final Four match and sets up championship match.
     * @param year The year of the tournament
     * @param gameIndex Index of the Final Four match (0 or 1)
     * @param winners The name of the winning team
     * @param homePoints Points scored by home team
     * @param awayPoints Points scored by away team
     */
    function determineFinalFourWinner(
        uint256 year,
        uint8 gameIndex,
        string memory winners,
        uint256 homePoints,
        uint256 awayPoints
    ) external onlyExecutor {
        require(!paused, "Contract is paused");
        OnchainMadness(tournaments[year]).determineFinalFourWinner(
            gameIndex,
            winners,
            homePoints,
            awayPoints
        );
    }

    /**
     * @dev Records the result of the championship match and completes the tournament.
     * @param year The year of the tournament
     * @param winner The name of the winning team
     * @param homePoints Points scored by home team
     * @param awayPoints Points scored by away team
     */
    function determineChampion(
        uint256 year,
        string memory winner,
        uint256 homePoints,
        uint256 awayPoints
    ) external onlyExecutor {
        require(!paused, "Contract is paused");
        OnchainMadness(tournaments[year]).determineChampion(
            winner,
            homePoints,
            awayPoints
        );
        emit TournamentFinished(year);
    }

    /**
     * @dev Get the data for a specific region.
     * * Region Data (encoded): string[16] teams, bytes[8] matchesRound1, bytes[4] matchesRound2, bytes[2] matchesRound3, bytes matchRound4, string winner
     * * Match Data (encoded): string home, string away, uint256 home_points, uint256 away_points, string winner
     * @param year The year of the tournament.
     * @return The regions data in bytes format.
     */
    function getAllRegionsData(
        uint256 year
    ) public view returns (bytes[4] memory) {
        OnchainMadness tournament = OnchainMadness(tournaments[year]);
        return [
            tournament.getRegionData(tournament.SOUTH()),
            tournament.getRegionData(tournament.WEST()),
            tournament.getRegionData(tournament.MIDWEST()),
            tournament.getRegionData(tournament.EAST())
        ];
    }

    /**
     * @dev Get the data for the First Four.
     * * First Four Data (encoded): bytes[4] matches
     * * Match Data (encoded): string home, string away, uint256 home_points, uint256 away_points, string winner
     * @return The First Four data in bytes format.
     */
    function getFirstFourData(
        uint256 year
    ) public view returns (bytes[4] memory) {
        return OnchainMadness(tournaments[year]).getFirstFourData();
    }

    /**
     * @dev Get the data for the Final Four.
     * * Final Four Data (encoded): bytes[2] matchesRound1, bytes matchFinal, string winner
     * * Match Data (encoded): string home, string away, uint256 home_points, uint256 away_points, string winner
     * @param year The year of the tournament.
     * @return The Final Four data in bytes format.
     */
    function getFinalFourData(uint256 year) public view returns (bytes memory) {
        return OnchainMadness(tournaments[year]).getFinalFourData();
    }

    /**
     * @dev Get the round and game status for the current year.
     * * Game Status (encoded): uint8 currentRound, uint8 status
     * @param year The year of the tournament.
     * @return The current round and game status in bytes format.
     */
    function getGameStatus(uint256 year) public view returns (bytes memory) {
        return
            abi.encode(
                OnchainMadness(tournaments[year]).currentRound(),
                OnchainMadness(tournaments[year]).status()
            );
    }

    /**
     * @dev Get the team names and IDs for all the regions in a specific year.
     * * Teams (encoded): string[16] teams, uint8[16] teamsIds
     * @param year The year of the tournament.
     * @return The team names IDs for all the regions in bytes format.
     */
    function getAllTeamsIdsNames(
        uint256 year
    ) public view returns (bytes[4] memory) {
        bytes[4] memory allTeams;
        allTeams[0] = OnchainMadness(tournaments[year]).getAllTeams(
            keccak256("SOUTH")
        );
        allTeams[1] = OnchainMadness(tournaments[year]).getAllTeams(
            keccak256("WEST")
        );
        allTeams[2] = OnchainMadness(tournaments[year]).getAllTeams(
            keccak256("MIDWEST")
        );
        allTeams[3] = OnchainMadness(tournaments[year]).getAllTeams(
            keccak256("EAST")
        );

        return allTeams;
    }

    function getFinalResult(
        uint256 year
    ) public view returns (uint8[63] memory) {
        return OnchainMadness(tournaments[year]).getFinalResult();
    }

    function getTeamSymbols(
        uint256 year,
        uint8[63] memory teamIds
    ) public view returns (string[63] memory) {
        return OnchainMadness(tournaments[year]).getTeamSymbols(teamIds);
    }
}
