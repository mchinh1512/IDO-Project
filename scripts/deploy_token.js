// Import necessary dependencies
const { ethers } = require("hardhat");

async function main() {
  // Deploy the PredumToken contract
  const PredumToken = await ethers.getContractFactory("PredumToken");
  const predumToken = await PredumToken.deploy();
  await predumToken.deployed();

  console.log("PredumToken contract deployed to:", predumToken.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });