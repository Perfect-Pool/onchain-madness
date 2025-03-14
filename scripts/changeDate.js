/**
 * @title Close Bets Script
 * @dev This script closes the betting period for the first round of the NCAA Tournament.
 *
 * Functionality:
 * - Closes betting period when games are about to start
 *
 */

const path = require("path");
const fs = require("fs");
const { ethers } = require("hardhat");
require("dotenv").config();

const MOCKED_YEAR = 2024;
const MOCKED_MONTH = 3;
const MOCKED_DAY = 1;

async function main() {
  // Get contract data
  const variablesPath = path.join(__dirname, "..", "contracts.json");
  const data = JSON.parse(fs.readFileSync(variablesPath, "utf8"));
  const networkName = hre.network.name;
  const networkData = data[networkName];

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
    console.log(`\nSetting mocked date to ${MOCKED_YEAR}-${MOCKED_MONTH}-${MOCKED_DAY}...`);
    const tx = await contract.setMockedDate(MOCKED_YEAR, MOCKED_MONTH, MOCKED_DAY);
    await tx.wait();
    console.log("Date changed successfully!");
  } catch (error) {
    console.log("Date already changed.");
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
