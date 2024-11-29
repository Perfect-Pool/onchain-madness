const fs = require("fs-extra");
const path = require("path");
const { ethers } = require("hardhat");

async function main() {
  const variablesPath = path.join(__dirname, "..", "..", "contracts.json");
  const data = JSON.parse(fs.readFileSync(variablesPath, "utf8"));
  const networkName = hre.network.name;
  const networkData = data[networkName];

  const OnchainMadnessFactory = await ethers.getContractAt(
    "OnchainMadnessFactory",
    networkData.OM_DEPLOYER
  );
  console.log(
    `OnchainMadnessFactory loaded at ${OnchainMadnessFactory.address}`
  );

  const name = "OM_METADATA";
  if (networkData.OM_METADATA === "") {
    console.log(`Deploying NftMetadata...`);
    const NftMetadata = await ethers.getContractFactory("NftMetadata");
    const nftMetadata = await NftMetadata.deploy(networkData.OM_DEPLOYER);
    await nftMetadata.deployed();
    console.log(`NftMetadata deployed at ${nftMetadata.address}`);
    await new Promise((resolve) => setTimeout(resolve, 5000));

    console.log(`Setting NftMetadata address to OnchainMadnessFactory...`);
    await OnchainMadnessFactory.setContract(name, nftMetadata.address);

    networkData.OM_METADATA = nftMetadata.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

  } else {
    console.log(`NftMetadata already deployed at ${networkData.OM_METADATA}`);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
