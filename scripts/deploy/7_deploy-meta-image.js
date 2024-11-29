const fs = require("fs-extra");
const path = require("path");
const { ethers } = require("hardhat");

async function main() {
  const variablesPath = path.join(__dirname, "..", "..", "contracts.json");
  const data = JSON.parse(fs.readFileSync(variablesPath, "utf8"));
  const networkName = hre.network.name;
  const networkData = data[networkName];

  // Ensure the BuildImage library is deployed
  if (
    !networkData["Libraries"].BuildImage ||
    networkData["Libraries"].BuildImage === ""
  ) {
    throw new Error(
      "BuildImage library address not found. Please deploy BuildImage first."
    );
  }

  const OnchainMadnessFactory = await ethers.getContractAt(
    "OnchainMadnessFactory",
    networkData.OM_DEPLOYER
  );
  console.log(
    `OnchainMadnessFactory loaded at ${OnchainMadnessFactory.address}`
  );

  const name = "OM_IMAGE";

  if (networkData.OM_IMAGE === "") {
    console.log("Deploying NftImage...");
    // Linking BuildImage library
    const NftImage = await ethers.getContractFactory("NftImage", {
      libraries: {
        BuildImage: networkData["Libraries"].BuildImage,
      },
    });
    const nftImage = await NftImage.deploy(
      networkData.OM_DEPLOYER
    );
    await nftImage.deployed();
    console.log(`NftImage deployed at ${nftImage.address}`);

    await new Promise((resolve) => setTimeout(resolve, 5000));

    console.log(
      `Setting NftImage address to OnchainMadnessFactory...`
    );
    await OnchainMadnessFactory.setContract(
      name,
      nftImage.address
    );

    networkData.OM_IMAGE = nftImage.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

  } else {
    console.log(`NftImage already deployed at ${networkData.OM_IMAGE}`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
