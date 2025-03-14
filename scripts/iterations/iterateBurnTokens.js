/**
 * @title Burn PPS Tokens Script
 * @dev This script iterates through pools to burn PPS tokens for a given tournament year
 * The script will continue iterating until all pools for the year have been processed
 */

const path = require("path");
const fs = require("fs");
const { ethers } = require("hardhat");

async function main() {
  // Get contract data
  const variablesPath = path.join(__dirname, "..", "..", "contracts.json");
  const data = JSON.parse(fs.readFileSync(variablesPath, "utf8"));
  const networkName = hre.network.name;
  const networkData = data[networkName];
  const TOURNAMENT_YEAR = networkData.year;

  console.log(`Using network: ${networkName}`);
  console.log(`Entry Factory address: ${networkData["OM_ENTRY_DEPLOYER"]}`);

  // Get contract instances
  const EntryFactory = await ethers.getContractFactory(
    "OnchainMadnessEntryFactory"
  );
  const factory = EntryFactory.attach(networkData["OM_ENTRY_DEPLOYER"]);

  try {
    console.log("\nBurning non claimed tokens...");
    const tx = await factory.burnYearTokens(TOURNAMENT_YEAR);
    await tx.wait();

    console.log("\nTokens burned successfully!");
  } catch (error) {
    console.error("Error burning tokens:");
    console.error(error.message);
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
