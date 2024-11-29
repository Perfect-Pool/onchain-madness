const hre = require("hardhat");

async function main() {
  const contracts = require("../../contracts.json");
  const networkName = hre.network.name;

  const addressTicket = contracts[networkName].OM_TICKET;
  if (!addressTicket) {
    console.error("OnchainMadnessTicket address not found in contracts.json");
    process.exit(1);
  }

  console.log("Verifying OnchainMadnessTicket at address", addressTicket);

  await hre.run("verify:verify", {
    address: addressTicket,
    constructorArguments: [contracts[networkName].USDC],
    contract: "contracts/utils/OnchainMadnessTicket.sol:OnchainMadnessTicket",
    libraries: {
      OnchainMadnessLib: contracts[networkName].Libraries.OnchainMadnessLib,
    },
  });

  const addressTicketStorage = contracts[networkName].OM_TICKET_STORAGE;
  if (!addressTicketStorage) {
    console.error(
      "TicketStorage address not found in contracts.json"
    );
    process.exit(1);
  }

  console.log(
    "Verifying TicketStorage at address",
    addressTicketStorage
  );

  await hre.run("verify:verify", {
    address: addressTicketStorage,
    constructorArguments: [contracts[networkName].OM_DEPLOYER],
    contract:
      "contracts/utils/TicketStorage.sol:TicketStorage",
  });

  const addressTicketFactory = contracts[networkName].OM_TICKET_DEPLOYER;
  if (!addressTicketFactory) {
    console.error(
      "OnchainMadnessTicketFactory address not found in contracts.json"
    );
    process.exit(1);
  }

  console.log(
    "Verifying OnchainMadnessTicketFactory at address",
    addressTicketFactory
  );

  await hre.run("verify:verify", {
    address: addressTicketFactory,
    constructorArguments: [contracts[networkName].OM_TICKET,contracts[networkName].OM_DEPLOYER],
    contract:
      "contracts/utils/OnchainMadnessTicketFactory.sol:OnchainMadnessTicketFactory",
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
