/**
 * @title Championship Creation Script
 * @dev This script interacts with the OnchainMadnessFactory contract
 * to create the Championship game of the NCAA Tournament.
 *
 * Functionality:
 * - Resets the Championship game
 * - Creates the Championship game
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
  const REGION_ORDER = networkData.regionOrder;

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
    console.log("Resetting Championship Game...");
    const tx = await contract.resetGame(TOURNAMENT_YEAR);
    await tx.wait();
  } catch (error) {
    console.log("There is no Championship Game to reset.");
  }

  try {
    console.log("Creating Championship Game...");
    let tx = await contract.createOnchainMadness(TOURNAMENT_YEAR);
    await tx.wait();

    const BetCheck = await ethers.getContractFactory("BetCheck", {
      libraries: {
        OnchainMadnessBetLib: networkData["Libraries"].OnchainMadnessBetLib,
      },
    });
    const betCheck = BetCheck.attach(networkData["BET_CHECK"]);

    tx = await betCheck.setRegionPosition(TOURNAMENT_YEAR, REGION_ORDER);
    await tx.wait();

  } catch (error) {
    console.log("There was an error creating the Championship Game:");
    console.log(error);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
