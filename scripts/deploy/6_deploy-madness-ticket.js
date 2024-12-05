const fs = require("fs-extra");
const path = require("path");
const { ethers } = require("hardhat");

async function main() {
  const variablesPath = path.join(__dirname, "..", "..", "contracts.json");
  const data = JSON.parse(fs.readFileSync(variablesPath, "utf8"));
  const networkName = hre.network.name;
  const networkData = data[networkName];

  const libraryAddress = networkData.Libraries.OnchainMadnessLib;
  if (!libraryAddress) {
    throw new Error("OnchainMadnessLib address not found in contracts.json");
  }

  console.log(`Using OnchainMadnessLib at address: ${libraryAddress}`);

  const OnchainMadnessFactory = await ethers.getContractAt(
    "OnchainMadnessFactory",
    networkData.OM_DEPLOYER
  );
  console.log(
    `OnchainMadnessFactory loaded at ${OnchainMadnessFactory.address}`
  );

  if (networkData.OM_ENTRY === "") {
    // Link the library
    const OnchainMadnessEntry = await ethers.getContractFactory(
      "OnchainMadnessEntry",
      {
        libraries: {
          OnchainMadnessLib: libraryAddress,
        },
      }
    );

    const onchainMadnessEntry = await OnchainMadnessEntry.deploy(
      networkData.USDC
    );
    await onchainMadnessEntry.deployed();
    console.log(
      `OnchainMadnessEntry deployed at ${onchainMadnessEntry.address}`
    );

    networkData.OM_ENTRY = onchainMadnessEntry.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

    await new Promise((resolve) => setTimeout(resolve, 2000));
  } else {
    console.log(
      `OnchainMadnessEntry already deployed at ${networkData.OM_ENTRY}`
    );
  }

  const nameStorage = "OM_ENTRY_STORAGE";

  if (networkData.OM_ENTRY_STORAGE === "") {
    const EntryStorage = await ethers.getContractFactory("EntryStorage");
    const entryStorage = await EntryStorage.deploy(networkData.OM_DEPLOYER);
    await entryStorage.deployed();
    console.log(`EntryStorage deployed at ${entryStorage.address}`);

    networkData.OM_ENTRY_STORAGE = entryStorage.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

    await new Promise((resolve) => setTimeout(resolve, 2000));

    console.log(`Setting EntryStorage address to OnchainMadnessFactory...`);
    await OnchainMadnessFactory.setContract(nameStorage, entryStorage.address);

    networkData.OM_ENTRY_STORAGE = entryStorage.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));
  } else {
    console.log(
      `EntryStorage already deployed at ${networkData.OM_ENTRY_STORAGE}`
    );
    console.log(`Setting EntryStorage address to OnchainMadnessFactory...`);
    await OnchainMadnessFactory.setContract(nameStorage, networkData.OM_ENTRY_STORAGE);
  }

  await new Promise((resolve) => setTimeout(resolve, 2000));

  // Deploy do OnchainMadnessEntry, se necessário
  const name = "OM_ENTRY_DEPLOYER";

  if (networkData.OM_ENTRY_DEPLOYER === "") {
    const OnchainMadnessEntryFactory = await ethers.getContractFactory(
      "OnchainMadnessEntryFactory"
    );
    const onchainMadnessEntryFactory =
      await OnchainMadnessEntryFactory.deploy(
        networkData.OM_ENTRY,
        networkData.OM_DEPLOYER,
        networkData.USDC
      );
    await onchainMadnessEntryFactory.deployed();
    console.log(
      `OnchainMadnessEntryFactory deployed at ${onchainMadnessEntryFactory.address}`
    );

    await new Promise((resolve) => setTimeout(resolve, 2000));

    console.log(
      `Setting OnchainMadnessEntryFactory address to OnchainMadnessFactory...`
    );
    await OnchainMadnessFactory.setContract(
      name,
      onchainMadnessEntryFactory.address
    );

    networkData.OM_ENTRY_DEPLOYER = onchainMadnessEntryFactory.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));
  } else {
    console.log(
      `OnchainMadnessEntryFactory already deployed at ${networkData.OM_ENTRY_DEPLOYER}`
    );
    console.log(
      `Setting OnchainMadnessEntryFactory address to OnchainMadnessFactory...`
    );
    await OnchainMadnessFactory.setContract(
      name,
      networkData.OM_ENTRY_DEPLOYER
    );
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
