const hre = require("hardhat");

async function main() {
  const contracts = require("../../contracts.json");
  const networkName = hre.network.name;

  const address = contracts[networkName]["PERFECTPOOL"];
  if (!address) {
    console.error("PerfectPool address not found in contracts.json");
    process.exit(1);
  }

  console.log("Verifying PerfectPool at address", address);

  await hre.run("verify:verify", {
    address: address,
    constructorArguments: [
      contracts[networkName]["USDC"],
      contracts[networkName]["aUSDC"],
      contracts[networkName]["LendingPool"],
      "OnchainMadnessShare",
      "OCM",
      contracts[networkName]["OM_ENTRY_DEPLOYER"],
      contracts[networkName]["OM_DEPLOYER"],
    ],
    contract: "contracts/utils/PerfectPool.sol:PerfectPool",
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
