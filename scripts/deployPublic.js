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
  let DaoCommittee_ = "0xb2fcd4815Dd43F1353B88aC175A8B87Ac9290Efb"
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