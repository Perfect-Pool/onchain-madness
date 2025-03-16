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

const POOL = 10;
const NFT_ID = 1;

const decodeBase64 = (base64String) => {
  return Buffer.from(base64String.split("base64,")[1], "base64").toString("utf-8");
};

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

  try {
    console.log("\nChecking token...");
    const tokenURI = await factory.tokenURI(POOL, NFT_ID);
    const decoded = decodeBase64(tokenURI);
    const svgImage = decodeBase64(JSON.parse(decoded).image);
    //create folder if doesn't exist
    if (!fs.existsSync(`./nft_image`)) {
      fs.mkdirSync(`./nft_image`);
    }
    fs.writeFileSync(`./nft_image/${YEAR}_${POOL}_${NFT_ID}.svg`, svgImage);
    console.log("\nToken image saved successfully!");
  } catch (error) {
    console.error("Error checking token:");
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
