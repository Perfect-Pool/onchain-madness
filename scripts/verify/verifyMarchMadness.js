const hre = require("hardhat");

async function main() {
  const contracts = require("../../contracts.json");
  const networkName = hre.network.name;

  const address = contracts[networkName]["MM_BASE"];
  if (!address) {
    console.error("MarchMadness address not found in contracts.json");
    process.exit(1);
  }

  console.log("Verifying MarchMadness at address", address);

  await hre.run("verify:verify", {
    address: address,
    constructorArguments: [],
    contract: "contracts/games/MarchMadness.sol:MarchMadness",
  });

  const addressDeployer = contracts[networkName]["MM_DEPLOYER"];
  if (!addressDeployer) {
    console.error("MarchMadnessFactory address not found in contracts.json");
    process.exit(1);
  }

  console.log("Verifying MarchMadnessFactory at address", addressDeployer);

  await hre.run("verify:verify", {
    address: addressDeployer,
    constructorArguments: [
      contracts[networkName]["MM_BASE"],
      contracts[networkName]["GAMES_HUB"],
      contracts[networkName]["Executor"],
    ],
    contract: "contracts/games/MarchMadnessFactory.sol:MarchMadnessFactory",
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
