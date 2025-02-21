const { ethers } = require("hardhat");

async function checkPendingTransactions(signer) {
  const provider = signer.provider;
  const address = await signer.getAddress();
  
  // Get the latest nonce used on-chain
  const onchainNonce = await provider.getTransactionCount(address, "latest");
  
  // Get the pending nonce
  const pendingNonce = await provider.getTransactionCount(address, "pending");
  
  console.log(`Latest on-chain nonce: ${onchainNonce}`);
  console.log(`Pending nonce: ${pendingNonce}`);
  
  if (pendingNonce > onchainNonce) {
    console.log(`There are ${pendingNonce - onchainNonce} pending transactions`);
    
    // Optional: Get the last few blocks to check for pending txs
    const blockNumber = await provider.getBlockNumber();
    const block = await provider.getBlockWithTransactions(blockNumber);
    
    const pendingTxs = block.transactions.filter(tx => 
      tx.from.toLowerCase() === address.toLowerCase() && !tx.blockNumber
    );
    
    if (pendingTxs.length > 0) {
      console.log("Pending transactions found:");
      pendingTxs.forEach(tx => {
        console.log(`- Hash: ${tx.hash}`);
        console.log(`  Nonce: ${tx.nonce}`);
        console.log(`  Gas price: ${ethers.utils.formatUnits(tx.gasPrice, "gwei")} gwei`);
      });
    }
  } else {
    console.log("No pending transactions found");
  }
  
  return { onchainNonce, pendingNonce };
}

async function main() {
  // Get the deployer's address and check pending transactions
  const [deployer] = await ethers.getSigners();
  console.log(`\nDeployer address: ${deployer.address}\n`);
  
  await checkPendingTransactions(deployer);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
