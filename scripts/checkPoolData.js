/**
 * @title Check Pool Data Script
 * @dev This script retrieves data from a specific pool and token in the NCAA Tournament:
 * - Amount of prize claimed and to claim
 * - Bet validation data
 * 
 * The data is retrieved through the OnchainMadnessEntryFactory contract
 */

const path = require("path");
const fs = require("fs");
const { ethers } = require("hardhat");

// Configuration
const poolId = 0; // Change this to the desired pool ID
const tokenId = 1; // Change this to the desired token ID

async function main() {
  // Get contract data
  const variablesPath = path.join(__dirname, "..", "contracts.json");
  const data = JSON.parse(fs.readFileSync(variablesPath, "utf8"));
  const networkName = hre.network.name;
  const networkData = data[networkName];

  console.log(`Using network: ${networkName}`);
  console.log(`Entry Deployer address: ${networkData["OM_ENTRY_DEPLOYER"]}`);
  console.log(`Checking data for Pool ID: ${poolId}, Token ID: ${tokenId}\n`);

  // Get contract instance
  const EntryDeployer = await ethers.getContractFactory("OnchainMadnessEntryFactory");
  const deployer = EntryDeployer.attach(networkData["OM_ENTRY_DEPLOYER"]);

  try {
    // 1. Get prize claim data
    console.log("1. Checking prize claim data...");
    const [amountToClaim, amountClaimed] = await deployer.amountPrizeClaimed(poolId, tokenId);
    console.log(`Amount to claim: ${ethers.utils.formatUnits(amountToClaim, 6)} USDC`);
    console.log(`Amount claimed: ${ethers.utils.formatUnits(amountClaimed, 6)} USDC\n`);

    // 2. Get bet validation data
    console.log("2. Checking bet validation data...");
    const [betData, gameYear] = await deployer.betValidator(poolId, tokenId);
    console.log(`Game Year: ${gameYear}`);
    console.log("Bet Data:", betData.join(", "));

  } catch (error) {
    console.error("Error:", error.message);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
