/**
 * @title Close Bets Script
 * @dev This script closes the betting period for the first round of the NCAA Tournament.
 *
 * Functionality:
 * - Closes betting period when games are about to start
 *
 */

const axios = require("axios");
const path = require("path");
const fs = require("fs");
const { ethers } = require("hardhat");
require("dotenv").config();

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

  try {
    console.log(
      "\nFirst game starts in less than 30 minutes. Closing bets..."
    );
    const tx = await contract.closeBets(TOURNAMENT_YEAR);
    await tx.wait();
    console.log("Bets closed successfully!");
  } catch (error) {
    console.log("Bets already closed.");
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
