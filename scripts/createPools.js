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
      "Official March Madness 2024" // pool name
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
    console.log(`   Name: Official March Madness 2024`);

    // 2. Create Public pool
    console.log("\n2. Creating Public pool...");
    const publicTx = await deployer.createPool(
      false, // isProtocolPool
      false, // isPrivatePool
      "",    // no PIN needed
      "Public March Madness Pool" // pool name
    );
    const publicReceipt = await publicTx.wait();
    
    const publicEvent = publicReceipt.events.find(e => e.event === "EntryPoolCreated");
    if (!publicEvent) {
      throw new Error("EntryPoolCreated event not found in transaction receipt");
    }
    const [publicPoolId, publicPoolAddress] = publicEvent.args;
    
    console.log(`✅ Public Pool created:`);
    console.log(`   Pool ID: ${publicPoolId}`);
    console.log(`   Pool Address: ${publicPoolAddress}`);
    console.log(`   Name: Public March Madness Pool`);

    // 3. Create Private pool with PIN
    const pin = "131329";
    console.log(`\n3. Creating Private pool with PIN: ${pin}...`);
    const privateTx = await deployer.createPool(
      false,  // isProtocolPool
      true,   // isPrivatePool
      pin,    // 6-digit PIN
      "Friends & Family Pool 2024" // pool name
    );
    const privateReceipt = await privateTx.wait();
    
    const privateEvent = privateReceipt.events.find(e => e.event === "EntryPoolCreated");
    if (!privateEvent) {
      throw new Error("EntryPoolCreated event not found in transaction receipt");
    }
    const [privatePoolId, privatePoolAddress] = privateEvent.args;
    
    console.log(`✅ Private Pool created:`);
    console.log(`   Pool ID: ${privatePoolId}`);
    console.log(`   Pool Address: ${privatePoolAddress}`);
    console.log(`   PIN: ${pin}`);
    console.log(`   Name: Friends & Family Pool 2024`);

    // Summary
    console.log("\n=== Summary of Created Pools ===");
    console.log("\nProtocol Pool:");
    console.log(`ID: ${protocolPoolId}`);
    console.log(`Address: ${protocolPoolAddress}`);
    console.log(`Name: Official March Madness 2024`);
    
    console.log("\nPublic Pool:");
    console.log(`ID: ${publicPoolId}`);
    console.log(`Address: ${publicPoolAddress}`);
    console.log(`Name: Public March Madness Pool`);
    
    console.log("\nPrivate Pool:");
    console.log(`ID: ${privatePoolId}`);
    console.log(`Address: ${privatePoolAddress}`);
    console.log(`Name: Friends & Family Pool 2024`);
    console.log(`PIN: ${pin}`);

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
