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

  console.log(`Executor Address: ${networkData.Executor}`);
  const name = "PERFECTPOOL";
  if (networkData.PERFECTPOOL === "") {
    console.log(`Deploying PerfectPool...`);
    const PerfectPool = await ethers.getContractFactory("PerfectPool", {
      libraries: {
        OnchainMadnessLib: networkData["Libraries"].OnchainMadnessLib,
      },
    });
    const perfectPool = await PerfectPool.deploy(
      networkData.USDC,
      "PerfectPoolShare",
      "PPS",
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
