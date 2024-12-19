/**
 * @title Championship Game Update Script
 * @dev This script interacts with the Sports Radar API and OnchainMadnessFactory contract
 * to manage the Championship game of the NCAA Tournament.
 * 
 * Functionality:
 * - Fetches current tournament data from Sports Radar API
 * - Processes the Championship game
 * - Updates game result and determines tournament champion
 * - Advances tournament to completion
 * - Displays final tournament state
 */

const axios = require("axios");
const path = require("path");
const fs = require("fs");
const { ethers } = require("hardhat");
require("dotenv").config();

const TOURNAMENT_YEAR = 2024;

async function decodeFinalFourData(finalFourBytes) {
  const abiCoder = new ethers.utils.AbiCoder();
  const [matchesRound1, matchFinal, winner] = abiCoder.decode(
    ['bytes[2]', 'bytes', 'string'],
    finalFourBytes
  );
  return { matchesRound1, matchFinal, winner };
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

  // Get initial Final Four data
  console.log("\nInitial Championship Game Data:");
  const initialFinalFourData = await contract.getFinalFourData(TOURNAMENT_YEAR);
  const decodedFinalFour = await decodeFinalFourData(initialFinalFourData);

  console.log("\n=== CHAMPIONSHIP GAME ===");
  const championshipData = await decodeMatchData(decodedFinalFour.matchFinal);
  console.log(`${championshipData.home} vs ${championshipData.away}${championshipData.winner ? ` - Champion: ${championshipData.winner}` : ""}`);

  try {
    const response = await axios.get(process.env.SPORTSRADAR_URL);
    const championshipGame = response.data.rounds[6].games[0]; // Only one game in championship round

    if (championshipGame.status === "closed") {
      const matchData = await decodeMatchData(decodedFinalFour.matchFinal);

      if (matchData.home === "" || matchData.away === "") {
        console.log("\nChampionship game not decided yet. Waiting for more results...");
        process.exit(1);
      }
      
      if (matchData.winner === "") {
        const homePoints = parseInt(championshipGame.home_points);
        const awayPoints = parseInt(championshipGame.away_points);
        const winner = championshipGame.home_points > championshipGame.away_points ? 
          championshipGame.home.alias : championshipGame.away.alias;

        console.log(
          `\nUpdating Championship Game: ${championshipGame.home.alias} ${homePoints} - ${awayPoints} ${championshipGame.away.alias}`
        );
        
        const tx = await contract.determineChampion(
          TOURNAMENT_YEAR,
          winner,
          homePoints,
          awayPoints
        );
        await tx.wait();
        console.log(`\n🏆 ${winner} is the NCAA Tournament Champion! 🏆`);

        // Advance tournament to completion
        console.log("\nCompleting tournament...");
        const advanceTx = await contract.advanceRound(TOURNAMENT_YEAR);
        await advanceTx.wait();
      }
    } else {
      console.log("\nChampionship game not completed yet. Waiting for results...");
    }

    // Print final state
    console.log("\nFinal Tournament State:");
    const finalFinalFourData = await contract.getFinalFourData(TOURNAMENT_YEAR);
    const decodedFinalState = await decodeFinalFourData(finalFinalFourData);

    console.log("\n=== CHAMPIONSHIP GAME - FINAL STATE ===");
    const finalChampionshipData = await decodeMatchData(decodedFinalState.matchFinal);
    console.log(`${finalChampionshipData.home} vs ${finalChampionshipData.away}`);
    if (finalChampionshipData.winner) {
      console.log(`\n🏆 Tournament Champion: ${finalChampionshipData.winner} 🏆`);
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
