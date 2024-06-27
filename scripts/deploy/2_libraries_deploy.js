const fs = require("fs-extra");
const path = require("path");
const { ethers } = require("hardhat");

async function main() {
  const variablesPath = path.join(__dirname, "..", "..", "contracts.json");
  const data = JSON.parse(fs.readFileSync(variablesPath, "utf8"));
  const networkName = hre.network.name;
  const networkData = data[networkName]["Libraries"];

  let dinamicDataAddress = networkData.DinamicData;
  if (!dinamicDataAddress) {
    throw new Error("DinamicData library is not deployed. Deploy it first.");
  }

  console.log(`Using DinamicData at address: ${dinamicDataAddress}`);

  if (networkData.RegionBuilder === "") {
    console.log(`Deploying RegionBuilder...`);

    const RegionBuilder = await ethers.getContractFactory("RegionBuilder", {
      libraries: {
        DinamicData: dinamicDataAddress,
      },
    });

    const regionBuilder = await RegionBuilder.deploy();
    await regionBuilder.deployed();
    console.log(`RegionBuilder deployed at ${regionBuilder.address}`);

    networkData.RegionBuilder = regionBuilder.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

  } else {
    console.log(`RegionBuilder already deployed at ${networkData.RegionBuilder}`);
  }

  if (networkData.RegionsData === "" && networkData.RegionBuilder !== "") {
    console.log(`Deploying RegionsData...`);

    const RegionsData = await ethers.getContractFactory("RegionsData", {
      libraries: {
        RegionBuilder: networkData.RegionBuilder,
      },
    });

    const regionData = await RegionsData.deploy();
    await regionData.deployed();
    console.log(`RegionsData deployed at ${regionData.address}`);

    networkData.RegionsData = regionData.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

  } else {
    console.log(`RegionsData already deployed at ${networkData.RegionsData}`);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
