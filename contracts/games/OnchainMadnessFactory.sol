// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./OnchainMadness.sol";
import "../libraries/OnchainMadnessLib.sol";

interface IPerfectPool {
    function resetData(uint256 year) external;
}

/**
 * @title OnchainMadnessFactory
 * @author PerfectPool
 * @notice Factory contract for creating and managing NCAA Tournament bracket games
 * @dev Uses the clone pattern to deploy new tournament instances for each year
 */
contract OnchainMadnessFactory is Ownable {
    /** EVENTS **/
    /**
     * @dev Emitted when the betting period is closed for a tournament year
     * @param year The year of the tournament
     */
    event BetsClosed(uint256 year);
    /**
     * @dev Emitted when a First Four match is decided
     * @param year The year of the tournament
     * @param matchCode The code of the First Four match (FFG1-FFG4)
     * @param winner Name of the winning team
     */
    event FirstFourMatchDecided(uint256 year, string matchCode, string winner);

    /**
     * @dev Emitted when a match is decided
     * @param year The year of the tournament
     * @param regionName The name of the region
     * @param matchIndex Index of the match in the current round
     * @param _winner Winner of the match (1 for home, 2 for away)
     */
    event MatchDecided(
        uint256 year,
        string regionName,
        uint8 matchIndex,
        string _winner
    );

    /**
     * @dev Emitted when the final region is decided
     * @param year The year of the tournament
     * @param regionName The name of the region
     * @param winner The winner of the final region
     */
    event FinalRegionDecided(uint256 year, string regionName, string winner);
    /**
     * @dev Emitted when a final four match is decided
     * @param year The year of the tournament
     * @param gameIndex Index of the game in the final four
     * @param winners The winners of the game (home or away)
     */
    event FinalFourMatchDecided(uint256 year, uint8 gameIndex, string winners);
    /**
     * @dev Emitted when the tournament advances to the next round
     * @param year The year of the tournament
     * @param round The round number advanced to
     */
    event RoundAdvanced(uint256 year, uint8 round);
    /**
     * @dev Emitted when a tournament is marked as finished
     * @param year The year of the tournament
     * @param winner The winner of the tournament
     */
    event TournamentFinished(uint256 year, string winner);
    /**
     * @dev Emitted when a new OnchainMadness contract is created
     * @param proxy The address of the newly created OnchainMadness contract
     * @param year The year of the tournament
     */
    event OnchainMadnessCreated(address indexed proxy, uint256 year);
    /**
     * @dev Emitted when the executor address is changed
     * @param executor The new executor address
     */
    event ExecutorChanged(address indexed executor);
    /**
     * @dev Emitted when a tournament is reset to its initial state
     * @param year The year of the tournament
     */
    event TournamentReset(uint256 indexed year);
    /**
     * @dev Emitted when the paused state of the contract is changed
     * @param paused The new paused state
     */
    event Paused(bool paused);

    /** STRUCTS AND ENUMS **/
    /**
     * @dev Enum representing the status of a tournament
     */
    enum Status {
        Disabled,
        BetsOn,
        OnGoing,
        Finished
    }

    /** VARIABLES FOR MOCKED CONTRACT **/
    bool public immutable IS_MOCKED;
    uint256 mockedYear;
    uint256 mockedMonth;
    uint256 mockedDay;

    /** STATE VARIABLES **/
    /**
     * @dev Address of the OnchainMadness implementation contract
     */
    address public immutable implementation;
    /**
     * @dev Address authorized to execute tournament operations
     */
    address public executor;
    /**
     * @dev Last created tournament year
     */
    uint256 public lastCreatedTournament;
    /**
     * @dev Paused state of the contract
     */
    bool public paused = false;
    /**
     * @dev Mapping of contract addresses by name
     */
    mapping(bytes32 => address) private _contracts;
    /**
     * @dev Mapping of tournament addresses by year
     */
    mapping(uint256 => address) public tournaments;

    /**
     * @dev Constructor initializes the factory with implementation and executor addresses
     * @param _implementation Address of the OnchainMadness implementation contract
     * @param _executor Address authorized to execute tournament operations
     */
    constructor(
        address _implementation,
        address _executor,
        bool _isMocked
    ) Ownable(msg.sender) {
        implementation = _implementation;
        executor = _executor;
        IS_MOCKED = _isMocked;
        if (IS_MOCKED) {
            mockedYear = 2022;
            mockedMonth = 3;
            mockedDay = 1;
        }
    }

    /**
     * @dev Modifier to restrict functions to the authorized executor
     */
    modifier onlyExecutor() {
        require(msg.sender == executor, "OMF-01");
        _;
    }

    /**
     * @dev Set mocked date
     * @param _year The year of the mocked date
     * @param _month The month of the mocked date
     * @param _day The day of the mocked date
     */
    function setMockedDate(
        uint256 _year,
        uint256 _month,
        uint256 _day
    ) public onlyOwner {
        require(IS_MOCKED, "OMF-00");
        mockedYear = _year;
        mockedMonth = _month;
        mockedDay = _day;
    }

    /**
     * @dev Creates a new OnchainMadness contract for a specific year using the clone pattern
     * @param year The year of the tournament to create
     * @return The address of the newly created OnchainMadness contract
     */
    function createOnchainMadness(
        uint256 year
    ) public onlyOwner returns (address) {
        require(tournaments[year] == address(0), "OMF-02");
        (uint256 currentYear, , ) = getCurrentDate();
        require(year == currentYear, "OMF-03");
        require(!paused, "Contract is paused");

        address clone = Clones.clone(implementation);
        OnchainMadness(clone).initialize(year, address(this));
        emit OnchainMadnessCreated(clone, year);
        tournaments[year] = clone;
        lastCreatedTournament = year;
        return clone;
    }

    /**
     * @dev Sets a new executor address
     * @param _executor The new executor address
     */
    function setExecutor(address _executor) public onlyOwner {
        executor = _executor;

        emit ExecutorChanged(_executor);
    }

    /**
     * @dev Resets the address of the OnchainMadness contract for a specific year
     * @param year The year of the tournament
     */
    function resetGame(uint256 year) public onlyOwner {
        tournaments[year] = address(0);
        IPerfectPool(contracts("PERFECTPOOL")).resetData(year);

        emit TournamentReset(year);
    }

    /**
     * @dev Pause / unpause the contract
     * @param _paused The new paused state
     */
    function pause(bool _paused) public onlyOwner {
        paused = _paused;
        emit Paused(_paused);
    }

    /**
     * @dev Initializes a First Four match with two teams
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
        OnchainMadness(tournaments[year]).initFirstFourMatch(
            _matchCode,
            _home,
            _away
        );
    }

    /**
     * @dev Initializes a region with 16 teams and sets up first round matches
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
     * @dev Records the result of a First Four match and sets the winner
     * @param year The year of the tournament
     * @param matchCode The code of the First Four match (FFG1-FFG4)
     * @param _homePoints Points scored by the home team
     * @param _awayPoints Points scored by the away team
     * @param winner Name of the winning team
     */
    function determineFirstFourWinner(
        uint256 year,
        string memory matchCode,
        uint256 _homePoints,
        uint256 _awayPoints,
        string memory winner
    ) external onlyExecutor {
        require(!paused, "Contract is paused");
        OnchainMadness(tournaments[year]).determineFirstFourWinner(
            matchCode,
            _homePoints,
            _awayPoints,
            winner
        );
        emit FirstFourMatchDecided(year, matchCode, winner);
    }

    /**
     * @dev Closes the betting period and starts the tournament
     * @param year The year of the tournament
     */
    function closeBets(uint256 year) external onlyExecutor {
        require(!paused, "Contract is paused");
        OnchainMadness(tournaments[year]).closeBets();
        emit BetsClosed(year);
    }

    /**
     * @dev Advances the tournament to the next round
     * @param year The year of the tournament
     */
    function advanceRound(uint256 year) external onlyExecutor {
        require(!paused, "Contract is paused");
        OnchainMadness(tournaments[year]).advanceRound();
        emit RoundAdvanced(
            year,
            OnchainMadness(tournaments[year]).currentRound()
        );
    }

    /**
     * @dev Records the result of a match and sets up the next round match
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
        emit MatchDecided(year, regionName, matchIndex, winner);
    }

    /**
     * @dev Initializes the Final Four matches
     * @param year The year of the tournament
     * @param teamsRound1 Array of team names for the first round of Final Four
     */
    function initFinalFour(
        uint256 year,
        string[4] memory teamsRound1
    ) external onlyExecutor {
        require(!paused, "Contract is paused");
        OnchainMadness(tournaments[year]).initFinalFour(teamsRound1);
    }

    /**
     * @dev Records the result of a region's final match and sets up Final Four match
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
        emit FinalRegionDecided(year, regionName, winner);
    }

    /**
     * @dev Records the result of a Final Four match and sets up championship match
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
        emit FinalFourMatchDecided(year, gameIndex, winners);
    }

    /**
     * @dev Records the result of the championship match and completes the tournament
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

        emit TournamentFinished(year, winner);
    }

    /**
     * @dev Sets a contract address for a given name in the contracts mapping
     * @param _name The name identifier for the contract
     * @param _contract The address of the contract to set
     */
    function setContract(
        string memory _name,
        address _contract
    ) external onlyOwner {
        _contracts[keccak256(bytes(_name))] = _contract;
    }

    /**
     * @dev Retrieves a contract address by its name from the contracts mapping
     * @param _name The name identifier of the contract
     * @return The address of the requested contract
     */
    function contracts(string memory _name) public view returns (address) {
        return _contracts[keccak256(bytes(_name))];
    }

    /**
     * @dev Get the data for a specific region
     * * Region Data (encoded): string[16] teams, bytes[8] matchesRound1, bytes[4] matchesRound2, bytes[2] matchesRound3, bytes matchRound4, string winner
     * * Match Data (encoded): string home, string away, uint256 home_points, uint256 away_points, string winner
     * @param year The year of the tournament
     * @return The regions data in bytes format
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
     * @dev Get the data for the First Four
     * * First Four Data (encoded): bytes[4] matches
     * * Match Data (encoded): string home, string away, uint256 home_points, uint256 away_points, string winner
     * @param year The year of the tournament
     * @return The First Four data in bytes format
     */
    function getFirstFourData(
        uint256 year
    ) public view returns (bytes[4] memory) {
        return OnchainMadness(tournaments[year]).getFirstFourData();
    }

    /**
     * @dev Get the data for the Final Four
     * * Final Four Data (encoded): bytes[2] matchesRound1, bytes matchFinal, string winner
     * * Match Data (encoded): string home, string away, uint256 home_points, uint256 away_points, string winner
     * @param year The year of the tournament
     * @return The Final Four data in bytes format
     */
    function getFinalFourData(uint256 year) public view returns (bytes memory) {
        return OnchainMadness(tournaments[year]).getFinalFourData();
    }

    /**
     * @dev Get the round and game status for the current year
     * * Game Status (encoded): uint8 currentRound, uint8 status
     * @param year The year of the tournament
     * @return The current round and game status in bytes format
     */
    function getGameStatus(uint256 year) public view returns (bytes memory) {
        return
            abi.encode(
                OnchainMadness(tournaments[year]).currentRound(),
                OnchainMadness(tournaments[year]).status()
            );
    }

    /**
     * @dev Get if the last created tournament is finished
     * @param year The year of the tournament
     * @return True if the tournament is finished, false otherwise
     */
    function isFinished(uint256 year) public view returns (bool) {
        if (tournaments[year] == address(0)) return false;
        OnchainMadness.FinalFour memory finalFour = OnchainMadness(
            tournaments[year]
        ).getFinalFour();
        return finalFour.winner != 0;
    }

    /**
     * @dev Get the team names and IDs for all the regions in a specific year
     * * Teams (encoded): string[16] teams, uint8[16] teamsIds
     * @param year The year of the tournament
     * @return The team names IDs for all the regions in bytes format
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

    /**
     * @dev Retrieves the final result array of winner IDs for all matches in a tournament
     * @param year The year of the tournament
     * @return An array of 63 winner IDs representing all match results
     */
    function getFinalResult(
        uint256 year
    ) public view returns (uint8[63] memory) {
        return OnchainMadness(tournaments[year]).getFinalResult();
    }

    /**
     * @dev Converts an array of team IDs to their corresponding team symbols/names
     * @param year The year of the tournament
     * @param teamIds Array of team IDs to convert
     * @return Array of team symbols/names corresponding to the input IDs
     */
    function getTeamSymbols(
        uint256 year,
        uint8[63] memory teamIds
    ) public view returns (string[63] memory) {
        return OnchainMadness(tournaments[year]).getTeamSymbols(teamIds);
    }

    /**
     * @dev Get all the teams in a specific region
     * @param _region The name of the region
     * @return The names of the teams and their corresponding IDs
     */
    function getAllTeamIds(
        uint256 year,
        bytes32 _region
    ) public view returns (uint8[16] memory) {
        return OnchainMadness(tournaments[year]).getAllTeamIds(_region);
    }

    /**
     * @dev Get a Region data based on its name
     * @param _regionName The name of the region
     * @return The data of the region as Region memory
     */
    function getRegion(
        uint256 year,
        bytes32 _regionName
    ) external view returns (OnchainMadness.Region memory) {
        return OnchainMadness(tournaments[year]).getRegion(_regionName);
    }

    /**
     * @dev Get the Final Four data
     * @return The data of the Final Four as FinalFour memory
     */
    function getFinalFour(
        uint256 year
    ) external view returns (OnchainMadness.FinalFour memory) {
        return OnchainMadness(tournaments[year]).getFinalFour();
    }

    /**
     * @dev Get the name of a team based on its ID
     * @param year The year of the tournament
     * @param _teamId The ID of the team
     * @return The name of the team
     */
    function getTeamName(
        uint256 year,
        uint8 _teamId
    ) external view returns (string memory) {
        return OnchainMadness(tournaments[year]).getTeamName(_teamId);
    }

    /**
     * @dev Get the ID of a team based on its name
     * @param year The year of the tournament
     * @param _team The name of the team
     * @return The ID of the team
     */
    function getTeamId(
        uint256 year,
        string memory _team
    ) external view returns (uint8) {
        return OnchainMadness(tournaments[year]).getTeamId(_team);
    }

    /**
     * @notice Get the current day. If its mocked, returns the mocked date
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
        if (IS_MOCKED) return (mockedYear, mockedMonth, mockedDay);
        return OnchainMadnessLib.getCurrentDate();
    }

    /**
     * @notice Get the current timestamp. If its mocked, returns the mocked timestamp
     * @return The current timestamp
     */
    function getCurrentTimestamp() public view returns (uint256) {
        if (IS_MOCKED)
            return
                OnchainMadnessLib.dateToTimestamp(
                    mockedYear,
                    mockedMonth,
                    mockedDay
                );
        return block.timestamp;
    }
}
