const fs = require("fs");
const path = require("path");

// Caminho para os artefatos do Hardhat
const artifactsDir = path.join(__dirname, "..", "artifacts", "contracts");

// Contratos para extrair ABIs
const contracts = [
  { name: "MarchMadness", path: "games/MarchMadness.sol" },
  { name: "MarchMadnessFactory", path: "games/MarchMadnessFactory.sol" },
  { name: "OnchainMadnessTicket", path: "utils/OnchainMadnessTicket.sol" },
];

// Função para extrair e salvar ABI
async function extractAndSaveAbi(contractName, contractPath) {
  const artifactPath = path.join(
    artifactsDir,
    contractPath,
    `${contractName}.json`
  );

  // Lê o arquivo do artefato do contrato
  const artifact = JSON.parse(fs.readFileSync(artifactPath, "utf8"));

  // Extrai o ABI
  const abi = artifact.abi;

  // Define o caminho do arquivo ABI de saída
  const outputDir = path.join(__dirname, "..", "abi");
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir);
  }
  const outputPath = path.join(outputDir, `${contractName}.abi.json`);

  // Salva o ABI em um arquivo
  fs.writeFileSync(outputPath, JSON.stringify(abi, null, 2));
  console.log(`ABI for ${contractName} saved to ${outputPath}`);
}

// Executa a extração para cada contrato
contracts.forEach((contract) =>
  extractAndSaveAbi(contract.name, contract.path)
);
