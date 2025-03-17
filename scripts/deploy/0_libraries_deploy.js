const fs = require("fs-extra");
const path = require("path");
const { ethers } = require("hardhat");

async function main() {
  // Get the deployer's address and nonce
  const [deployer] = await ethers.getSigners();
  const nonce = await deployer.getTransactionCount();
  console.log(`Deployer address: ${deployer.address}`);
  console.log(`Current nonce: ${nonce}`);
  
  const variablesPath = path.join(__dirname, "..", "..", "contracts.json");
  const data = JSON.parse(fs.readFileSync(variablesPath, "utf8"));
  const networkName = hre.network.name;
  const networkData = data[networkName]["Libraries"];

  const FixedData = await ethers.getContractFactory("FixedData");

  if (networkData.FixedData === "") {
    console.log(`Deploying FixedData...`);
    const fixedData = await FixedData.deploy();
    await fixedData.deployed();
    console.log(`FixedData deployed at ${fixedData.address}`);

    networkData.FixedData = fixedData.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

    await new Promise((resolve) => setTimeout(resolve, 5000));
  } else {
    console.log(`FixedData already deployed at ${networkData.FixedData}`);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
