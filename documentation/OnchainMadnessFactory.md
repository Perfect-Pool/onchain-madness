# OnchainMadnessFactory

Factory contract for creating and managing NCAA Tournament bracket games. Uses the clone pattern to deploy new tournament instances for each year.

## Events

- **BetsClosed**: Emitted when the betting period is closed for a tournament year
    - `year`: `uint256` - The year of the tournament
- **FirstFourMatchDecided**: Emitted when a First Four match is decided
    - `year`: `uint256` - The year of the tournament
    - `matchCode`: `string` - The code of the First Four match (FFG1-FFG4)
    - `_winner`: `uint8` - Winner of the match (1 for home, 2 for away)
- **MatchDecided**: Emitted when a match is decided
    - `year`: `uint256` - The year of the tournament
    - `regionName`: `string` - The name of the region
    - `matchIndex`: `uint8` - Index of the match in the current round
    - `_winner`: `string` - Winner of the match
- **FinalRegionDecided**: Emitted when the final region is decided
    - `year`: `uint256` - The year of the tournament
    - `regionName`: `string` - The name of the region
    - `winner`: `string` - The winner of the final region
- **FinalFourMatchDecided**: Emitted when a final four match is decided
    - `year`: `uint256` - The year of the tournament
    - `gameIndex`: `uint8` - Index of the game in the final four
    - `winners`: `string` - The winners of the game
- **RoundAdvanced**: Emitted when the tournament advances to the next round
    - `year`: `uint256` - The year of the tournament
    - `round`: `uint8` - The round number advanced to
- **TournamentFinished**: Emitted when a tournament is marked as finished
    - `year`: `uint256` - The year of the tournament
    - `winner`: `string` - The winner of the tournament
- **OnchainMadnessCreated**: Emitted when a new OnchainMadness contract is created
    - `proxy`: `address` - The address of the newly created OnchainMadness contract
    - `year`: `uint256` - The year of the tournament
- **ExecutorChanged**: Emitted when the executor address is changed
    - `executor`: `address` - The new executor address
- **TournamentReset**: Emitted when a tournament is reset to its initial state
    - `year`: `uint256` - The year of the tournament
- **Paused**: Emitted when the paused state of the contract is changed
    - `paused`: `bool` - The new paused state

## Enums

- **Status**: Represents the status of a tournament
    - `Disabled`: Tournament is disabled
    - `BetsOn`: Betting period is active
    - `OnGoing`: Tournament is in progress
    - `Finished`: Tournament is completed

## State Variables

- **implementation**: `address public immutable` - Address of the OnchainMadness implementation contract
- **executor**: `address public` - Address authorized to execute tournament operations
- **lastCreatedTournament**: `uint256 public` - Last created tournament year
- **paused**: `bool public` - Paused state of the contract
- **tournaments**: `mapping(uint256 => address) public` - Mapping of tournament addresses by year

## Modifiers

- `onlyExecutor()`: Restricts function access to the authorized executor

## Functions

### Constructor

- Description: Initializes the factory with implementation and executor addresses
- Arguments:
    - `_implementation`: `address` - Address of the OnchainMadness implementation contract
    - `_executor`: `address` - Address authorized to execute tournament operations

### createOnchainMadness

- Description: Creates a new OnchainMadness contract for a specific year using the clone pattern
- Arguments:
    - `year`: `uint256` - The year of the tournament to create
- Returns: `address` - The address of the newly created OnchainMadness contract
- Modifiers:
    - `onlyExecutor`: Restricted to authorized executor

### setExecutor

- Description: Sets a new executor address
- Arguments:
    - `_executor`: `address` - The new executor address
- Modifiers:
    - `onlyOwner`: Restricted to contract owner

### resetGame

- Description: Resets the address of the OnchainMadness contract for a specific year
- Arguments:
    - `year`: `uint256` - The year of the tournament
- Modifiers:
    - `onlyExecutor`: Restricted to authorized executor

### pause

- Description: Pause or unpause the contract
- Arguments:
    - `_paused`: `bool` - The new paused state
- Modifiers:
    - `onlyOwner`: Restricted to contract owner

### initFirstFourMatch

- Description: Initializes a First Four match with two teams
- Arguments:
    - `year`: `uint256` - The year of the tournament
    - `_matchCode`: `string` - The code identifying the First Four match (FFG1-FFG4)
    - `_home`: `string` - The name of the home team
    - `_away`: `string` - The name of the away team
- Modifiers:
    - `onlyExecutor`: Restricted to authorized executor

### initRegion

- Description: Initializes a region with 16 teams and sets up first round matches
- Arguments:
    - `year`: `uint256` - The year of the tournament
    - `_regionName`: `string` - The name of the region (SOUTH, WEST, MIDWEST, EAST)
    - `teamNames`: `string[16]` - Array of 16 team names for the region, ordered by seeding
- Modifiers:
    - `onlyExecutor`: Restricted to authorized executor

### determineFirstFourWinner

- Description: Records the result of a First Four match and sets the winner
- Arguments:
    - `year`: `uint256` - The year of the tournament
    - `matchCode`: `string` - The code of the First Four match (FFG1-FFG4)
    - `_homePoints`: `uint256` - Points scored by the home team
    - `_awayPoints`: `uint256` - Points scored by the away team
    - `_winner`: `uint8` - Winner of the match (1 for home, 2 for away)
- Modifiers:
    - `onlyExecutor`: Restricted to authorized executor

### closeBets

- Description: Closes the betting period and starts the tournament
- Arguments:
    - `year`: `uint256` - The year of the tournament
- Modifiers:
    - `onlyExecutor`: Restricted to authorized executor

### advanceRound

- Description: Advances the tournament to the next round
- Arguments:
    - `year`: `uint256` - The year of the tournament
- Modifiers:
    - `onlyExecutor`: Restricted to authorized executor

### determineMatchWinner

- Description: Records the result of a match and sets up the next round match
- Arguments:
    - `year`: `uint256` - The year of the tournament
    - `regionName`: `string` - The name of the region
    - `winner`: `string` - The name of the winning team
    - `round`: `uint8` - Current round number (1-4)
    - `matchIndex`: `uint8` - Index of the match in the current round
    - `homePoints`: `uint256` - Points scored by home team
    - `awayPoints`: `uint256` - Points scored by away team
- Modifiers:
    - `onlyExecutor`: Restricted to authorized executor

### determineFinalRegionWinner

- Description: Records the result of a region's final match and sets up Final Four match
- Arguments:
    - `year`: `uint256` - The year of the tournament
    - `regionName`: `string` - The name of the region
    - `winner`: `string` - The name of the winning team
    - `homePoints`: `uint256` - Points scored by home team
    - `awayPoints`: `uint256` - Points scored by away team
- Modifiers:
    - `onlyExecutor`: Restricted to authorized executor

### determineFinalFourWinner

- Description: Records the result of a Final Four match and sets up championship match
- Arguments:
    - `year`: `uint256` - The year of the tournament
    - `gameIndex`: `uint8` - Index of the Final Four match (0 or 1)
    - `winners`: `string` - The name of the winning team
    - `homePoints`: `uint256` - Points scored by home team
    - `awayPoints`: `uint256` - Points scored by away team
- Modifiers:
    - `onlyExecutor`: Restricted to authorized executor

### determineChampion

- Description: Records the result of the championship match and completes the tournament
- Arguments:
    - `year`: `uint256` - The year of the tournament
    - `winner`: `string` - The name of the winning team
    - `homePoints`: `uint256` - Points scored by home team
    - `awayPoints`: `uint256` - Points scored by away team
- Modifiers:
    - `onlyExecutor`: Restricted to authorized executor

### setContract

- Description: Sets a contract address for a given name in the contracts mapping
- Arguments:
    - `_name`: `string` - The name identifier for the contract
    - `_contract`: `address` - The address of the contract to set
- Modifiers:
    - `onlyOwner`: Restricted to contract owner

### contracts

- Description: Retrieves a contract address by its name from the contracts mapping
- Arguments:
    - `_name`: `string` - The name identifier of the contract
- Returns: `address` - The address of the requested contract

### getAllRegionsData

- Description: Get the data for all regions
- Arguments:
    - `year`: `uint256` - The year of the tournament
- Returns: `bytes[4]` - The regions data in bytes format
- Notes: Region Data (encoded): string[16] teams, bytes[8] matchesRound1, bytes[4] matchesRound2, bytes[2] matchesRound3, bytes matchRound4, string winner

### getFirstFourData

- Description: Get the data for the First Four
- Arguments:
    - `year`: `uint256` - The year of the tournament
- Returns: `bytes[4]` - The First Four data in bytes format
- Notes: Match Data (encoded): string home, string away, uint256 home_points, uint256 away_points, string winner

### getFinalFourData

- Description: Get the data for the Final Four
- Arguments:
    - `year`: `uint256` - The year of the tournament
- Returns: `bytes` - The Final Four data in bytes format
- Notes: Final Four Data (encoded): bytes[2] matchesRound1, bytes matchFinal, string winner

### getGameStatus

- Description: Get the round and game status for the current year
- Arguments:
    - `year`: `uint256` - The year of the tournament
- Returns: `bytes` - The current round and game status in bytes format
- Notes: Game Status (encoded): uint8 currentRound, uint8 status

### isFinished

- Description: Get if the last created tournament is finished
- Arguments:
    - `year`: `uint256` - The year of the tournament
- Returns: `bool` - True if the tournament is finished, false otherwise

### getAllTeamsIdsNames

- Description: Get the team names and IDs for all the regions in a specific year
- Arguments:
    - `year`: `uint256` - The year of the tournament
- Returns: `bytes[4]` - The team names IDs for all the regions in bytes format
- Notes: Teams (encoded): string[16] teams, uint8[16] teamsIds

### getFinalResult

- Description: Retrieves the final result array of winner IDs for all matches in a tournament
- Arguments:
    - `year`: `uint256` - The year of the tournament
- Returns: `uint8[63]` - An array of 63 winner IDs representing all match results

### getTeamSymbols

- Description: Converts an array of team IDs to their corresponding team symbols/names
- Arguments:
    - `year`: `uint256` - The year of the tournament
    - `teamIds`: `uint8[63]` - Array of team IDs to convert
- Returns: `string[63]` - Array of team symbols/names corresponding to the input IDs

### getAllTeamIds

- Description: Get all the teams in a specific region
- Arguments:
    - `year`: `uint256` - The year of the tournament
    - `_region`: `bytes32` - The name of the region
- Returns: `uint8[16]` - The IDs of the teams in the region

### getRegion

- Description: Get a Region data based on its name
- Arguments:
    - `year`: `uint256` - The year of the tournament
    - `_regionName`: `bytes32` - The name of the region
- Returns: `OnchainMadness.Region` - The data of the region

### getMatch

- Description: Get a match data based on its ID
- Arguments:
    - `year`: `uint256` - The year of the tournament
    - `_matchId`: `uint8` - The ID of the match
- Returns: `OnchainMadness.Match` - The data of the match

### getFinalFour

- Description: Get the Final Four data
- Arguments:
    - `year`: `uint256` - The year of the tournament
- Returns: `OnchainMadness.FinalFour` - The data of the Final Four

### getTeamName

- Description: Get the name of a team based on its ID
- Arguments:
    - `year`: `uint256` - The year of the tournament
    - `_teamId`: `uint8` - The ID of the team
- Returns: `string` - The name of the team