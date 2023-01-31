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
  const DaoCommittee = await ethers.getContractFactory(
    "DaoCommittee"
  );
  console.log("Deploying DaoCommittee...");
  const contract = await upgrades.deployProxy(DaoCommittee, [], {
    initializer: "initialize",
    kind: "transparent",
  });
  await contract.deployed();
  console.log("DaoCommittee deployed to:", contract.address);

  await new Promise(resolve => setTimeout(resolve, 20000));
  verify(contract.address, [])
}

main();

// 0xc42021D099652CdeB704FE4e08f37Bc0652B8A13