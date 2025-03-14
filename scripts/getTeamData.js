/**
 * @title Get Final Four Data Script
 * @dev This script retrieves and displays the Final Four data from the OnchainMadness contract
 * in a human-readable format.
 *
 * Functionality:
 * - Retrieves Final Four data from the contract
 * - Decodes and displays game data for semifinals and championship
 */

const path = require("path");
const fs = require("fs");
const { ethers } = require("hardhat");
require("dotenv").config();

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
  const year = networkData.year;

  console.log(`Using network: ${networkName}`);
  console.log(`Contract address: ${networkData["OM_DEPLOYER"]}`);

  // Get contract instance
  const Factory = await ethers.getContractFactory("OnchainMadnessFactory", {
    libraries: {
      OnchainMadnessLib: networkData["Libraries"].OnchainMadnessLib,
    },
  });
  const contract = Factory.attach(networkData["OM_DEPLOYER"]);

  try {
    console.log(`\nGetting ASU Team ID...`);
    const teamId = await contract.getTeamId(year, "ASU");
    console.log(`ASU Team ID: ${teamId}`);
    const teamName = await contract.getTeamName(year, 0);
    console.log(`ID #0 Team Name: ${teamName}`);
  } catch (error) {
    console.log("Error getting ASU Team ID:");
    console.error(error.response ? error.response.data : error.message);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
