/**
 * @title Check Prize Script
 * @dev This script checks the prize for a given token ID
 */

const path = require("path");
const fs = require("fs");
const { ethers } = require("hardhat");

const POOL = 0;

async function main() {
  // Get contract data
  const variablesPath = path.join(__dirname, "..", "contracts.json");
  const data = JSON.parse(fs.readFileSync(variablesPath, "utf8"));
  const networkName = hre.network.name;
  const networkData = data[networkName];
  const YEAR = networkData.year;
  
  console.log(`Using network: ${networkName}`);
  console.log(`Entry Factory address: ${networkData["OM_ENTRY_DEPLOYER"]}`);

  // Get contract instances
  const EntryFactory = await ethers.getContractFactory(
    "OnchainMadnessEntryFactory"
  );
  const factory = EntryFactory.attach(networkData["OM_ENTRY_DEPLOYER"]);

  const [wallet] = await ethers.getSigners();

  try {
    console.log("\nIterating tokens...");
    let n = 1;
    while (true) {
      try {
        await factory.tokenURI(POOL, n);
        await new Promise((resolve) => setTimeout(resolve, 200));
      } catch (error) {
        console.log("\nNo more tokens on this pool.");
        break;
      }
      console.log(`\nToken ID #${n}`);
      const [, points] = await factory.betValidator(POOL, n);
      console.log(`Points: ${points}`);
      const [toClaim, claimed] = await factory.amountPrizeClaimed(POOL, n);
      const shares = await factory.verifyShares(wallet.address, YEAR);
      console.log(`Shares: ${shares}`);
      console.log(`To Claim: ${toClaim}`);
      console.log(`Claimed: ${claimed}`);
      n++;

      await new Promise((resolve) => setTimeout(resolve, 500));
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
