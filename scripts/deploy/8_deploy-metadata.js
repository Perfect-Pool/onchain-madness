const fs = require("fs-extra");
const path = require("path");
const { ethers } = require("hardhat");

async function main() {
  const variablesPath = path.join(__dirname, "..", "..", "contracts.json");
  const data = JSON.parse(fs.readFileSync(variablesPath, "utf8"));
  const networkName = hre.network.name;
  const networkData = data[networkName];

  const name = "MM_METADATA";
  if (networkData.MM_METADATA === "") {
    console.log(`Deploying NftMetadata...`);
    const NftMetadata = await ethers.getContractFactory("NftMetadata");
    const nftMetadata = await NftMetadata.deploy();
    await nftMetadata.deployed();
    console.log(`NftMetadata deployed at ${nftMetadata.address}`);

    networkData.MM_METADATA = nftMetadata.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

    await new Promise((resolve) => setTimeout(resolve, 5000));
  } else {
    console.log(`NftMetadata already deployed at ${networkData.MM_METADATA}`);
  }
}

main().then(() => process.exit(0)).catch((error) => {
  console.error(error);
  process.exit(1);
});
