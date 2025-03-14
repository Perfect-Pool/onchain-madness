/**
 * @title Second Round Games Update Script
 * @dev This script interacts with the Sports Radar API and OnchainMadnessFactory contract
 * to manage the Second Round games of the NCAA Tournament.
 * 
 * Functionality:
 * - Fetches current tournament data from Sports Radar API
 * - Processes games for each region (WEST, MIDWEST, SOUTH, EAST)
 * - Updates game results when games are completed
 * - Advances to next round when all games are decided
 * - Displays comprehensive state of all regions and their games
 * 
 * Regions:
 * - Each region contains 4 Second Round games
 * - Games are numbered 1-4 within each region
 * - Winners advance to Sweet 16
 */

const axios = require("axios");
const path = require("path");
const fs = require("fs");
const { ethers } = require("hardhat");
require("dotenv").config();

// Map to convert from API region names to contract region names
const REGION_NAME_MAP = {
  "West Regional": "WEST",
  "Midwest Regional": "MIDWEST",
  "South Regional": "SOUTH",
  "East Regional": "EAST"
};

async function decodeRegionData(regionBytes) {
  const abiCoder = new ethers.utils.AbiCoder();
  const [teams, matchesRound1, matchesRound2, matchesRound3, matchRound4, winner] = abiCoder.decode(
    ['string[16]', 'bytes[8]', 'bytes[4]', 'bytes[2]', 'bytes', 'string'],
    regionBytes
  );
  return { teams, matchesRound1, matchesRound2, matchesRound3, matchRound4, winner };
}

async function decodeMatchData(matchBytes) {
  const abiCoder = new ethers.utils.AbiCoder();
  const [home, away, homePoints, awayPoints, winner] = abiCoder.decode(
    ['string', 'string', 'uint256', 'uint256', 'string'],
    matchBytes
  );
  return { home, away, homePoints, awayPoints, winner };
}

async function main() {
  // Get contract data
  const variablesPath = path.join(__dirname, "..", "..", "contracts.json");
  const data = JSON.parse(fs.readFileSync(variablesPath, "utf8"));
  const networkName = hre.network.name;
  const networkData = data[networkName];
  const TOURNAMENT_YEAR = networkData.year;

  console.log(`Using network: ${networkName}`);
  console.log(`Contract address: ${networkData["OM_DEPLOYER"]}`);

  // Get contract instance
  const Factory = await ethers.getContractFactory("OnchainMadnessFactory", {
    libraries: {
      OnchainMadnessLib: networkData["Libraries"].OnchainMadnessLib,
    },
  });
  const contract = Factory.attach(networkData["OM_DEPLOYER"]);

  // Get initial regions data
  console.log("\nInitial Regions Data:");
  const initialRegionsData = await contract.getAllRegionsData(TOURNAMENT_YEAR);
  const decodedRegions = await Promise.all(
    initialRegionsData.map(async (regionData, index) => {
      const decoded = await decodeRegionData(regionData);
      const regionName = Object.values(REGION_NAME_MAP)[index];
      console.log(`\n=== ${regionName} REGION ===`);
      console.log(`Teams: ${decoded.teams.join(", ")}`);
      console.log(`\nSecond Round Matches for ${regionName}:`);
      await Promise.all(
        decoded.matchesRound2.map(async (match, i) => {
          const matchData = await decodeMatchData(match);
          console.log(`Game ${i + 1}: ${matchData.home} vs ${matchData.away}${matchData.winner ? ` - Winner: ${matchData.winner}` : ""}`);
        })
      );
      return decoded;
    })
  );

  try {
    const response = await axios.get(process.env.SPORTSRADAR_URL + `?year=${TOURNAMENT_YEAR}`);
    const secondRoundBrackets = response.data.rounds[2].bracketed;

    // Process each region
    for (const bracket of secondRoundBrackets) {
      const regionName = REGION_NAME_MAP[bracket.bracket.name];
      const regionIndex = Object.values(REGION_NAME_MAP).indexOf(regionName);
      const games = bracket.games;

      // Sort games by their game number
      games.sort((a, b) => {
        const aNum = parseInt(a.title.split("Game ")[1]);
        const bNum = parseInt(b.title.split("Game ")[1]);
        return aNum - bNum;
      });

      // Update match results
      console.log(`\nChecking ${regionName} games for updates...`);
      let decidedGames = 0;
      
      for (let i = 0; i < games.length; i++) {
        const game = games[i];
        if (game.status === "closed") {
          decidedGames++;
          const matchData = await decodeMatchData(decodedRegions[regionIndex].matchesRound2[i]);
          
          if (matchData.winner === "") {
            const homePoints = parseInt(game.home_points);
            const awayPoints = parseInt(game.away_points);
            const winner = game.home_points > game.away_points ? game.home.alias : game.away.alias;

            console.log(
              `Updating Game ${i + 1}: ${game.home.alias} ${homePoints} - ${awayPoints} ${game.away.alias}, Winner: ${winner}`
            );
            
            try{
              const tx = await contract.determineMatchWinner(
                TOURNAMENT_YEAR,
                regionName,
                winner,
                2, // round 2
                i, // match index
                homePoints,
                awayPoints
              );
              await tx.wait();
            }catch(error){
              console.log(`Game ${i + 1} already decided. Skipping...`);
            }
          }
        }
      }

      // If all games in the region are decided, check if we need to advance the round
      if (decidedGames === games.length) {
        console.log(`\nAll games in ${regionName} are decided`);
      }
    }

    // Check if all regions have all games decided
    const updatedRegionsData = await contract.getAllRegionsData(TOURNAMENT_YEAR);
    const allRegionsDecided = await Promise.all(
      updatedRegionsData.map(async (regionData) => {
        const decoded = await decodeRegionData(regionData);
        // Check if all matches in round 2 have winners
        const matchResults = await Promise.all(
          decoded.matchesRound2.map(async (match) => {
            const matchData = await decodeMatchData(match);
            return matchData.winner !== "";
          })
        );
        return matchResults.every(hasWinner => hasWinner);
      })
    );

    if (allRegionsDecided.every(regionDecided => regionDecided)) {
      console.log("\nAll second round games are decided. Advancing to next round...");
      const tx = await contract.advanceRound(TOURNAMENT_YEAR);
      await tx.wait();
    } else {
      console.log("\nNot all games are decided yet. Waiting for more results...");
    }

    // Print final state
    console.log("\nFinal Regions Data:");
    const finalRegionsData = await contract.getAllRegionsData(TOURNAMENT_YEAR);
    await Promise.all(
      finalRegionsData.map(async (regionData, index) => {
        const decoded = await decodeRegionData(regionData);
        const regionName = Object.values(REGION_NAME_MAP)[index];
        console.log(`\n=== ${regionName} REGION ===`);
        console.log(`Teams: ${decoded.teams.join(", ")}`);
        console.log(`\nSecond Round Matches for ${regionName}:`);
        await Promise.all(
          decoded.matchesRound2.map(async (match, i) => {
            const matchData = await decodeMatchData(match);
            console.log(`Game ${i + 1}: ${matchData.home} vs ${matchData.away}${matchData.winner ? ` - Winner: ${matchData.winner}` : ""}`);
          })
        );
      })
    );

  } catch (error) {
    console.error("Error:");
    console.error(error.response ? error.response.data : error.message);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
