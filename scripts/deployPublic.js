const { ethers } = require("hardhat");

const { network, run } = require("hardhat");

async function verify(address, constructorArguments) {
  console.log(`verify  ${address} with arguments ${constructorArguments.join(',')}`)
  await run("verify:verify", {
    address,
    constructorArguments
  })
}


async function main() {
  const DaoPublicTest = await ethers.getContractFactory(
    "DaoPublicTest"
  );
  console.log("Deploying DaoPublicTest...");
  const contract = await upgrades.deployProxy(DaoPublicTest, 
    ["0x805790bA4AF1A044949a1dB27Ba10a8D957d77Dc "], {
    initializer: "initialize",
    kind: "transparent",
  });
  await contract.deployed();
  console.log("DaoPublicTest deployed to:", contract.address);

  await new Promise(resolve => setTimeout(resolve, 20000));
  verify(contract.address, [])
}
// 0x7DC1f3352E5E3e01b99428d0005545c1A94222cD
main();