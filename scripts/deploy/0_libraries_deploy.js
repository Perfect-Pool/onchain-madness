const fs = require("fs-extra");
const path = require("path");
const { ethers } = require("hardhat");

async function main() {
  const variablesPath = path.join(__dirname, "..", "..", "contracts.json");
  const data = JSON.parse(fs.readFileSync(variablesPath, "utf8"));
  const networkName = hre.network.name;
  const networkData = data[networkName]["Libraries"];

  const FixedDataPart2 = await ethers.getContractFactory("FixedDataPart2");

  if (networkData.FixedDataPart2 === "") {
    console.log(`Deploying FixedDataPart2...`);
    const fixedDataPart2 = await FixedDataPart2.deploy();
    await fixedDataPart2.deployed();
    console.log(`FixedDataPart2 deployed at ${fixedDataPart2.address}`);

    networkData.FixedDataPart2 = fixedDataPart2.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

    await new Promise((resolve) => setTimeout(resolve, 5000));
  }

  const FixedData = await ethers.getContractFactory("FixedData", {
    libraries: {
      FixedDataPart2: networkData.FixedDataPart2,
    },
  });

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
