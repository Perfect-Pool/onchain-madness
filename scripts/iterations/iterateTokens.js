/**
 * @title Place Bets Script
 * @dev This script places bets on the NCAA Tournament pools by minting NFTs
 * Each NFT represents a bracket prediction with 63 games
 * - First Four: 4 games
 * - First Round: 32 games
 * - Second Round: 16 games
 * - Sweet 16: 8 games
 * - Elite Eight: 4 games
 * - Final Four: 2 games
 * - Championship: 1 game
 *
 * Each bet costs 20 USDC and requires approval before minting
 */

const path = require("path");
const fs = require("fs");
const { ethers } = require("hardhat");

const TOURNAMENT_YEAR = 2024;

async function main() {
  // Get contract data
  const variablesPath = path.join(__dirname, "..", "..", "contracts.json");
  const data = JSON.parse(fs.readFileSync(variablesPath, "utf8"));
  const networkName = hre.network.name;
  const networkData = data[networkName];

  console.log(`Using network: ${networkName}`);
  console.log(`Entry Factory address: ${networkData["OM_ENTRY_DEPLOYER"]}`);

  // Get contract instances
  const EntryFactory = await ethers.getContractFactory(
    "OnchainMadnessEntryFactory"
  );
  const factory = EntryFactory.attach(networkData["OM_ENTRY_DEPLOYER"]);

  try {
    console.log("\nIterating tokens...");
    let n = 0;
    while (true) {
      console.log(`\nIteration ${n}`);
      const tx = await factory.iterateYearTokens(TOURNAMENT_YEAR);
      const receipt = await tx.wait();

      const eventFinished = receipt.events.find(
        (e) => e.event === "IterationFinished"
      );
      if (eventFinished) {
        console.log(
          "\nEvent 'IterationFinished' found. No more tokens to iterate."
        );
        break;
      }
      n++;
    }
  } catch (error) {
    console.error("Error iterating tokens:");
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
