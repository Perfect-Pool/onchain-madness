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

  let fakeLending;

  // Deploy FakeLending and get aUSDC address if needed
  if (networkData.LendingPool === "") {
    console.log("Deploying FakeLending contract...");
    const FakeLending = await ethers.getContractFactory("FakeLending");
    fakeLending = await FakeLending.deploy(networkData.USDC);
    await fakeLending.deployed();
    console.log(`FakeLending deployed at ${fakeLending.address}`);

    // Get aUSDC address from the FakeLending contract
    const aUSDCAddress = await fakeLending.aUSDC();
    console.log(`aUSDC token deployed at ${aUSDCAddress}`);

    // Update the network data
    networkData.LendingPool = fakeLending.address;
    networkData.aUSDC = aUSDCAddress;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

    // Wait a bit for the network to sync
    await new Promise((resolve) => setTimeout(resolve, 2000));
  } else {
    console.log(`LendingPool already deployed at ${networkData.LendingPool}`);
    fakeLending = await ethers.getContractAt(
      "FakeLending",
      networkData.LendingPool
    );
  }

  // Get aUSDC address if needed
  if (networkData.aUSDC === "") {
    // Get aUSDC address from the FakeLending contract
    const aUSDCAddress = await fakeLending.aUSDC();
    console.log(`aUSDC token deployed at ${aUSDCAddress}`);

    // Update the network data
    networkData.aUSDC = aUSDCAddress;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

    // Wait a bit for the network to sync
    await new Promise((resolve) => setTimeout(resolve, 2000));
  }

  console.log(`Executor Address: ${networkData.Executor}`);
  const name = "PERFECTPOOL";
  if (networkData.PERFECTPOOL === "") {
    console.log(`Deploying PerfectPool...`);
    const PerfectPool = await ethers.getContractFactory("PerfectPool");
    const perfectPool = await PerfectPool.deploy(
      networkData.USDC,
      networkData.aUSDC,
      networkData.LendingPool,
      "OnchainMadnessShare",
      "OCM",
      networkData.OM_ENTRY_DEPLOYER,
      networkData.OM_DEPLOYER
    );
    await perfectPool.deployed();

    console.log(`PerfectPool deployed at ${perfectPool.address}`);
    networkData.PERFECTPOOL = perfectPool.address;
    console.log(`Setting PerfectPool address to OnchainMadnessFactory...`);
    await OnchainMadnessFactory.setContract(name, perfectPool.address);
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

    await new Promise((resolve) => setTimeout(resolve, 2000));
  } else {
    console.log(`PerfectPool already deployed at ${networkData.PERFECTPOOL}`);
    console.log(`Setting PerfectPool address to OnchainMadnessFactory...`);
    await OnchainMadnessFactory.setContract(name, networkData.PERFECTPOOL);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
