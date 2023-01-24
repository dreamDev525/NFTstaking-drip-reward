// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const oNFT = "0xeF61B8734fcdA4Dbedd25B76b0FE45eEa2298dE6";
  const Staking = await hre.ethers.getContractFactory("UPNFTStaking_MR");
  const staking = await Staking.deploy(oNFT);

  await staking.deployed();

  console.log(`deployed to ${staking.address}`);

  await hre.run("verify:verify", {
    address: staking.address,
    contract: "contracts/UPNFTStaking_MR.sol:UPNFTStaking_MR",
    constructorArguments: [oNFT],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
