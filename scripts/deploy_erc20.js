// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const ERC20Mock = await hre.ethers.getContractFactory("ERC20Mock");
  const erc20mock = await ERC20Mock.deploy("ERC20Mock", "UP");

  await erc20mock.deployed();

  console.log(`deployed to ${erc20mock.address}`);

  await hre.run("verify:verify", {
    address: erc20mock.address,
    contract: "contracts/Mock/ERC20Mock.sol:ERC20Mock",
    constructorArguments: ["ERC20Mock", "UP"],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
