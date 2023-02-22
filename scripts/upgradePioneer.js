const { ethers, upgrades } = require("hardhat");

async function main() {
  const DaoPublicTest = await ethers.getContractFactory(
    "DaoPublicTest"
  );
  console.log("Upgrading DaoPublicTest...");
  await upgrades.upgradeProxy(
    "0x4eD86FBcD2Cc1c5dB769AE21593296546BFa5FC9", // old address
    DaoPublicTest
  );
  console.log("Upgraded Successfully");
}

main();