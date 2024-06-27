const fs = require("fs-extra");
const path = require("path");
const { ethers } = require("hardhat");

async function main() {
  const variablesPath = path.join(__dirname, "..", "..", "contracts.json");
  const data = JSON.parse(fs.readFileSync(variablesPath, "utf8"));
  const networkName = hre.network.name;
  const networkData = data[networkName];

  const GamesHub = await ethers.getContractAt(
    "GamesHub",
    networkData.GAMES_HUB
  );
  console.log(`GamesHub loaded at ${GamesHub.address}`);
  console.log(`Executor Address: ${networkData.Executor}`);

  if (networkData.MM_BASE === "") {
    console.log(`Deploying MarchMadness...`);
    const MarchMadness = await ethers.getContractFactory("MarchMadness");
    const marchMadness = await MarchMadness.deploy();
    await marchMadness.deployed();

    console.log(`MarchMadness deployed at ${marchMadness.address}`);
    networkData.MM_BASE = marchMadness.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

    await new Promise((resolve) => setTimeout(resolve, 5000));

    console.log(`Setting MarchMadness address to GamesHub...`);
    await GamesHub.setGameContact(
      marchMadness.address,
      ethers.utils.id("MM_BASE"),
      true
    );

    await new Promise((resolve) => setTimeout(resolve, 5000));
  } else {
    console.log(`MarchMadness already deployed at ${networkData.MM_BASE}`);
  }

  //MM_DEPLOYER
  if (networkData.MM_DEPLOYER === "") {
    console.log(`Deploying MarchMadnessFactory...`);
    const MarchMadnessFactory = await ethers.getContractFactory(
      "MarchMadnessFactory"
    );
    const marchMadnessFactory = await MarchMadnessFactory.deploy(
      networkData.MM_BASE,
      networkData.GAMES_HUB,
      networkData.Executor
    );
    await marchMadnessFactory.deployed();

    console.log(
      `MarchMadnessFactory deployed at ${marchMadnessFactory.address}`
    );
    networkData.MM_DEPLOYER = marchMadnessFactory.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

    await new Promise((resolve) => setTimeout(resolve, 5000));

    console.log(`Setting MarchMadness address to GamesHub...`);
    await GamesHub.setGameContact(
      marchMadnessFactory.address,
      ethers.utils.id("MM_DEPLOYER"),
      false
    );
  } else {
    console.log(
      `MarchMadnessFactory already deployed at ${networkData.MM_DEPLOYER}`
    );
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
