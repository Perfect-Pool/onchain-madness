/**
 * @title Create NCAA Tournament Pools Script
 * @dev This script creates three different types of pools for the NCAA Tournament:
 * 1. Protocol-owned pool (for official tournament pools)
 * 2. Public pool (open for anyone to join)
 * 3. Private pool (requires PIN to join)
 * 
 * Each pool is created through the OnchainMadnessEntryFactory contract
 * and returns both the Pool ID and Pool address.
 */

const path = require("path");
const fs = require("fs");
const { ethers } = require("hardhat");

// Generate a random 6-digit PIN
function generatePin() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

async function main() {
  // Get contract data
  const variablesPath = path.join(__dirname, "..", "contracts.json");
  const data = JSON.parse(fs.readFileSync(variablesPath, "utf8"));
  const networkName = hre.network.name;
  const networkData = data[networkName];

  console.log(`Using network: ${networkName}`);
  console.log(`Entry Deployer address: ${networkData["OM_ENTRY_DEPLOYER"]}`);

  // Get contract instance
  const EntryDeployer = await ethers.getContractFactory("OnchainMadnessEntryFactory");
  const deployer = EntryDeployer.attach(networkData["OM_ENTRY_DEPLOYER"]);

  console.log("\nCreating pools...");

  try {
    // 1. Create Protocol-owned pool
    console.log("\n1. Creating Protocol-owned pool...");
    const protocolTx = await deployer.createPool(
      true,  // isProtocolPool
      false, // isPrivatePool
      "",    // no PIN needed
      "🏆 Onchain Madness Official" // pool name with official badge icon (emoji)
    );
    const protocolReceipt = await protocolTx.wait();
    
    // Get pool ID from event logs
    const protocolEvent = protocolReceipt.events.find(e => e.event === "EntryPoolCreated");
    if (!protocolEvent) {
      throw new Error("EntryPoolCreated event not found in transaction receipt");
    }
    const [protocolPoolId, protocolPoolAddress] = protocolEvent.args;
    
    console.log(`✅ Protocol Pool created:`);
    console.log(`   Pool ID: ${protocolPoolId}`);
    console.log(`   Pool Address: ${protocolPoolAddress}`);
    console.log(`   Name: Perfect Pool March Madness`);

  } catch (error) {
    console.error("Error creating pools:");
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
