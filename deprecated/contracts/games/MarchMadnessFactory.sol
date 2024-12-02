// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/IGamesHub.sol";
import "./MarchMadness.sol";

contract MarchMadnessFactory {
    /** EVENTS **/
    event BetsClosed(uint256 year);
    event FirstFourDecided(uint256 year, string[4] winners);
    event RoundAdvanced(uint256 year, uint8 round);
    event TournamentFinished(uint256 year);
    event MarchMadnessCreated(address indexed proxy, uint256 year);
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
    IGamesHub public immutable gamesHub;
    address public executor;
    bool public paused = false;

    mapping(uint256 => address) public tournaments;

    constructor(address _implementation, address _gamesHub, address _executor) {
        implementation = _implementation;
        gamesHub = IGamesHub(_gamesHub);
        executor = _executor;
    }

    modifier onlyExecutor() {
        require(msg.sender == executor, "MF-01");
        _;
    }

    modifier onlyAdministrator() {
        require(gamesHub.checkRole(keccak256("ADMIN"), msg.sender), "MF-02");
        _;
    }

    function createMarchMadness(
        uint256 year,
        string[8] memory _firstFour,
        string[16] memory _south,
        string[16] memory _west,
        string[16] memory _midwest,
        string[16] memory _east
    ) public onlyExecutor returns (address) {
        address clone = Clones.clone(implementation);
        MarchMadness(clone).initialize(
            year,
            _firstFour,
            _south,
            _west,
            _midwest,
            _east,
            address(gamesHub)
        );
        emit MarchMadnessCreated(clone, year);
        tournaments[year] = clone;
        return clone;
    }

    /**
     * @dev Determines the winners of the First Four matches.
     * @param year The year of the tournament.
     * @param teamNames The array of team names for the First Four matches.
     * @param scores The array of scores for the First Four matches.
     * @param winners The array of winners for the First Four matches.
     */
    function determineFirstFourWinners(
        uint256 year,
        string[8] memory teamNames,
        uint256[8] memory scores,
        string[4] memory winners
    ) public onlyExecutor {
        MarchMadness(tournaments[year]).determineFirstFourWinners(
            teamNames,
            scores,
            winners
        );

        emit FirstFourDecided(year, winners);
    }

    /**
     * @dev Opens the bets for the current year.
     * @param year The year of the tournament.
     */
    function closeBets(uint256 year) public onlyExecutor {
        MarchMadness(tournaments[year]).closeBets();

        emit BetsClosed(year);
    }

    /**
     * @dev Advances the round to the next one.
     * @param year The year of the tournament.
     */
    function advanceRound(uint256 year) public onlyExecutor {
        MarchMadness(tournaments[year]).advanceRound();
        emit RoundAdvanced(year, MarchMadness(tournaments[year]).currentRound());
    }

    /**
     * @dev Determines the winners of the Round 1 matches in a specific region.
     * @param year The year of the tournament.
     * @param regionName The name of the region.
     * @param teamNames The array of team names for the Round 1 matches.
     * @param scores The array of scores for the Round 1 matches.
     * @param winners The array of winners for the Round 1 matches.
     */
    function determineRound1Winners(
        uint256 year,
        string memory regionName,
        string[16] memory teamNames,
        uint256[16] memory scores,
        string[8] memory winners
    ) public onlyExecutor {
        MarchMadness(tournaments[year]).determineRound1Winners(
            regionName,
            teamNames,
            scores,
            winners
        );
    }

    /**
     * @dev Determines the winners of the Round 2 matches in a specific region and prepares Round 3 matches.
     * @param year The year of the tournament.
     * @param regionName The name of the region.
     * @param teamNames The array of team names for the Round 2 matches.
     * @param scores The array of scores for the Round 2 matches.
     * @param winners The array of winners for the Round 2 matches.
     */
    function determineRound2Winners(
        uint256 year,
        string memory regionName,
        string[8] memory teamNames,
        uint256[8] memory scores,
        string[4] memory winners
    ) public onlyExecutor {
        MarchMadness(tournaments[year]).determineRound2Winners(
            regionName,
            teamNames,
            scores,
            winners
        );
    }

    /**
     * @dev Determines the winners of the Round 3 matches in a specific region and prepares the Round 4 match.
     * @param year The year of the tournament.
     * @param regionName The name of the region.
     * @param teamNames The array of team names for the Round 3 matches.
     * @param scores The array of scores for the Round 3 matches.
     * @param winners The array of winners for the Round 3 matches.
     */
    function determineRound3Winners(
        uint256 year,
        string memory regionName,
        string[4] memory teamNames,
        uint256[4] memory scores,
        string[2] memory winners
    ) public onlyExecutor {
        MarchMadness(tournaments[year]).determineRound3Winners(
            regionName,
            teamNames,
            scores,
            winners
        );
    }

    /**
     * @dev Determines the winner of the Round 4 match in a specific region and prepares the team placement in the Final Four.
     * @param year The year of the tournament.
     * @param regionName The name of the region.
     * @param teamNameHome The team name for the home side of the Round 4 match.
     * @param teamNameAway The team name for the away side of the Round 4 match.
     * @param scoreHome The score for the home team in the Round 4 match.
     * @param scoreAway The score for the away team in the Round 4 match.
     * @param winner The winner of the Round 4 match.
     */
    function determineRound4Winners(
        uint256 year,
        string memory regionName,
        string memory teamNameHome,
        string memory teamNameAway,
        uint256 scoreHome,
        uint256 scoreAway,
        string memory winner
    ) public onlyExecutor {
        MarchMadness(tournaments[year]).determineRound4Winners(
            regionName,
            teamNameHome,
            teamNameAway,
            scoreHome,
            scoreAway,
            winner
        );
    }

    /**
     * @dev Determines the winners of the Final Four matches and prepares the championship match.
     * @param year The year of the tournament.
     * @param teamNames The array of team names for the Final Four matches.
     * @param scores The array of scores for the Final Four matches.
     * @param winners The array of winners for the Final Four matches.
     */
    function determineFinalFourWinners(
        uint256 year,
        string[4] memory teamNames,
        uint256[4] memory scores,
        string[2] memory winners
    ) public onlyExecutor {
        MarchMadness(tournaments[year]).determineFinalFourWinners(
            teamNames,
            scores,
            winners
        );
    }

    /**
     * @dev Determines the winner of the championship match.
     * @param year The year of the tournament.
     * @param teamNameHome The name of the home team in the championship match.
     * @param teamNameAway The name of the away team in the championship match.
     * @param scoreHome The score of the home team in the championship match.
     * @param scoreAway The score of the away team in the championship match.
     * @param winner The winner of the championship match.
     */
    function determineChampion(
        uint256 year,
        string memory teamNameHome,
        string memory teamNameAway,
        uint256 scoreHome,
        uint256 scoreAway,
        string memory winner
    ) public onlyExecutor {
        MarchMadness(tournaments[year]).determineChampion(
            teamNameHome,
            teamNameAway,
            scoreHome,
            scoreAway,
            winner
        );

        emit TournamentFinished(year);
    }

    /**
     * @dev Sets a new executor address.
     * @param _executor The address of the executor.
     */
    function setExecutor(address _executor) public onlyAdministrator {
        executor = _executor;

        emit ExecutorChanged(_executor);
    }

    /**
     * @dev Resets the address of the MarchMadness contract for a specific year.
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
    function pause(bool _paused) public onlyAdministrator {
        paused = _paused;
        emit Paused(_paused);
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
        MarchMadness tournament = MarchMadness(tournaments[year]);
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
        return MarchMadness(tournaments[year]).getFirstFourData();
    }

    /**
     * @dev Get the data for the Final Four.
     * * Final Four Data (encoded): bytes[2] matchesRound1, bytes matchFinal, string winner
     * * Match Data (encoded): string home, string away, uint256 home_points, uint256 away_points, string winner
     * @param year The year of the tournament.
     * @return The Final Four data in bytes format.
     */
    function getFinalFourData(uint256 year) public view returns (bytes memory) {
        return MarchMadness(tournaments[year]).getFinalFourData();
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
                MarchMadness(tournaments[year]).currentRound(),
                MarchMadness(tournaments[year]).status()
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
        allTeams[0] = MarchMadness(tournaments[year]).getAllTeams(
            keccak256("SOUTH")
        );
        allTeams[1] = MarchMadness(tournaments[year]).getAllTeams(
            keccak256("WEST")
        );
        allTeams[2] = MarchMadness(tournaments[year]).getAllTeams(
            keccak256("MIDWEST")
        );
        allTeams[3] = MarchMadness(tournaments[year]).getAllTeams(
            keccak256("EAST")
        );

        return allTeams;
    }

    function getFinalResult(
        uint256 year
    ) public view returns (uint8[63] memory) {
        return MarchMadness(tournaments[year]).getFinalResult();
    }

    function getTeamSymbols(
        uint256 year,
        uint8[63] memory teamIds
    ) public view returns (string[63] memory) {
        return MarchMadness(tournaments[year]).getTeamSymbols(teamIds);
    }
}
