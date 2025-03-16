const hre = require("hardhat");

async function main() {
  const contracts = require("../../contracts.json");
  const networkName = hre.network.name;

  const address = contracts[networkName]["OM_BASE"];
  if (!address) {
    console.error("OnchainMadness address not found in contracts.json");
    process.exit(1);
  }

  // Wait 5 seconds
  await new Promise((resolve) => setTimeout(resolve, 5000));

  console.log("Verifying OnchainMadness at address", address);

  await hre.run("verify:verify", {
    address: address,
    constructorArguments: [],
    contract: "contracts/games/OnchainMadness.sol:OnchainMadness",
  });

  const addressDeployer = contracts[networkName]["OM_DEPLOYER"];
  if (!addressDeployer) {
    console.error("OnchainMadnessFactory address not found in contracts.json");
    process.exit(1);
  }

  // Wait 5 seconds
  await new Promise((resolve) => setTimeout(resolve, 5000));

  console.log("Verifying OnchainMadnessFactory at address", addressDeployer);

  await hre.run("verify:verify", {
    address: addressDeployer,
    constructorArguments: [
      contracts[networkName]["OM_BASE"],
      contracts[networkName]["Executor"],
      networkName.includes("testnet")
    ],
    libraries: {
      OnchainMadnessLib: contracts[networkName]["Libraries"]["OnchainMadnessLib"],
    },
    contract: "contracts/games/OnchainMadnessFactory.sol:OnchainMadnessFactory",
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
