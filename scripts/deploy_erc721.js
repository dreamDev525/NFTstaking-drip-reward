// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const ERC721Mock = await hre.ethers.getContractFactory("ERC721Mock");
  const erc721mock = await ERC721Mock.deploy("ERC721Mock", "oNFT");

  await erc721mock.deployed();

  console.log(`deployed to ${erc721mock.address}`);

  await hre.run("verify:verify", {
    address: erc721mock.address,
    contract: "contracts/Mock/ERC721Mock.sol:ERC721Mock",
    constructorArguments: ["ERC721Mock", "oNFT"],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
