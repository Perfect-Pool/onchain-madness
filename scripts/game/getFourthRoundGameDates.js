/**
 * @title Fourth Round Games Update Script
 * @dev This script interacts with the Sports Radar API and OnchainMadnessFactory contract
 * to manage the Fourth Round games of the NCAA Tournament.
 *
 * Functionality:
 * - Fetches current tournament data from Sports Radar API
 * - prints the dates of the fourth round games in chronological order
 *
 * Regions:
 * - Each region contains 1 Fourth Round game
 * - Teams are ordered by seeding in initialization
 * - Games are numbered 1-1 within each region
 *
 */

const axios = require("axios");
const path = require("path");
const fs = require("fs");
require("dotenv").config();

async function main() {
  // Get contract data
  const variablesPath = path.join(__dirname, "..", "..", "contracts.json");
  const data = JSON.parse(fs.readFileSync(variablesPath, "utf8"));
  const networkName = hre.network.name;
  const networkData = data[networkName];
  const TOURNAMENT_YEAR = networkData.year;

  // Convert to Brasilia time (UTC-3)
  // Create a formatter that explicitly uses Brasilia timezone
  const formatter = new Intl.DateTimeFormat('pt-BR', {
    timeZone: 'America/Sao_Paulo',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
    timeZoneName: 'short'
  });

  try {
    const response = await axios.get(process.env.SPORTSRADAR_URL + `?year=${TOURNAMENT_YEAR}`);
    const fourthRoundBrackets = response.data.rounds[4].bracketed;
    const southBracket = fourthRoundBrackets[0];
    const midwestBracket = fourthRoundBrackets[1];
    const eastBracket = fourthRoundBrackets[2];
    const westBracket = fourthRoundBrackets[3];

    // Combine all games from all regions into a single array
    const allGames = [];
    
    // Add region identifier to each game
    southBracket.games.forEach(game => {
      allGames.push({
        ...game,
        region: 'SOUTH'
      });
    });
    
    midwestBracket.games.forEach(game => {
      allGames.push({
        ...game,
        region: 'MIDWEST'
      });
    });
    
    eastBracket.games.forEach(game => {
      allGames.push({
        ...game,
        region: 'EAST'
      });
    });
    
    westBracket.games.forEach(game => {
      allGames.push({
        ...game,
        region: 'WEST'
      });
    });
    
    // Sort games by scheduled date (earliest first)
    allGames.sort((a, b) => new Date(a.scheduled) - new Date(b.scheduled));
    
    // Print all games in chronological order
    console.log("\nThird Round Games in Chronological Order:");
    allGames.forEach((game) => {
      console.log(`- [ ] ${game.home.alias} vs ${game.away.alias}: ${formatter.format(new Date(game.scheduled))}`);
    });
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
