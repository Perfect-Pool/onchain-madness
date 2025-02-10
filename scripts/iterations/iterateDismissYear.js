/**
 * @title Dismiss Year Prizes Script
 * @dev This script iterates through pools to dismiss prizes for a given tournament year
 * The script will continue iterating until all pools for the year have been processed
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
    console.log("\nIterating pools for prize dismissal...");
    let n = 0;
    while (true) {
      console.log(`\nIteration ${n}`);
      const tx = await factory.iterateDismissYear(TOURNAMENT_YEAR);
      const receipt = await tx.wait();

      const eventFinished = receipt.events.find(
        (e) => e.event === "DismissIterationFinished"
      );
      if (eventFinished) {
        console.log(
          "\nEvent 'DismissIterationFinished' found. No more prizes to dismiss."
        );
        break;
      }

      const eventContinue = receipt.events.find(
        (e) => e.event === "ContinueDismissIteration"
      );
      if (!eventContinue) {
        console.log("\nNo continuation event found. Stopping iteration.");
        break;
      }
      n++;
    }
  } catch (error) {
    console.error("Error dismissing prizes:");
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
