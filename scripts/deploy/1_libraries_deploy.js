const fs = require("fs-extra");
const path = require("path");
const { ethers } = require("hardhat");

async function main() {
  const DinamicData = await ethers.getContractFactory("DinamicData");

  const variablesPath = path.join(__dirname, "..", "..", "contracts.json");
  const data = JSON.parse(fs.readFileSync(variablesPath, "utf8"));
  const networkName = hre.network.name;
  const networkData = data[networkName]["Libraries"];

  if (networkData.DinamicData === "") {
    console.log(`Deploying DinamicData...`);
    const dinamicData = await DinamicData.deploy();
    await dinamicData.deployed();
    console.log(`DinamicData deployed at ${dinamicData.address}`);

    networkData.DinamicData = dinamicData.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

    await new Promise((resolve) => setTimeout(resolve, 5000));
  } else {
    console.log(`DinamicData already deployed at ${networkData.DinamicData}`);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
