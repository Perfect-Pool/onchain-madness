// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./OnchainMadness.sol";

/**
 * Interface for OnchainMadnessFactory
 */
interface IOnchainMadnessEntryFactory {
    function iterateYearTokens(uint256 _year) external;
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
     * @dev Emitted when the First Four winners are set for a tournament year
     * @param year The year of the tournament
     * @param winners Array of 4 team names that won the First Four matches
     */
    event FirstFourDecided(uint256 year, string[4] winners);
    /**
     * @dev Emitted when the tournament advances to the next round
     * @param year The year of the tournament
     * @param round The round number advanced to
     */
    event RoundAdvanced(uint256 year, uint8 round);
    /**
     * @dev Emitted when a tournament is marked as finished
     * @param year The year of the tournament
     */
    event TournamentFinished(uint256 year);
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
        address _executor
    ) Ownable(msg.sender) {
        implementation = _implementation;
        executor = _executor;
    }

    /**
     * @dev Modifier to restrict functions to the authorized executor
     */
    modifier onlyExecutor() {
        require(msg.sender == executor, "OMF-01");
        _;
    }

    /**
     * @dev Creates a new OnchainMadness contract for a specific year using the clone pattern
     * @param year The year of the tournament to create
     * @return The address of the newly created OnchainMadness contract
     */
    function createOnchainMadness(
        uint256 year
    ) public onlyExecutor returns (address) {
        address clone = Clones.clone(implementation);
        OnchainMadness(clone).initialize(year, address(this));
        emit OnchainMadnessCreated(clone, year);
        tournaments[year] = clone;
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
    function resetGame(uint256 year) public onlyExecutor {
        tournaments[year] = address(0);

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

        IOnchainMadnessEntryFactory(
            contracts("OM_ENTRY_DEPLOYER")
        ).iterateYearTokens(year);

        emit TournamentFinished(year);
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
}
