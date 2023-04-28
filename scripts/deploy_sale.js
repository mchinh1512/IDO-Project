// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
// Import necessary dependencies
const { ethers } = require("hardhat");

async function deployPredumSale() {
  // Deploy the PredumSale contract
  const PredumSale = await ethers.getContractFactory("PredumSale");
  const cap = "10000000000000000000000000000";
  const tokenAddress = "0xABE2D3aB08eb4e0ef40c3B0a6AdB58Bf9fa36231";
  const tokenPrice = "40000";
  const minBuy = "50000000000000000";
   // Replace with the actual address of the token contract
  const predumSale = await PredumSale.deploy(cap, tokenAddress, tokenPrice, minBuy);
  await predumSale.deployed();

  console.log("PredumSale contract deployed to:", predumSale.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
deployPredumSale().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
