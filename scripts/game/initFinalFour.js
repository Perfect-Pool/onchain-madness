/**
 * @title Final Four Initialization Script
 * @author PerfectPool
 * @notice This script interacts with the Sports Radar API and OnchainMadnessFactory contract
 * to initialize the Final Four games of the NCAA Tournament.
 *
 * Functionality:
 * - Fetches current tournament data from Sports Radar API
 * - Gets the Final Four teams from the API
 * - Initializes the Final Four matches with their respective teams
 * - Displays initial and final state of Final Four games
 */

const axios = require("axios");
const path = require("path");
const fs = require("fs");
const { ethers } = require("hardhat");
require("dotenv").config();

/**
 * @dev Decodes the Final Four data from the contract
 * @param finalFourBytes The encoded Final Four data
 * @return Object containing matchesRound1 (bytes[2]), matchFinal (bytes), and winner (string)
 */
async function decodeFinalFourData(finalFourBytes) {
  const abiCoder = new ethers.utils.AbiCoder();
  const [matchesRound1, matchFinal, winner] = abiCoder.decode(
    ["bytes[2]", "bytes", "string"],
    finalFourBytes
  );
  return { matchesRound1, matchFinal, winner };
}

/**
 * @dev Decodes a match's data from the contract
 * @param matchBytes The encoded match data
 * @return Object containing home team, away team, points, and winner
 */
async function decodeMatchData(matchBytes) {
  const abiCoder = new ethers.utils.AbiCoder();
  const [home, away, homePoints, awayPoints, winner] = abiCoder.decode(
    ["string", "string", "uint256", "uint256", "string"],
    matchBytes
  );
  return { home, away, homePoints, awayPoints, winner };
}

/**
 * @dev Main function to initialize Final Four matches
 */
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

  // Get initial Final Four data
  console.log("\nInitial Final Four Data:");
  const initialFinalFourData = await contract.getFinalFourData(TOURNAMENT_YEAR);
  const decodedFinalFour = await decodeFinalFourData(initialFinalFourData);

  console.log("\n=== INITIAL FINAL FOUR STATE ===");
  for (let i = 0; i < 2; i++) {
    console.log(`\nSemifinal Game ${i + 1}:`);
    try {
      const matchData = await decodeMatchData(
        decodedFinalFour.matchesRound1[i]
      );
      console.log(`Teams: ${matchData.home} vs ${matchData.away}`);
    } catch (error) {
      console.log("Not initialized yet");
    }
  }

  try {
    const response = await axios.get(
      process.env.SPORTSRADAR_URL + `?year=${TOURNAMENT_YEAR}`
    );
    const finalFourGames = response.data.rounds[5].games;

    // Collect Final Four semifinal games
    const semifinalGames = finalFourGames
      .filter((game) => game.title.includes("Final Four - Semifinals"))
      .sort((a, b) => {
        // Sort by game number to ensure consistent order
        const aNum = parseInt(a.title.split("Game ")[1]);
        const bNum = parseInt(b.title.split("Game ")[1]);
        return aNum - bNum;
      });

    // Check if we have both semifinal games
    if (semifinalGames.length !== 2) {
      console.log("\nError: Could not find both Final Four semifinal games");
      return;
    }

    // Check if any team is still TBD
    const hasTBDTeams = semifinalGames.some(
      (game) => game.home?.alias === "TBD" || game.away?.alias === "TBD"
    );

    if (hasTBDTeams) {
      console.log(
        "\nSkipping initialization - some Final Four teams are still TBD"
      );
      return;
    }

    // Prepare teams array for initialization
    const teamsRound1 = [
      semifinalGames[0].home.alias, // First semifinal home team
      semifinalGames[0].away.alias, // First semifinal away team
      semifinalGames[1].home.alias, // Second semifinal home team
      semifinalGames[1].away.alias, // Second semifinal away team
    ];

    console.log("\nTeams:", teamsRound1.join(", "));

    console.log("\nInitializing Final Four matches...");
    console.log("Teams:", teamsRound1.join(", "));

    try {
      const tx = await contract.initFinalFour(TOURNAMENT_YEAR, teamsRound1);
      await tx.wait();
      console.log("Final Four matches initialized successfully!");
    } catch (error) {
      console.error("Error initializing Final Four matches:", error);
    }

    // Get final state
    console.log("\n=== FINAL FOUR STATE AFTER INITIALIZATION ===");
    const finalFinalFourData = await contract.getFinalFourData(TOURNAMENT_YEAR);
    const decodedFinalState = await decodeFinalFourData(finalFinalFourData);

    for (let i = 0; i < 2; i++) {
      console.log(`\nSemifinal Game ${i + 1}:`);
      try {
        const matchData = await decodeMatchData(
          decodedFinalState.matchesRound1[i]
        );
        console.log(`Teams: ${matchData.home} vs ${matchData.away}`);
      } catch (error) {
        console.log("Not initialized");
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
