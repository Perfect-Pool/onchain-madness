const fs = require("fs-extra");
const path = require("path");
const { ethers } = require("hardhat");

async function main() {
  const variablesPath = path.join(__dirname, "..", "..", "contracts.json");
  const data = JSON.parse(fs.readFileSync(variablesPath, "utf8"));
  const networkName = hre.network.name;
  const networkData = data[networkName];

  // Deploy do OnchainMadnessTicket, se necessário
  const name = "MM_TICKET";

  if (networkData.MM_TICKET === "") {
    const OnchainMadnessTicket = await ethers.getContractFactory("OnchainMadnessTicket");
    const onchainMadnessTicket = await OnchainMadnessTicket.deploy();
    await onchainMadnessTicket.deployed();
    console.log(`OnchainMadnessTicket deployed at ${onchainMadnessTicket.address}`);

    networkData.MM_TICKET = onchainMadnessTicket.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

    await new Promise((resolve) => setTimeout(resolve, 5000));
  } else {
    console.log(`OnchainMadnessTicket already deployed at ${networkData.MM_TICKET}`);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
