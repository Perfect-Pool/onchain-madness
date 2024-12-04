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

  if (networkData.OM_TICKET === "") {
    // Link the library
    const OnchainMadnessTicket = await ethers.getContractFactory(
      "OnchainMadnessTicket",
      {
        libraries: {
          OnchainMadnessLib: libraryAddress,
        },
      }
    );

    const onchainMadnessTicket = await OnchainMadnessTicket.deploy(
      networkData.USDC
    );
    await onchainMadnessTicket.deployed();
    console.log(
      `OnchainMadnessTicket deployed at ${onchainMadnessTicket.address}`
    );

    networkData.OM_TICKET = onchainMadnessTicket.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));
  } else {
    console.log(
      `OnchainMadnessTicket already deployed at ${networkData.OM_TICKET}`
    );
  }

  const nameStorage = "OM_TICKET_STORAGE";

  if (networkData.OM_TICKET_STORAGE === "") {
    const TicketStorage = await ethers.getContractFactory("TicketStorage");
    const ticketStorage = await TicketStorage.deploy(networkData.OM_DEPLOYER);
    await ticketStorage.deployed();
    console.log(`TicketStorage deployed at ${ticketStorage.address}`);

    networkData.OM_TICKET_STORAGE = ticketStorage.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

    await new Promise((resolve) => setTimeout(resolve, 5000));

    console.log(`Setting TicketStorage address to OnchainMadnessFactory...`);
    await OnchainMadnessFactory.setContract(nameStorage, ticketStorage.address);

    networkData.OM_TICKET_STORAGE = ticketStorage.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));
  } else {
    console.log(
      `TicketStorage already deployed at ${networkData.OM_TICKET_STORAGE}`
    );
    console.log(`Setting TicketStorage address to OnchainMadnessFactory...`);
    await OnchainMadnessFactory.setContract(nameStorage, networkData.OM_TICKET_STORAGE);
  }

  // Deploy do OnchainMadnessTicket, se necessário
  const name = "OM_TICKET_DEPLOYER";

  if (networkData.OM_TICKET_DEPLOYER === "") {
    const OnchainMadnessTicketFactory = await ethers.getContractFactory(
      "OnchainMadnessTicketFactory"
    );
    const onchainMadnessTicketFactory =
      await OnchainMadnessTicketFactory.deploy(
        networkData.OM_TICKET,
        networkData.OM_DEPLOYER
      );
    await onchainMadnessTicketFactory.deployed();
    console.log(
      `OnchainMadnessTicketFactory deployed at ${onchainMadnessTicketFactory.address}`
    );

    await new Promise((resolve) => setTimeout(resolve, 5000));

    console.log(
      `Setting OnchainMadnessTicketFactory address to OnchainMadnessFactory...`
    );
    await OnchainMadnessFactory.setContract(
      name,
      onchainMadnessTicketFactory.address
    );

    networkData.OM_TICKET_DEPLOYER = onchainMadnessTicketFactory.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));
  } else {
    console.log(
      `OnchainMadnessTicketFactory already deployed at ${networkData.OM_TICKET_DEPLOYER}`
    );
    console.log(
      `Setting OnchainMadnessTicketFactory address to OnchainMadnessFactory...`
    );
    await OnchainMadnessFactory.setContract(
      name,
      networkData.OM_TICKET_DEPLOYER
    );
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
