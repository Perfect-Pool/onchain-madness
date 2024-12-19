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
const BET_AMOUNT = ethers.utils.parseUnits("20", 6); // 20 USDC (6 decimals)

// Minimal USDC ABI for the functions we need
const USDC_ABI = [
  "function approve(address spender, uint256 amount) external returns (bool)",
  "function balanceOf(address account) external view returns (uint256)"
];

// Generate a random array of 63 predictions (0 or 1)
function generateRandomPredictions() {
  const predictions = new Array(63);
  for (let i = 0; i < 63; i++) {
    predictions[i] = Math.random() < 0.5 ? 0 : 1;
  }
  return predictions;
}

async function main() {
  // Get contract data
  const variablesPath = path.join(__dirname, "..", "contracts.json");
  const data = JSON.parse(fs.readFileSync(variablesPath, "utf8"));
  const networkName = hre.network.name;
  const networkData = data[networkName];

  console.log(`Using network: ${networkName}`);
  console.log(`Entry Factory address: ${networkData["OM_ENTRY_DEPLOYER"]}`);
  console.log(`USDC address: ${networkData["USDC"]}`);

  // Get contract instances
  const EntryFactory = await ethers.getContractFactory("OnchainMadnessEntryFactory");
  const factory = EntryFactory.attach(networkData["OM_ENTRY_DEPLOYER"]);
  
  const [signer] = await ethers.getSigners();
  const usdc = new ethers.Contract(networkData["USDC"], USDC_ABI, signer);

  try {
    // Check USDC balance
    const balance = await usdc.balanceOf(signer.address);
    const requiredAmount = BET_AMOUNT.mul(3); // Need 20 USDC for each of the 3 bets
    
    console.log(`USDC Balance: ${ethers.utils.formatUnits(balance, 6)} USDC`);
    console.log(`Required Amount: ${ethers.utils.formatUnits(requiredAmount, 6)} USDC`);
    
    if (balance.lt(requiredAmount)) {
      throw new Error(`Insufficient USDC balance. Need ${ethers.utils.formatUnits(requiredAmount, 6)} USDC`);
    }

    // Approve USDC spending
    console.log("\nApproving USDC spending...");
    const approveTx = await usdc.approve(factory.address, balance);
    await approveTx.wait();
    console.log("✅ USDC approved");

    // 1. Place bet on Protocol Pool (ID: 0)
    console.log("\n1. Placing bet on Protocol Pool (ID: 0)...");
    const protocolBets = generateRandomPredictions();
    const protocolTx = await factory.safeMint(
      0,                    // poolId
      TOURNAMENT_YEAR,      // gameYear
      protocolBets,         // predictions
      ""                    // no PIN needed
    );
    const protocolReceipt = await protocolTx.wait();
    
    const protocolEvent = protocolReceipt.events.find(e => e.event === "BetPlaced");
    if (!protocolEvent) {
      throw new Error("BetPlaced event not found in transaction receipt");
    }
    const [bettor, gameYear, protocolTokenId] = protocolEvent.args;
    
    console.log(`✅ Bet placed on Protocol Pool:`);
    console.log(`   Token ID: ${protocolTokenId}`);
    console.log(`   Bettor: ${bettor}`);

    // 2. Place bet on Public Pool (ID: 1)
    console.log("\n2. Placing bet on Public Pool (ID: 1)...");
    const publicBets = generateRandomPredictions();
    const publicTx = await factory.safeMint(
      1,                    // poolId
      TOURNAMENT_YEAR,      // gameYear
      publicBets,          // predictions
      ""                    // no PIN needed
    );
    const publicReceipt = await publicTx.wait();
    
    const publicEvent = publicReceipt.events.find(e => e.event === "BetPlaced");
    if (!publicEvent) {
      throw new Error("BetPlaced event not found in transaction receipt");
    }
    const [publicBettor, publicGameYear, publicTokenId] = publicEvent.args;
    
    console.log(`✅ Bet placed on Public Pool:`);
    console.log(`   Token ID: ${publicTokenId}`);
    console.log(`   Bettor: ${publicBettor}`);

    // 3. Place bet on Private Pool (ID: 2)
    console.log("\n3. Placing bet on Private Pool (ID: 2)...");
    const privateBets = generateRandomPredictions();
    const privateTx = await factory.safeMint(
      2,                    // poolId
      TOURNAMENT_YEAR,      // gameYear
      privateBets,         // predictions
      "131329"              // PIN required
    );
    const privateReceipt = await privateTx.wait();
    
    const privateEvent = privateReceipt.events.find(e => e.event === "BetPlaced");
    if (!privateEvent) {
      throw new Error("BetPlaced event not found in transaction receipt");
    }
    const [privateBettor, privateGameYear, privateTokenId] = privateEvent.args;
    
    console.log(`✅ Bet placed on Private Pool:`);
    console.log(`   Token ID: ${privateTokenId}`);
    console.log(`   Bettor: ${privateBettor}`);

    // Final USDC balance
    const finalBalance = await usdc.balanceOf(signer.address);
    console.log(`\nFinal USDC Balance: ${ethers.utils.formatUnits(finalBalance, 6)} USDC`);

    // Summary
    console.log("\n=== Summary of Placed Bets ===");
    console.log(`Total USDC Spent: ${ethers.utils.formatUnits(BET_AMOUNT.mul(3), 6)} USDC`);
    
    console.log("\nProtocol Pool (ID: 0):");
    console.log(`Token ID: ${protocolTokenId}`);
    console.log(`Bettor: ${bettor}`);
    
    console.log("\nPublic Pool (ID: 1):");
    console.log(`Token ID: ${publicTokenId}`);
    console.log(`Bettor: ${publicBettor}`);
    
    console.log("\nPrivate Pool (ID: 2):");
    console.log(`Token ID: ${privateTokenId}`);
    console.log(`Bettor: ${privateBettor}`);
    console.log(`PIN Used: 131329`);

  } catch (error) {
    console.error("Error placing bets:");
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
