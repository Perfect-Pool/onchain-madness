const axios = require("axios");
const path = require("path");
const fs = require("fs");
const { ethers } = require("hardhat");
require("dotenv").config();

const TOURNAMENT_YEAR = 2024;

async function decodeFirstFourMatch(matchBytes) {
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

  // Get initial First Four data
  console.log("\nInitial First Four Data:");
  const initialFirstFourData = await contract.getFirstFourData(TOURNAMENT_YEAR);
  for (let i = 0; i < initialFirstFourData.length; i++) {
    const decodedMatch = await decodeFirstFourMatch(initialFirstFourData[i]);
    console.log(`Match FFG${i + 1}:`, decodedMatch);
  }

  // Make the GET request to SPORTSRADAR_URL
  try {
    const response = await axios.get(process.env.SPORTSRADAR_URL);
    
    // Collect all First Four games from different brackets
    const firstFourGames = [];
    response.data.rounds[0].bracketed.forEach(bracket => {
      bracket.games.forEach(game => {
        if (game.title.includes("First Four")) {
          firstFourGames.push(game);
        }
      });
    });

    // Sort games by their game number to ensure consistent order
    firstFourGames.sort((a, b) => {
      const aNum = parseInt(a.title.split("Game ")[1]);
      const bNum = parseInt(b.title.split("Game ")[1]);
      return aNum - bNum;
    });

    // First, initialize all games that need initialization
    console.log("\nChecking games that need initialization...");
    for (const game of firstFourGames) {
      const matchCode = `FFG${game.title.split("Game ")[1]}`;
      const homeTeam = game.home.alias;
      const awayTeam = game.away.alias;

      // Get current match data from contract
      const matchIndex = parseInt(matchCode.slice(3)) - 1;
      const currentMatchData = await decodeFirstFourMatch(
        initialFirstFourData[matchIndex]
      );

      // If match not initiated, initialize it
      if (currentMatchData.home === "" && currentMatchData.away === "") {
        console.log(
          `Initializing ${matchCode} with ${homeTeam} vs ${awayTeam}`
        );
        const tx = await contract.initFirstFourMatch(
          TOURNAMENT_YEAR,
          matchCode,
          homeTeam,
          awayTeam
        );
        await tx.wait(); // Wait for transaction to be mined
      }
    }

    // Then update results for completed games
    console.log("\nChecking games that need result updates...");
    for (const game of firstFourGames) {
      const matchCode = `FFG${game.title.split("Game ")[1]}`;
      const homeTeam = game.home.alias;
      const awayTeam = game.away.alias;

      // Get current match data from contract
      const matchIndex = parseInt(matchCode.slice(3)) - 1;
      const currentMatchData = await decodeFirstFourMatch(
        initialFirstFourData[matchIndex]
      );

      // If match is decided in API but not in contract, update it
      if (game.status === "closed" && currentMatchData.winner === "") {
        const homePoints = parseInt(game.home.points);
        const awayPoints = parseInt(game.away.points);
        const winner = homePoints > awayPoints ? 1 : 2;

        console.log(
          `Updating ${matchCode} result: ${homeTeam} ${homePoints} - ${awayPoints} ${awayTeam}`
        );
        const tx = await contract.determineFirstFourWinner(
          TOURNAMENT_YEAR,
          matchCode,
          1, // homeId - using placeholder as it's not critical for the game result
          2, // awayId - using placeholder as it's not critical for the game result
          homePoints,
          awayPoints,
          winner
        );
        await tx.wait(); // Wait for transaction to be mined
      }
    }

    // Get final First Four data
    console.log("\nFinal First Four Data after updates:");
    const finalFirstFourData = await contract.getFirstFourData(TOURNAMENT_YEAR);
    for (let i = 0; i < finalFirstFourData.length; i++) {
      const decodedMatch = await decodeFirstFourMatch(finalFirstFourData[i]);
      console.log(`Match FFG${i + 1}:`, decodedMatch);
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
