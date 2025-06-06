/**
 * @title Get NFT Image Script
 * @dev This script retrieves the SVG image of a specific NFT token
 */

const path = require("path");
const fs = require("fs");
const { ethers } = require("hardhat");

const POOL = 0;
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
