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

// Generate a random 3-digit hex string
function generateRandomHexSuffix() {
  return Math.floor(Math.random() * 0xFFF).toString(16).padStart(3, '0');
}

// Create pool with retry logic
async function createPoolWithRetry(deployer, isProtocolPool, isPrivatePool, pin, baseName, maxRetries = 5) {
  let attempts = 0;
  let currentName = baseName;

  while (attempts < maxRetries) {
    try {
      // First simulate the transaction
      await deployer.callStatic.createPool(
        isProtocolPool,
        isPrivatePool,
        pin,
        currentName
      );

      // If simulation succeeds, execute the actual transaction
      const tx = await deployer.createPool(
        isProtocolPool,
        isPrivatePool,
        pin,
        currentName
      );
      const receipt = await tx.wait();
      
      // Get pool ID from event logs
      const event = receipt.events.find(e => e.event === "EntryPoolCreated");
      if (!event) {
        throw new Error("EntryPoolCreated event not found in transaction receipt");
      }
      
      return { receipt, name: currentName };
    } catch (error) {
      if (error.message.includes("Pool name already exists")) {
        attempts++;
        if (attempts === maxRetries) {
          throw new Error(`Failed to create pool after ${maxRetries} attempts`);
        }
        currentName = `${baseName}-${generateRandomHexSuffix()}`;
        console.log(`Pool name already exists. Retrying with name: ${currentName}`);
      } else {
        throw error; // Re-throw if it's a different error
      }
    }
  }
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
    const { receipt: protocolReceipt, name: protocolName } = await createPoolWithRetry(
      deployer,
      true,   // isProtocolPool
      false,  // isPrivatePool
      "",     // no PIN needed
      "🏆 Onchain Madness Official" // pool name with official badge icon (emoji)
    );
    
    // Get pool ID from event logs
    const protocolEvent = protocolReceipt.events.find(e => e.event === "EntryPoolCreated");
    if (!protocolEvent) {
      throw new Error("EntryPoolCreated event not found in transaction receipt");
    }
    const [protocolPoolId, protocolPoolAddress] = protocolEvent.args;
    
    console.log(`✅ Protocol Pool created:`);
    console.log(`   Pool ID: ${protocolPoolId}`);
    console.log(`   Pool Address: ${protocolPoolAddress}`);
    console.log(`   Name: ${protocolName}`);

    // 2. Create Public pool
    console.log("\n2. Creating Public pool...");
    const { receipt: publicReceipt, name: publicName } = await createPoolWithRetry(
      deployer,
      false,  // isProtocolPool
      false,  // isPrivatePool
      "",     // no PIN needed
      "🎉 My Public Pool" // pool name with public badge icon (emoji)
    );
    
    // Get pool ID from event logs
    const publicEvent = publicReceipt.events.find(e => e.event === "EntryPoolCreated");
    if (!publicEvent) {
      throw new Error("EntryPoolCreated event not found in transaction receipt");
    }
    const [publicPoolId, publicPoolAddress] = publicEvent.args;
    
    console.log(`✅ Public Pool created:`);
    console.log(`   Pool ID: ${publicPoolId}`);
    console.log(`   Pool Address: ${publicPoolAddress}`);
    console.log(`   Name: ${publicName}`);

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
