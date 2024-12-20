On this Solidity smart contract, we need to check the results of a bet in a bracketed version of NCAA basketball tournament. 
- The tournament is divided by 4 regions, each one with 8 initial matches of two teams. 
- When a team wins, it goes to the next round, where 4 matches decides who goes to the next round
- the third round has 2 matches
- one final match decides the final result of the region
- On the Final Four phase, the winners of the four regions are placed as brackets on this way:
	- East winner as home team X West winner as away team
	- South winner as home team X Midwest winner as away team
	- The winner of the first match is the home team for the last match 
	- The winner of the second is the away team for the last match

This BetCheck contract receives the data from the game to build the results variables for the NFT where the bet will be placed. Let's first build the regionCheck() function:
- `regionTeams` is an array of team IDs, the first 16 teams of the region. 
	- The odd indexes are the home teams of the 8 first matches. 
	- The even indexes are the away teams. 
	- The indexes are in order of the matches: Game 1 is 0 vs 1, Game 2 is 2 vs 3, and so on 
	- Use this array to build betTeamNames, as many matches may not have the home and away teams defined in the early stages of the game
- `bets` is an array of values as 0 or 1, where 0 means victory for the home team and 1 for the away team.
- `start` shows the index for `bets` array that we will start to check
- `points` is the variable that shows how many points the player made (max points: 63)
- `betResults` is an array of 0, 1 or 2; where 0 is match not defined, 1 is home victory, 2 is away victory
- `betTeamNames` is the names of the teams the player choose as winners. It can be got using getTeamName() function

To check on the results, you may use getMatch() with the ID got from the arrays of matches, accordingly to the round you are checking. Check on betResultCalculate() to understand the logic

Pay attention to `Stack too deep` error for Solidity compiler. Do not declare uneeded variable, and avoid to declare them twice. Do not use `match` as variable name, it's a reserved word in solidity.

You may need to build other internal functions to simplify the logic. The final goal is to correctly build the variables betTeamNames, betResults and points.

FIRST GOAL: Build regionCheck() function until the end for me