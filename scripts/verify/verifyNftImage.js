const hre = require("hardhat");

async function main() {
  const contracts = require("../../contracts.json");
  const networkName = hre.network.name;

  const address = contracts[networkName]["MM_IMAGE"];
  if (!address) {
    console.error("NftImage address not found in contracts.json");
    process.exit(1);
  }

  console.log("Verifying NftImage at address", address);

  await hre.run("verify:verify", {
    address: address,
    constructorArguments: [
      contracts[networkName]["GAMES_HUB"],
    ],
    contract: "contracts/utils/NftImage.sol:NftImage",
    libraries:{
      "BuildImage": contracts[networkName].Libraries.BuildImage
    }
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
