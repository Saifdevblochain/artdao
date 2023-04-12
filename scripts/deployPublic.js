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
  let DaoCommittee_ = "0x79Ac5B72D7B847Dd2310fBa7E2E1EAA73E812414"
  let timer_= 300
  let FIXED_DURATION= 300;
  const DaoPublic = await ethers.getContractFactory(
    "DaoPublic"
  );
  console.log("Deploying DaoPublic...");
  const contract = await upgrades.deployProxy(DaoPublic, 
    [DaoCommittee_,timer_,FIXED_DURATION], {
    initializer: "initialize",
    kind: "transparent",
  });
  await contract.deployed();
  console.log("DaoPublic deployed to:", contract.address);

  await new Promise(resolve => setTimeout(resolve, 20000));
  verify(contract.address, [])
}
main();