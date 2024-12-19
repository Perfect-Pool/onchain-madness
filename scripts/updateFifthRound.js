/**
 * @title Fifth Round (Final Four Semifinals) Games Update Script
 * @dev This script interacts with the Sports Radar API and OnchainMadnessFactory contract
 * to manage the Fifth Round (Final Four Semifinals) games of the NCAA Tournament.
 * 
 * Functionality:
 * - Fetches current tournament data from Sports Radar API
 * - Processes both Final Four semifinal games
 * - Updates game results and determines finalists
 * - Advances to Championship game when both semifinal games are decided
 * - Displays comprehensive state of Final Four matches
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
  console.log("\nInitial Final Four Data:");
  const initialFinalFourData = await contract.getFinalFourData(TOURNAMENT_YEAR);
  const decodedFinalFour = await decodeFinalFourData(initialFinalFourData);

  console.log("\n=== FINAL FOUR SEMIFINALS ===");
  for (let i = 0; i < 2; i++) {
    const matchData = await decodeMatchData(decodedFinalFour.matchesRound1[i]);
    if(matchData.home==="" || matchData.away==="") {
      console.log(`\nGame ${i + 1} not decided yet. Waiting for more results...`);
      process.exit(1);
    }
    console.log(`\nGame ${i + 1}:`);
    console.log(`${matchData.home} vs ${matchData.away}${matchData.winner ? ` - Winner: ${matchData.winner}` : ""}`);
  }

  try {
    const response = await axios.get(process.env.SPORTSRADAR_URL);
    const finalFourGames = response.data.rounds[5].games;

    // Process both semifinal games
    let decidedGames = 0;
    for (let i = 0; i < finalFourGames.length; i++) {
      const game = finalFourGames[i];
      
      if (game.title.includes("Final Four - Semifinals")) {
        const gameIndex = game.title.includes("Game 1") ? 0 : 1;
        console.log(`\nChecking Final Four Semifinal Game ${gameIndex + 1}...`);
        
        if (game.status === "closed") {
          decidedGames++;
          const matchData = await decodeMatchData(decodedFinalFour.matchesRound1[gameIndex]);
          
          if (matchData.winner === "") {
            const homePoints = parseInt(game.home_points);
            const awayPoints = parseInt(game.away_points);
            const winner = game.home_points > game.away_points ? game.home.alias : game.away.alias;

            console.log(
              `Updating Semifinal Game ${gameIndex + 1}: ${game.home.alias} ${homePoints} - ${awayPoints} ${game.away.alias}, Winner: ${winner}`
            );
            
            try{
              const tx = await contract.determineFinalFourWinner(
                TOURNAMENT_YEAR,
                gameIndex,
                winner,
                homePoints,
                awayPoints
              );
              await tx.wait();
              console.log(`${winner} advances to Championship Game!`);
            } catch (error) {
              console.log(`Game ${gameIndex + 1} already decided. Skipping...`);
            }
          }
        }
      }
    }

    // If both semifinal games are decided, advance to Championship
    if (decidedGames === 2) {
      console.log("\nBoth semifinal games decided. Advancing to Championship Game...");
      const tx = await contract.advanceRound(TOURNAMENT_YEAR);
      await tx.wait();
    } else {
      console.log("\nNot all semifinal games decided yet. Waiting for more results...");
    }

    // Print final state
    console.log("\nFinal Four State:");
    const finalFinalFourData = await contract.getFinalFourData(TOURNAMENT_YEAR);
    const decodedFinalState = await decodeFinalFourData(finalFinalFourData);

    console.log("\n=== FINAL FOUR SEMIFINALS - FINAL STATE ===");
    for (let i = 0; i < 2; i++) {
      const matchData = await decodeMatchData(decodedFinalState.matchesRound1[i]);
      console.log(`\nGame ${i + 1}:`);
      console.log(`${matchData.home} vs ${matchData.away}${matchData.winner ? ` - Winner: ${matchData.winner}` : ""}`);
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
