const { ethers, upgrades } = require("hardhat");

async function main() {
  const DaoPublicTest = await ethers.getContractFactory(
    "DaoPublicTest"
  );
  console.log("Upgrading DaoPublicTest...");
  await upgrades.upgradeProxy(
    "0x352fAcf2c6b66Be0B40cCc01E64C9d7F038Cdc6f", // old address
    DaoPublicTest
  );
  console.log("Upgraded Successfully");
}

main();