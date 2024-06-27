const fs = require("fs-extra");
const path = require("path");
const { ethers } = require("hardhat");

async function main() {
  const variablesPath = path.join(__dirname, "..", "..", "contracts.json");
  const data = JSON.parse(fs.readFileSync(variablesPath, "utf8"));
  const networkName = hre.network.name;
  const networkData = data[networkName];

  // Carregar o contrato GamesHub
  const GamesHub = await ethers.getContractFactory("GamesHub");
  const gamesHub = await GamesHub.attach(networkData.GAMES_HUB);
  console.log(`GamesHub loaded at ${gamesHub.address}`);

  // Deploy do OnchainMadnessTicket, se necessário
  const name = "MM_TICKET";

  if (networkData.MM_TICKET === "") {
    const OnchainMadnessTicket = await ethers.getContractFactory("OnchainMadnessTicket");
    const onchainMadnessTicket = await OnchainMadnessTicket.deploy(gamesHub.address);
    await onchainMadnessTicket.deployed();
    console.log(`OnchainMadnessTicket deployed at ${onchainMadnessTicket.address}`);

    networkData.MM_TICKET = onchainMadnessTicket.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

    await new Promise((resolve) => setTimeout(resolve, 5000));

    console.log(`Setting OnchainMadnessTicket address to GamesHub...`);
    await gamesHub.setGameContact(
      onchainMadnessTicket.address,
      ethers.utils.id(name),
      true
    );

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
