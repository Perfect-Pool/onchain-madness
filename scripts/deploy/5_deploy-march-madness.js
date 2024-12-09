const fs = require("fs-extra");
const path = require("path");
const { ethers } = require("hardhat");

async function main() {
  const variablesPath = path.join(__dirname, "..", "..", "contracts.json");
  const data = JSON.parse(fs.readFileSync(variablesPath, "utf8"));
  const networkName = hre.network.name;
  const networkData = data[networkName];

  console.log(`Executor Address: ${networkData.Executor}`);

  if (networkData.OM_BASE === "") {
    console.log(`Deploying OnchainMadness...`);
    const OnchainMadness = await ethers.getContractFactory("OnchainMadness");
    const onchainMadness = await OnchainMadness.deploy();
    await onchainMadness.deployed();

    console.log(`OnchainMadness deployed at ${onchainMadness.address}`);
    networkData.OM_BASE = onchainMadness.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

    await new Promise((resolve) => setTimeout(resolve, 5000));
  } else {
    console.log(`OnchainMadness already deployed at ${networkData.OM_BASE}`);
  }

  //OM_DEPLOYER
  if (networkData.OM_DEPLOYER === "") {
    console.log(`Deploying OnchainMadnessFactory...`);
    const OnchainMadnessFactory = await ethers.getContractFactory(
      "OnchainMadnessFactory"
    );
    const onchainMadnessFactory = await OnchainMadnessFactory.deploy(
      networkData.OM_BASE,
      networkData.Executor
    );
    await onchainMadnessFactory.deployed();

    console.log(
      `OnchainMadnessFactory deployed at ${onchainMadnessFactory.address}`
    );
    networkData.OM_DEPLOYER = onchainMadnessFactory.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

    if (networkData.OM_ENTRY_DEPLOYER !== ""){
      const nftDeployer = await ethers.getContractAt(
        "OnchainMadnessEntryFactory",
        networkData.OM_ENTRY_DEPLOYER 
      );
      
      console.log(
        `Set OnchainMadnessFactory as deployer for OnchainMadnessEntryFactory at ${nftDeployer.address}`
      );
      await new Promise((resolve) => setTimeout(resolve, 5000));
      await nftDeployer.setDeployer(onchainMadnessFactory.address);
    }
  } else {
    console.log(
      `OnchainMadnessFactory already deployed at ${networkData.OM_DEPLOYER}`
    );
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
