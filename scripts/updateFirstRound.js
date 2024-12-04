/**
 * @title First Round Games Update Script
 * @dev This script interacts with the Sports Radar API and OnchainMadnessFactory contract
 * to manage the First Round games of the NCAA Tournament.
 * 
 * Functionality:
 * - Fetches current tournament data from Sports Radar API
 * - Processes games for each region (WEST, MIDWEST, SOUTH, EAST)
 * - Initializes regions that haven't been set up with their 16 teams
 * - Updates game results when games are completed
 * - Advances to next round when all games are decided
 * - Closes betting period when games are about to start
 * - Displays comprehensive state of all regions and their games
 * 
 * Regions:
 * - Each region contains 8 First Round games
 * - Teams are ordered by seeding in initialization
 * - Games are numbered 1-8 within each region
 * 
 * Mock Date:
 * - Uses MOCK_DATE to simulate current time
 * - Automatically closes bets if any game starts within 30 minutes
 */

const axios = require("axios");
const path = require("path");
const fs = require("fs");
const { ethers } = require("hardhat");
require("dotenv").config();

const TOURNAMENT_YEAR = 2024;

// Mock current time for testing
const MOCK_DATE = "2024-03-20T12:00:00+00:00";
const currentTime = new Date(MOCK_DATE);

// Time threshold in milliseconds (30 minutes)
const THRESHOLD_MS = 30 * 60 * 1000;

// Map to convert from API region names to contract region names
const REGION_NAME_MAP = {
  "West Regional": "WEST",
  "Midwest Regional": "MIDWEST",
  "South Regional": "SOUTH",
  "East Regional": "EAST",
};

async function decodeRegionData(regionBytes) {
  const abiCoder = new ethers.utils.AbiCoder();
  const [
    teams,
    matchesRound1,
    matchesRound2,
    matchesRound3,
    matchRound4,
    winner,
  ] = abiCoder.decode(
    ["string[16]", "bytes[8]", "bytes[4]", "bytes[2]", "bytes", "string"],
    regionBytes
  );
  return {
    teams,
    matchesRound1,
    matchesRound2,
    matchesRound3,
    matchRound4,
    winner,
  };
}

async function decodeMatchData(matchBytes) {
  const abiCoder = new ethers.utils.AbiCoder();
  const [home, away, homePoints, awayPoints, winner] = abiCoder.decode(
    ["string", "string", "uint256", "uint256", "string"],
    matchBytes
  );
  return { home, away, homePoints, awayPoints, winner };
}

async function main() {
  // Get contract data
  const variablesPath = path.join(__dirname, "..", "contracts.json");
  const data = JSON.parse(fs.readFileSync(variablesPath, "utf8"));
  const networkName = hre.network.name;
  const networkData = data[networkName];

  console.log(`Using network: ${networkName}`);
  console.log(`Contract address: ${networkData["OM_DEPLOYER"]}`);

  // Get contract instance
  const Factory = await ethers.getContractFactory("OnchainMadnessFactory");
  const contract = Factory.attach(networkData["OM_DEPLOYER"]);

  // Get initial regions data
  console.log("\nInitial Regions Data:");
  const initialRegionsData = await contract.getAllRegionsData(TOURNAMENT_YEAR);
  const decodedRegions = await Promise.all(
    initialRegionsData.map(async (regionData, index) => {
      const decoded = await decodeRegionData(regionData);
      const regionName = Object.values(REGION_NAME_MAP)[index];
      console.log(`\n${regionName}:`);
      console.log(`Teams: ${decoded.teams.join(", ")}`);
      return decoded;
    })
  );

  try {
    const response = await axios.get(process.env.SPORTSRADAR_URL);
    const firstRoundBrackets = response.data.rounds[1].bracketed;

    // Track earliest game date
    let earliestDate = null;

    // Process each region
    for (const bracket of firstRoundBrackets) {
      const regionName = REGION_NAME_MAP[bracket.bracket.name];
      const regionIndex = Object.values(REGION_NAME_MAP).indexOf(regionName);
      const games = bracket.games;

      // Update earliest date
      games.forEach((game) => {
        const gameDate = new Date(game.scheduled);
        if (!earliestDate || gameDate < earliestDate) {
          earliestDate = gameDate;
        }
      });

      // Sort games by their game number
      games.sort((a, b) => {
        const aNum = parseInt(a.title.split("Game ")[1]);
        const bNum = parseInt(b.title.split("Game ")[1]);
        return aNum - bNum;
      });

      // Check if region needs initialization
      const currentRegionData = decodedRegions[regionIndex];
      const needsInit = currentRegionData.teams.every((team) => team === "");

      if (needsInit) {
        // Prepare teams array for initialization
        const teams = [];
        for (let i = 0; i < games.length; i++) {
          const game = games[i];
          // Check if home team is a First Four winner
          const homeTeam = game.home.name.includes("First Four - Game")
            ? `FFG${game.home.name.split("Game ")[1].split(" ")[0]}`
            : game.home.alias;
          // Check if away team is a First Four winner
          const awayTeam = game.away.name.includes("First Four - Game")
            ? `FFG${game.away.name.split("Game ")[1].split(" ")[0]}`
            : game.away.alias;

          teams.push(homeTeam);
          teams.push(awayTeam);
        }

        console.log(
          `\nInitializing ${regionName} with teams:`,
          teams.join(", ")
        );
        const tx = await contract.initRegion(
          TOURNAMENT_YEAR,
          regionName,
          teams
        );
        await tx.wait();
      }

      // Update match results
      console.log(`\nChecking ${regionName} games for updates...`);
      let decidedGames = 0;

      for (let i = 0; i < games.length; i++) {
        const game = games[i];
        if (game.status === "closed") {
          decidedGames++;
          const matchData = await decodeMatchData(
            currentRegionData.matchesRound1[i]
          );

          if (matchData.winner === "") {
            const homePoints = parseInt(game.home.points);
            const awayPoints = parseInt(game.away.points);
            const winner =
              game.home.points > game.away.points
                ? game.home.alias
                : game.away.alias;

            console.log(
              `Updating Game ${i + 1}: ${
                game.home.alias
              } ${homePoints} - ${awayPoints} ${
                game.away.alias
              }, Winner: ${winner}`
            );

            const tx = await contract.determineMatchWinner(
              TOURNAMENT_YEAR,
              regionName,
              winner,
              1, // round 1
              i, // match index
              homePoints,
              awayPoints
            );
            await tx.wait();
          }
        }
      }

      // If all games in the region are decided, check if we need to advance the round
      if (decidedGames === games.length) {
        console.log(`\nAll games in ${regionName} are decided`);
      }
    }

    // Print earliest game date and check if bets should be closed
    if (earliestDate) {
      console.log(`\nFirst Round starts on: ${earliestDate.toLocaleString()}`);
      
      // Check if earliest game is within 30 minutes of mock current time
      const timeUntilStart = earliestDate.getTime() - currentTime.getTime();
      
      console.log(`Current time (mocked): ${currentTime.toLocaleString()}`);
      console.log(`Time until first game: ${Math.floor(timeUntilStart / 60000)} minutes`);

      if (timeUntilStart <= THRESHOLD_MS) {
        console.log("\nFirst game starts in less than 30 minutes. Closing bets...");
        const tx = await contract.closeBets(TOURNAMENT_YEAR);
        await tx.wait();
        console.log("Bets closed successfully!");
      } else {
        console.log("\nBets remain open - first game is more than 30 minutes away");
      }
    }

    // Check if all regions have all games decided
    const updatedRegionsData = await contract.getAllRegionsData(
      TOURNAMENT_YEAR
    );
    const allRegionsDecided = await Promise.all(
      updatedRegionsData.map(async (regionData) => {
        const decoded = await decodeRegionData(regionData);
        // Check if all matches in round 1 have winners
        const matchResults = await Promise.all(
          decoded.matchesRound1.map(async (match) => {
            const matchData = await decodeMatchData(match);
            return matchData.winner !== "";
          })
        );
        return matchResults.every((hasWinner) => hasWinner);
      })
    );

    if (allRegionsDecided.every((regionDecided) => regionDecided)) {
      console.log(
        "\nAll first round games are decided. Advancing to next round..."
      );
      const tx = await contract.advanceRound(TOURNAMENT_YEAR);
      await tx.wait();
    } else {
      console.log(
        "\nNot all games are decided yet. Waiting for more results..."
      );
    }

    // Print final state
    console.log("\nFinal Regions Data:");
    const finalRegionsData = await contract.getAllRegionsData(TOURNAMENT_YEAR);

    // Process each region sequentially to maintain order
    for (let index = 0; index < finalRegionsData.length; index++) {
      const regionData = finalRegionsData[index];
      const decoded = await decodeRegionData(regionData);
      const regionName = Object.values(REGION_NAME_MAP)[index];

      console.log(`\n=== ${regionName} REGION ===`);
      console.log(`Teams: ${decoded.teams.join(", ")}`);
      console.log(`\nFirst Round Matches for ${regionName}:`);

      // Process matches sequentially to maintain order
      for (let i = 0; i < decoded.matchesRound1.length; i++) {
        const match = decoded.matchesRound1[i];
        const matchData = await decodeMatchData(match);
        console.log(
          `Game ${i + 1}: ${matchData.home} vs ${matchData.away}${
            matchData.winner ? ` - Winner: ${matchData.winner}` : ""
          }`
        );
      }
    }
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
