/**
 * @title Fourth Round (Elite Eight) Games Update Script
 * @dev This script interacts with the Sports Radar API and OnchainMadnessFactory contract
 * to manage the Fourth Round (Elite Eight) games of the NCAA Tournament.
 * 
 * Functionality:
 * - Fetches current tournament data from Sports Radar API
 * - Processes the final game for each region (WEST, MIDWEST, SOUTH, EAST)
 * - Updates game results and determines regional champions
 * - Advances to Final Four when all regional champions are decided
 * - Displays comprehensive state of all regions and their final games
 * 
 * Regions:
 * - Each region has 1 Elite Eight game to determine regional champion
 * - Winners advance to Final Four tournament
 */

const axios = require("axios");
const path = require("path");
const fs = require("fs");
const { ethers } = require("hardhat");
require("dotenv").config();

const TOURNAMENT_YEAR = 2024;

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
      console.log(`\n=== ${regionName} REGION ===`);
      console.log(`Teams: ${decoded.teams.join(", ")}`);
      console.log(`\nElite Eight Match for ${regionName}:`);
      const matchData = await decodeMatchData(decoded.matchRound4);
      console.log(`${matchData.home} vs ${matchData.away}${matchData.winner ? ` - Winner: ${matchData.winner}` : ""}`);
      return decoded;
    })
  );

  try {
    const response = await axios.get(process.env.SPORTSRADAR_URL);
    const fourthRoundBrackets = response.data.rounds[4].bracketed;

    // Process each region
    let decidedRegions = 0;
    for (const bracket of fourthRoundBrackets) {
      const regionName = REGION_NAME_MAP[bracket.bracket.name];
      const regionIndex = Object.values(REGION_NAME_MAP).indexOf(regionName);
      const game = bracket.games[0]; // Only one game per region in Elite Eight

      console.log(`\nChecking ${regionName} final game...`);
      
      if (game.status === "closed") {
        decidedRegions++;
        const matchData = await decodeMatchData(decodedRegions[regionIndex].matchRound4);
        
        if (matchData.winner === "") {
          const homePoints = parseInt(game.home.points);
          const awayPoints = parseInt(game.away.points);
          const winner = game.home.points > game.away.points ? game.home.alias : game.away.alias;

          console.log(
            `Updating ${regionName} Champion Game: ${game.home.alias} ${homePoints} - ${awayPoints} ${game.away.alias}, Winner: ${winner}`
          );
          
          const tx = await contract.determineFinalRegionWinner(
            TOURNAMENT_YEAR,
            regionName,
            winner,
            homePoints,
            awayPoints
          );
          await tx.wait();
          console.log(`${winner} advances to Final Four as ${regionName} Champion!`);
        }
      }
    }

    // If all regions have determined their champion, advance to Final Four
    if (decidedRegions === Object.keys(REGION_NAME_MAP).length) {
      console.log("\nAll regional champions decided. Advancing to Final Four...");
      const tx = await contract.advanceRound(TOURNAMENT_YEAR);
      await tx.wait();
    } else {
      console.log("\nNot all regional champions decided yet. Waiting for more results...");
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
        console.log(`\nElite Eight Match for ${regionName}:`);
        const matchData = await decodeMatchData(decoded.matchRound4);
        console.log(`${matchData.home} vs ${matchData.away}${matchData.winner ? ` - Regional Champion: ${matchData.winner}` : ""}`);
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
