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

const POOL = 2;
const BET_AMOUNT = ethers.utils.parseUnits("20", 6); // 20 USDC (6 decimals)

// Minimal USDC ABI for the functions we need
const USDC_ABI = [
  "function approve(address spender, uint256 amount) external returns (bool)",
  "function balanceOf(address account) external view returns (uint256)",
  "function allowance(address owner, address spender) external view returns (uint256)",
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
  const TOURNAMENT_YEAR = networkData.year;

  console.log(`Using network: ${networkName}`);
  console.log(`Entry Factory address: ${networkData["OM_ENTRY_DEPLOYER"]}`);
  console.log(`USDC address: ${networkData["USDC"]}`);

  // Get contract instances
  const EntryFactory = await ethers.getContractFactory(
    "OnchainMadnessEntryFactory"
  );
  const factory = EntryFactory.attach(networkData["OM_ENTRY_DEPLOYER"]);

  const [signer] = await ethers.getSigners();
  const usdc = new ethers.Contract(networkData["USDC"], USDC_ABI, signer);
  const perfectBet = [
    0, 1, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1, 1, 0, 0, 1, 0,
    1, 1, 0, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0,
    0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0
  ];
  try {
    // Check USDC balance
    const balance = await usdc.balanceOf(signer.address);

    console.log(`USDC Balance: ${ethers.utils.formatUnits(balance, 6)} USDC`);
    console.log(
      `Required Amount: ${ethers.utils.formatUnits(BET_AMOUNT, 6)} USDC`
    );

    if (balance.lt(BET_AMOUNT)) {
      throw new Error(
        `Insufficient USDC balance. Need ${ethers.utils.formatUnits(
          BET_AMOUNT,
          6
        )} USDC`
      );
    }

    //Verify USDC Approval
    const approvedAmount = await usdc.allowance(
      signer.address,
      factory.address
    );
    if (approvedAmount.lt(BET_AMOUNT)) {
      console.log("\nApproving USDC spending...");
      const approveTx = await usdc.approve(factory.address, balance);
      await approveTx.wait();
      console.log("✅ USDC approved");
    }

    // Place bet on Protocol Pool (ID: POOL)
    console.log(`\nPlacing bet on Protocol Pool (ID: ${POOL})...`);
    const protocolTx = await factory.safeMint(
      POOL, // poolId
      TOURNAMENT_YEAR, // gameYear
      perfectBet, // predictions
      "" // no PIN needed
    );
    const protocolReceipt = await protocolTx.wait();

    const protocolEvent = protocolReceipt.events.find(
      (e) => e.event === "BetPlaced"
    );
    if (!protocolEvent) {
      throw new Error("BetPlaced event not found in transaction receipt");
    }
    const [bettor, gameYear, protocolTokenId] = protocolEvent.args;

    console.log(`✅ Bet placed on Protocol Pool:`);
    console.log(`   Token ID: ${protocolTokenId}`);
    console.log(`   Bettor: ${bettor}`);

    // Final USDC balance
    const finalBalance = await usdc.balanceOf(signer.address);
    console.log(
      `\nFinal USDC Balance: ${ethers.utils.formatUnits(finalBalance, 6)} USDC`
    );

    // Summary
    console.log("\n=== Summary of Placed Bets ===");
    console.log(
      `Total USDC Spent: ${ethers.utils.formatUnits(BET_AMOUNT.mul(3), 6)} USDC`
    );

    console.log(`\nProtocol Pool (ID: ${POOL}):`);
    console.log(`Token ID: ${protocolTokenId}`);
    console.log(`Bettor: ${bettor}`);
  } catch (error) {
    console.log(`   Predictions: ${perfectBet}`);
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
