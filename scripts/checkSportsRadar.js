const axios = require('axios');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

async function main() {
  // Get contract data
  const variablesPath = path.join(__dirname, "..", "contracts.json");
  const data = JSON.parse(fs.readFileSync(variablesPath, "utf8"));
  const networkName = hre.network.name;
  const networkData = data[networkName]["OM_DEPLOYER"];

  console.log(`Using network: ${networkName}`);
  console.log(`Contract address: ${networkData}`);

  // Make the GET request to SPORTSRADAR_URL
  try {
    const response = await axios.get(process.env.SPORTSRADAR_URL);
    console.log('Response from SportsRadar:');
    console.log(JSON.stringify(response.data.rounds, null, 2));
  } catch (error) {
    console.error('Error fetching data from SportsRadar:');
    console.error(error.response ? error.response.data : error.message);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
