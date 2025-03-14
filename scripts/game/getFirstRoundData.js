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

// Mock current time for testing
// const MOCK_DATE = "2025-03-20T12:00:00+00:00";
// const currentTime = new Date(MOCK_DATE);
const currentTime = new Date();

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
      console.log(`\n${regionName}:`);
      console.log(`Teams: ${decoded.teams.join(", ")}`);
      return decoded;
    })
  );

  try {
    const response = await axios.get(process.env.SPORTSRADAR_URL + `?year=${TOURNAMENT_YEAR}`);
    const firstRoundBrackets = response.data.rounds[1].bracketed;

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
