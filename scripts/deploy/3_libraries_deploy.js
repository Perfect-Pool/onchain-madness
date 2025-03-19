const fs = require("fs-extra");
const path = require("path");
const { ethers } = require("hardhat");

async function main() {
  const variablesPath = path.join(__dirname, "..", "..", "contracts.json");
  const data = JSON.parse(fs.readFileSync(variablesPath, "utf8"));
  const networkName = hre.network.name;
  const networkData = data[networkName]["Libraries"];

  if (!networkData.DinamicData || networkData.DinamicData === "") {
    throw new Error(
      "DinamicData library address not found in contracts.json. Please deploy DinamicData first."
    );
  }
  if(!networkData.RegionsData || networkData.RegionsData === "") {
    throw new Error(
      "RegionsData library address not found in contracts.json. Please deploy RegionsData first."
    );
  }
  const dinamicDataAddress = networkData.DinamicData;
  const fixedDataAddress = networkData.FixedData;
  const regionDataAddress = networkData.RegionsData;

  if (networkData.BuildImage === "") {
    console.log(
      `Deploying BuildImage with DinamicData at ${dinamicDataAddress}...`
    );

    const BuildImage = await ethers.getContractFactory("BuildImage", {
      libraries: {
        FixedData: fixedDataAddress,
        DinamicData: dinamicDataAddress,
        RegionsData: regionDataAddress,
      },
    });

    const buildImage = await BuildImage.deploy();
    await buildImage.deployed();
    console.log(`BuildImage deployed at ${buildImage.address}`);

    networkData.BuildImage = buildImage.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

    await new Promise((resolve) => setTimeout(resolve, 5000));
  } else {
    console.log(
      `BuildImage already deployed at ${networkData.BuildImage}`
    );
  }

  if (networkData.OnchainMadnessLib === "") {
    console.log(`Deploying OnchainMadnessLib...`);

    const OnchainMadnessLib = await ethers.getContractFactory("OnchainMadnessLib");
    const onchainMadnessLib = await OnchainMadnessLib.deploy();
    await onchainMadnessLib.deployed();
    console.log(`OnchainMadnessLib deployed at ${onchainMadnessLib.address}`);

    networkData.OnchainMadnessLib = onchainMadnessLib.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

    await new Promise((resolve) => setTimeout(resolve, 5000));
  } else {
    console.log(
      `OnchainMadnessLib already deployed at ${networkData.OnchainMadnessLib}`
    );
  }

  if (networkData.OnchainMadnessBetLib === "") {
    console.log(`Deploying OnchainMadnessBetLib...`);

    const OnchainMadnessBetLib = await ethers.getContractFactory("OnchainMadnessBetLib");
    const onchainMadnessBetLib = await OnchainMadnessBetLib.deploy();
    await onchainMadnessBetLib.deployed();
    console.log(`OnchainMadnessBetLib deployed at ${onchainMadnessBetLib.address}`);

    networkData.OnchainMadnessBetLib = onchainMadnessBetLib.address;
    fs.writeFileSync(variablesPath, JSON.stringify(data, null, 2));

    await new Promise((resolve) => setTimeout(resolve, 5000));
  } else {
    console.log(
      `OnchainMadnessBetLib already deployed at ${networkData.OnchainMadnessBetLib}`
    );
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
