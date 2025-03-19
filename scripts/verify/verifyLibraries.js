const hre = require("hardhat");

async function main() {
  const contracts = require("../../contracts.json");
  const networkName = hre.network.name;

  const addressFixedData = contracts[networkName].Libraries.FixedData;
  if (!addressFixedData) {
    console.error("FixedData address not found in contracts.json");
    process.exit(1);
  }

  // Wait 5 seconds
  await new Promise((resolve) => setTimeout(resolve, 5000));

  console.log("Verifying FixedData at address", addressFixedData);

  await hre.run("verify:verify", {
    address: addressFixedData,
    constructorArguments: [],
    contract: "contracts/libraries/FixedData.sol:FixedData",
  });

  const addressBuildImage = contracts[networkName].Libraries.BuildImage;
  if (!addressBuildImage) {
    console.error("BuildImage address not found in contracts.json");
    process.exit(1);
  }

  // Wait 5 seconds
  await new Promise((resolve) => setTimeout(resolve, 5000));

  console.log("Verifying BuildImage at address", addressBuildImage);

  await hre.run("verify:verify", {
    address: addressBuildImage,
    constructorArguments: [],
    contract: "contracts/libraries/BuildImage.sol:BuildImage",
    libraries:{
      "DinamicData": contracts[networkName].Libraries.DinamicData,
      "FixedData": contracts[networkName].Libraries.FixedData,
      "RegionsData": contracts[networkName].Libraries.RegionsData,
    }
  });

  const addressDinamicData = contracts[networkName].Libraries.DinamicData;
  if (!addressDinamicData) {
    console.error("DinamicData address not found in contracts.json");
    process.exit(1);
  }

  // Wait 5 seconds
  await new Promise((resolve) => setTimeout(resolve, 5000));

  console.log("Verifying DinamicData at address", addressDinamicData);

  await hre.run("verify:verify", {
    address: addressDinamicData,
    constructorArguments: [],
    contract: "contracts/libraries/DinamicData.sol:DinamicData",
  });

  const addressRegionsData = contracts[networkName].Libraries.RegionsData;
  if (!addressRegionsData) {
    console.error("RegionsData address not found in contracts.json");
    process.exit(1);
  }

  // Wait 5 seconds
  await new Promise((resolve) => setTimeout(resolve, 5000));

  console.log("Verifying RegionsData at address", addressRegionsData);

  await hre.run("verify:verify", {
    address: addressRegionsData,
    constructorArguments: [],
    contract: "contracts/libraries/RegionsData.sol:RegionsData",
    libraries:{
      "RegionBuilder": contracts[networkName].Libraries.RegionBuilder,
    }
  });

  const addressRegionBuilder = contracts[networkName].Libraries.RegionBuilder;
  if (!addressRegionBuilder) {
    console.error("RegionBuilder address not found in contracts.json");
    process.exit(1);
  }

  // Wait 5 seconds
  await new Promise((resolve) => setTimeout(resolve, 5000));

  console.log("Verifying RegionBuilder at address", addressRegionBuilder);

  await hre.run("verify:verify", {
    address: addressRegionBuilder,
    constructorArguments: [],
    contract: "contracts/libraries/RegionBuilder.sol:RegionBuilder",
    libraries:{
      "DinamicData": contracts[networkName].Libraries.DinamicData,
    }
  });

  const addressOnchainMadnessLib = contracts[networkName].Libraries.OnchainMadnessLib;
  if (!addressOnchainMadnessLib) {
    console.error("OnchainMadnessLib address not found in contracts.json");
    process.exit(1);
  }

  // Wait 5 seconds
  await new Promise((resolve) => setTimeout(resolve, 5000));

  console.log("Verifying OnchainMadnessLib at address", addressOnchainMadnessLib);

  await hre.run("verify:verify", {
    address: addressOnchainMadnessLib,
    constructorArguments: [],
    contract: "contracts/libraries/OnchainMadnessLib.sol:OnchainMadnessLib",
  });

  const addressOnchainMadnessBetLib = contracts[networkName].Libraries.OnchainMadnessBetLib;
  if (!addressOnchainMadnessBetLib) {
    console.error("OnchainMadnessBetLib address not found in contracts.json");
    process.exit(1);
  }

  // Wait 5 seconds
  await new Promise((resolve) => setTimeout(resolve, 5000));

  console.log("Verifying OnchainMadnessBetLib at address", addressOnchainMadnessBetLib);

  await hre.run("verify:verify", {
    address: addressOnchainMadnessBetLib,
    constructorArguments: [],
    contract: "contracts/libraries/OnchainMadnessBetLib.sol:OnchainMadnessBetLib",
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
