const fs = require("fs-extra");
const path = require("path");
const { ethers } = require("hardhat");

async function main() {
  const variablesPath = path.join(__dirname, "..", "..", "contracts.json");
  const data = JSON.parse(fs.readFileSync(variablesPath, "utf8"));
  const networkName = hre.network.name;
  const networkData = data[networkName];

  console.log(`Executor Address: ${networkData.Executor}`);

  if (networkData.OM_BASE === "") {
    console.log(`Deploying OnchainMadness...`);
    const OnchainMadness = await ethers.getContractFactory("OnchainMadness");
    const onchainMadness = await OnchainMadness.deploy();
    await onchainMadness.deployed();

    console.log(`OnchainMadness deployed at ${onchainMadness.address}`);
    networkData.OM_BASE = onchainMadness.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

    await new Promise((resolve) => setTimeout(resolve, 5000));
  } else {
    console.log(`OnchainMadness already deployed at ${networkData.OM_BASE}`);
  }

  let onchainMadnessFactory;
  //OM_DEPLOYER
  if (networkData.OM_DEPLOYER === "") {
    console.log(`Deploying OnchainMadnessFactory...`);
    const OnchainMadnessFactory = await ethers.getContractFactory(
      "OnchainMadnessFactory"
    );
    onchainMadnessFactory = await OnchainMadnessFactory.deploy(
      networkData.OM_BASE,
      networkData.Executor
    );
    await onchainMadnessFactory.deployed();

    console.log(
      `OnchainMadnessFactory deployed at ${onchainMadnessFactory.address}`
    );
    networkData.OM_DEPLOYER = onchainMadnessFactory.address;

    if (networkData.OM_ENTRY_DEPLOYER !== "") {
      const nftDeployer = await ethers.getContractAt(
        "OnchainMadnessEntryFactory",
        networkData.OM_ENTRY_DEPLOYER
      );

      console.log(
        `Set OnchainMadnessFactory as deployer for OnchainMadnessEntryFactory at ${nftDeployer.address}`
      );
      await new Promise((resolve) => setTimeout(resolve, 2000));
      await nftDeployer.setGameDeployer(onchainMadnessFactory.address);
    }
    if (networkData.OM_ENTRY_STORAGE !== "") {
      const entryStorage = await ethers.getContractAt(
        "EntryStorage",
        networkData.OM_ENTRY_STORAGE
      );
      console.log(
        `Set OnchainMadnessFactory as deployer for EntryStorage at ${entryStorage.address}`
      );
      await new Promise((resolve) => setTimeout(resolve, 2000));
      await entryStorage.setDeployer(onchainMadnessFactory.address);
    }
    if (networkData.OM_IMAGE !== "") {
      const nftImage = await ethers.getContractAt(
        "NftImage",
        networkData.OM_IMAGE
      );
      console.log(
        `Set OnchainMadnessFactory as deployer for NftImage at ${nftImage.address}`
      );
      await new Promise((resolve) => setTimeout(resolve, 2000));
      await nftImage.setDeployer(onchainMadnessFactory.address);
    }
    if (networkData.OM_METADATA !== "") {
      const nftMetadata = await ethers.getContractAt(
        "NftMetadata",
        networkData.OM_METADATA
      );
      console.log(
        `Set OnchainMadnessFactory as deployer for NftMetadata at ${nftMetadata.address}`
      );
      await new Promise((resolve) => setTimeout(resolve, 2000));
      await nftMetadata.setDeployer(onchainMadnessFactory.address);
    }
    if (networkData.BET_CHECK !== "") {
      const betCheck = await ethers.getContractAt(
        "BetCheck",
        networkData.BET_CHECK
      );
      console.log(
        `Set OnchainMadnessFactory as deployer for BetCheck at ${betCheck.address}`
      );
      await new Promise((resolve) => setTimeout(resolve, 2000));
      await betCheck.setDeployer(onchainMadnessFactory.address);
    }
    if (networkData.REGION_CHECK !== "") {
      const regionCheck = await ethers.getContractAt(
        "RegionCheck",
        networkData.REGION_CHECK
      );
      console.log(
        `Set OnchainMadnessFactory as deployer for RegionCheck at ${regionCheck.address}`
      );
      await new Promise((resolve) => setTimeout(resolve, 2000));
      await regionCheck.setDeployer(onchainMadnessFactory.address);
    }
    if (networkData.TREASURY !== "") {
      await onchainMadnessFactory.setContract("TREASURY", networkData.TREASURY);
      console.log(
        `Set Treasury contract at ${networkData.TREASURY} on OnchainMadnessFactory`
      );
    }

    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));
  } else {
    console.log(
      `OnchainMadnessFactory already deployed at ${networkData.OM_DEPLOYER}`
    );

    onchainMadnessFactory = await ethers.getContractAt(
      "OnchainMadnessFactory",
      networkData.OM_DEPLOYER
    );
  }

  //BET_CHECK
  if (networkData.BET_CHECK === "") {
    console.log(`Deploying BetCheck...`);
    const BetCheck = await ethers.getContractFactory("BetCheck");
    const betCheck = await BetCheck.deploy(networkData.OM_DEPLOYER);
    await betCheck.deployed();

    console.log(`BetCheck deployed at ${betCheck.address}`);
    networkData.BET_CHECK = betCheck.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

    await new Promise((resolve) => setTimeout(resolve, 2000));

    console.log(`Setting BetCheck address to OnchainMadnessFactory...`);
    await onchainMadnessFactory.setContract("BET_CHECK", networkData.BET_CHECK);
  } else {
    console.log(`BetCheck already deployed at ${networkData.BET_CHECK}`);
    await onchainMadnessFactory.setContract("BET_CHECK", networkData.BET_CHECK);
  }

  //REGION_CHECK
  if (networkData.REGION_CHECK === "") {
    console.log(`Deploying RegionCheck...`);
    const RegionCheck = await ethers.getContractFactory("RegionCheck");
    const regionCheck = await RegionCheck.deploy(networkData.OM_DEPLOYER);
    await regionCheck.deployed();

    console.log(`RegionCheck deployed at ${regionCheck.address}`);
    networkData.REGION_CHECK = regionCheck.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

    await new Promise((resolve) => setTimeout(resolve, 2000));

    console.log(`Setting RegionCheck address to OnchainMadnessFactory...`);
    await onchainMadnessFactory.setContract("REGION_CHECK", networkData.REGION_CHECK);
  } else {
    console.log(`RegionCheck already deployed at ${networkData.REGION_CHECK}`);
    await onchainMadnessFactory.setContract("REGION_CHECK", networkData.REGION_CHECK);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
