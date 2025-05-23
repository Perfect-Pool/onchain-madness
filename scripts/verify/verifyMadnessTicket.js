const hre = require("hardhat");

async function main() {
  const contracts = require("../../contracts.json");
  const networkName = hre.network.name;

  const addressEntry = contracts[networkName].OM_ENTRY;
  if (!addressEntry) {
    console.error("OnchainMadnessEntry address not found in contracts.json");
    process.exit(1);
  }

  // Wait 5 seconds
  await new Promise((resolve) => setTimeout(resolve, 5000));

  console.log("Verifying OnchainMadnessEntry at address", addressEntry);

  await hre.run("verify:verify", {
    address: addressEntry,
    constructorArguments: [contracts[networkName].USDC],
    contract: "contracts/utils/OnchainMadnessEntry.sol:OnchainMadnessEntry"
  });

  const addressEntryStorage = contracts[networkName].OM_ENTRY_STORAGE;
  if (!addressEntryStorage) {
    console.error("EntryStorage address not found in contracts.json");
    process.exit(1);
  }

  // Wait 5 seconds
  await new Promise((resolve) => setTimeout(resolve, 5000));

  console.log("Verifying EntryStorage at address", addressEntryStorage);

  await hre.run("verify:verify", {
    address: addressEntryStorage,
    constructorArguments: [contracts[networkName].OM_DEPLOYER],
    contract: "contracts/utils/EntryStorage.sol:EntryStorage",
  });

  const addressBetCheck = contracts[networkName].BET_CHECK;
  if (!addressBetCheck) {
    console.error("BetCheck address not found in contracts.json");
    process.exit(1);
  }

  // Wait 5 seconds
  await new Promise((resolve) => setTimeout(resolve, 5000));

  console.log("Verifying BetCheck at address", addressBetCheck);

  await hre.run("verify:verify", {
    address: addressBetCheck,
    constructorArguments: [
      contracts[networkName].OM_DEPLOYER,
    ],
    contract: "contracts/utils/BetCheck.sol:BetCheck",
    libraries: {
      OnchainMadnessLib: contracts[networkName].Libraries.OnchainMadnessLib,
      OnchainMadnessBetLib: contracts[networkName].Libraries.OnchainMadnessBetLib,
    },
  });

  const addressEntryFactory = contracts[networkName].OM_ENTRY_DEPLOYER;
  if (!addressEntryFactory) {
    console.error(
      "OnchainMadnessEntryFactory address not found in contracts.json"
    );
    process.exit(1);
  }

  console.log(
    "Verifying OnchainMadnessEntryFactory at address",
    addressEntryFactory
  );

  await hre.run("verify:verify", {
    address: addressEntryFactory,
    constructorArguments: [
      contracts[networkName].OM_ENTRY,
      contracts[networkName].OM_DEPLOYER,
      contracts[networkName].USDC,
    ],
    contract:
      "contracts/utils/OnchainMadnessEntryFactory.sol:OnchainMadnessEntryFactory",
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
