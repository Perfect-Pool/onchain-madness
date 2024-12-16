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
    - `_winner`: `string` - Winner of the match (1 for home, 2 for away)

- **FinalRegionDecided**: Emitted when the final region is decided
    - `year`: `uint256` - The year of the tournament
    - `regionName`: `string` - The name of the region
    - `winner`: `string` - The winner of the final region

- **FinalFourMatchDecided**: Emitted when a final four match is decided
    - `year`: `uint256` - The year of the tournament
    - `gameIndex`: `uint8` - Index of the game in the final four
    - `winners`: `string` - The winners of the game (home or away)

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

- Description: Creates a new OnchainMadness contract for a specific year using the clone pattern. Returns the address of the new contract.
- Arguments:
    - `year`: `uint256` - The year of the tournament to create
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

### setFirstFourWinner

- Description: Records the result of a First Four match and sets the winner
- Arguments:
    - `year`: `uint256` - The year of the tournament
    - `matchCode`: `string` - The code of the First Four match (FFG1-FFG4)
    - `_homeId`: `uint256` - ID of the home team
    - `_awayId`: `uint256` - ID of the away team
    - `_homePoints`: `uint256` - Points scored by the home team
    - `_awayPoints`: `uint256` - Points scored by the away team
- Modifiers:
    - `onlyExecutor`: Restricted to authorized executor

### getFirstFourWinners

- Description: Retrieves the winners of the First Four matches for a specific year
- Arguments:
    - `year`: `uint256` - The year of the tournament
- Returns: `string[4]` - Array of team names that won the First Four matches

### getGameStatus

- Description: Retrieves the status of a tournament for a specific year
- Arguments:
    - `year`: `uint256` - The year of the tournament
- Returns: `bytes` - ABI-encoded data containing:
    - `round`: `uint8` - Current round of the tournament
    - `status`: `uint8` - Current status from the Status enum

### getRegionTeams

- Description: Retrieves all teams in a specific region
- Arguments:
    - `year`: `uint256` - The year of the tournament
    - `region`: `string` - Name of the region (SOUTH, WEST, MIDWEST, EAST)
- Returns: `bytes` - ABI-encoded data containing:
    - `teams`: `string[16]` - Array of team names in the region
    - `teamsIds`: `uint8[16]` - Array of team IDs corresponding to the team names

### getAllTeams

- Description: Retrieves teams from all regions
- Arguments:
    - `year`: `uint256` - The year of the tournament
- Returns: `bytes[4]` - Array of ABI-encoded data, one for each region (SOUTH, WEST, MIDWEST, EAST), each containing:
    - `teams`: `string[16]` - Array of team names in the region
    - `teamsIds`: `uint8[16]` - Array of team IDs corresponding to the team names

### getAllRegionsData

- Description: Get the complete data for all regions in a tournament year
- Parameters:
  - `year`: `uint256` - The year of the tournament
- Returns: `bytes[4]` - Array containing encoded data for each region (South, West, Midwest, East)
  - Region Data encoding:
    - `string[16]` teams - Array of team names in the region
    - `bytes[8]` matchesRound1 - First round matches
    - `bytes[4]` matchesRound2 - Second round matches
    - `bytes[2]` matchesRound3 - Third round matches
    - `bytes` matchRound4 - Fourth round match
    - `string` winner - Region winner
  - Match Data encoding:
    - `string` home - Home team name
    - `string` away - Away team name
    - `uint256` home_points - Home team points
    - `uint256` away_points - Away team points
    - `string` winner - Winner team name

### getFirstFourData

- Description: Get the complete data for the First Four matches
- Parameters:
  - `year`: `uint256` - The year of the tournament
- Returns: `bytes[4]` - Array containing encoded data for each First Four match
  - Match Data encoding:
    - `string` home - Home team name
    - `string` away - Away team name
    - `uint256` home_points - Home team points
    - `uint256` away_points - Away team points
    - `string` winner - Winner team name

### getFinalResult

- Description: Retrieves the final result array of winner IDs for all matches in a tournament
- Parameters:
  - `year`: `uint256` - The year of the tournament
- Returns: `uint8[63]` - Array of winner IDs representing all match results

### getTeamSymbols

- Description: Converts an array of team IDs to their corresponding team symbols/names
- Parameters:
  - `year`: `uint256` - The year of the tournament
  - `teamIds`: `uint8[63]` - Array of team IDs to convert
- Returns: `string[63]` - Array of team symbols/names corresponding to the input IDs

### getFinalFourData

- Description: Returns the Final Four match data
- Arguments:
    - `year`: `uint256` - The year of the tournament
- Returns: `bytes` - ABI-encoded data containing:
    - `matchesRound1`: `bytes[2]` - First round matches data
    - `matchFinal`: `bytes` - Final match data
    - `winner`: `string` - Name of the winning team
    - Each match data contains:
        - `home`: `string` - Home team name
        - `away`: `string` - Away team name
        - `home_points`: `uint256` - Points scored by home team
        - `away_points`: `uint256` - Points scored by away team
        - `winner`: `string` - Name of the winning team

### getAllTeamsIdsNames

- Description: Returns team names and IDs for all regions
- Arguments:
    - `year`: `uint256` - The year of the tournament
- Returns: `bytes[4]` - Array of ABI-encoded data for each region (SOUTH, WEST, MIDWEST, EAST), each containing:
    - `teams`: `string[16]` - Array of team names in the region
    - `teamsIds`: `uint8[16]` - Array of team IDs corresponding to the team names

### getGameStatus

- Description: Returns the status of a tournament for a specific year
- Arguments:
    - `year`: `uint256` - The year of the tournament
- Returns: `bytes` - ABI-encoded data containing:
    - `currentRound`: `uint8` - Current round of the tournament
    - `status`: `uint8` - Current status (0: Disabled, 1: BetsOn, 2: OnGoing, 3: Finished)
