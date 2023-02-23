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
    ["0x058d781Ac24E224DC903CE897C2D372D4388494B"], {
    initializer: "initialize",
    kind: "transparent",
  });
  await contract.deployed();
  console.log("DaoPublicTest deployed to:", contract.address);

  await new Promise(resolve => setTimeout(resolve, 20000));
  verify(contract.address, [])
}
main();