/**
 * @title Create NCAA Tournament Pools Script
 * @dev This script creates three different types of pools for the NCAA Tournament:
 * 1. Protocol-owned pool (for official tournament pools)
 * 2. Public pool (open for anyone to join)
 * 3. Private pool (requires PIN to join)
 * 
 * Each pool is created through the OnchainMadnessTicketFactory contract
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
  console.log(`Ticket Deployer address: ${networkData["OM_TICKET_DEPLOYER"]}`);

  // Get contract instance
  const TicketDeployer = await ethers.getContractFactory("OnchainMadnessTicketFactory");
  const deployer = TicketDeployer.attach(networkData["OM_TICKET_DEPLOYER"]);

  console.log("\nCreating pools...");

  try {
    // 1. Create Protocol-owned pool
    console.log("\n1. Creating Protocol-owned pool...");
    const protocolTx = await deployer.createPool(
      true,  // isProtocolPool
      false, // isPrivatePool
      ""     // no PIN needed
    );
    const protocolReceipt = await protocolTx.wait();
    
    // Get pool ID from event logs
    const protocolEvent = protocolReceipt.events.find(e => e.event === "TicketPoolCreated");
    if (!protocolEvent) {
      throw new Error("TicketPoolCreated event not found in transaction receipt");
    }
    const [protocolPoolId, protocolPoolAddress] = protocolEvent.args;
    
    console.log(`✅ Protocol Pool created:`);
    console.log(`   Pool ID: ${protocolPoolId}`);
    console.log(`   Pool Address: ${protocolPoolAddress}`);

    // 2. Create Public pool
    console.log("\n2. Creating Public pool...");
    const publicTx = await deployer.createPool(
      false, // isProtocolPool
      false, // isPrivatePool
      ""     // no PIN needed
    );
    const publicReceipt = await publicTx.wait();
    
    const publicEvent = publicReceipt.events.find(e => e.event === "TicketPoolCreated");
    if (!publicEvent) {
      throw new Error("TicketPoolCreated event not found in transaction receipt");
    }
    const [publicPoolId, publicPoolAddress] = publicEvent.args;
    
    console.log(`✅ Public Pool created:`);
    console.log(`   Pool ID: ${publicPoolId}`);
    console.log(`   Pool Address: ${publicPoolAddress}`);

    // 3. Create Private pool with PIN
    const pin = generatePin();
    console.log(`\n3. Creating Private pool with PIN: ${pin}...`);
    const privateTx = await deployer.createPool(
      false,  // isProtocolPool
      true,   // isPrivatePool
      pin     // 6-digit PIN
    );
    const privateReceipt = await privateTx.wait();
    
    const privateEvent = privateReceipt.events.find(e => e.event === "TicketPoolCreated");
    if (!privateEvent) {
      throw new Error("TicketPoolCreated event not found in transaction receipt");
    }
    const [privatePoolId, privatePoolAddress] = privateEvent.args;
    
    console.log(`✅ Private Pool created:`);
    console.log(`   Pool ID: ${privatePoolId}`);
    console.log(`   Pool Address: ${privatePoolAddress}`);
    console.log(`   PIN: ${pin}`);

    // Summary
    console.log("\n=== Summary of Created Pools ===");
    console.log("\nProtocol Pool:");
    console.log(`ID: ${protocolPoolId}`);
    console.log(`Address: ${protocolPoolAddress}`);
    
    console.log("\nPublic Pool:");
    console.log(`ID: ${publicPoolId}`);
    console.log(`Address: ${publicPoolAddress}`);
    
    console.log("\nPrivate Pool:");
    console.log(`ID: ${privatePoolId}`);
    console.log(`Address: ${privatePoolAddress}`);
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
