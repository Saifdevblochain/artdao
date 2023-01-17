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
  const DaoPublic = await ethers.getContractFactory(
    "DaoPublic"
  );
  console.log("Deploying DaoPublic...");
  const contract = await upgrades.deployProxy(DaoPublic, [], {
    initializer: "initialize",
    kind: "transparent",
  });
  await contract.deployed();
  console.log("DaoPublic deployed to:", contract.address);

  await new Promise(resolve => setTimeout(resolve, 20000));
  verify(contract.address, [])
}

main();