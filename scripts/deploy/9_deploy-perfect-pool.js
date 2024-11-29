const fs = require("fs-extra");
const path = require("path");
const { ethers } = require("hardhat");

async function main() {
  const variablesPath = path.join(__dirname, "..", "..", "contracts.json");
  const data = JSON.parse(fs.readFileSync(variablesPath, "utf8"));
  const networkName = hre.network.name;
  const networkData = data[networkName];

  console.log(`Executor Address: ${networkData.Executor}`);

  if (networkData.PERFECTPOOL === "") {
    console.log(`Deploying PerfectPool...`);
    const PerfectPool = await ethers.getContractFactory("PerfectPool");
    const perfectPool = await PerfectPool.deploy(
      networkData.USDC,
      "PerfectPoolShare",
      "PPS",
      networkData.OM_DEPLOYER
    );
    await perfectPool.deployed();

    console.log(`PerfectPool deployed at ${perfectPool.address}`);
    networkData.PERFECTPOOL = perfectPool.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

    await new Promise((resolve) => setTimeout(resolve, 5000));
  } else {
    console.log(`PerfectPool already deployed at ${networkData.PERFECTPOOL}`);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
