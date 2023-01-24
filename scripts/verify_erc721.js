const hre = require("hardhat");

async function main() {
  await hre.run("verify:verify", {
    address: "0xaCd0c02DFB24980EDcd0a3F9a7D22df70E7C39F3",
    contract: "contracts/Mock/ERC721Mock.sol:ERC721Mock",
    constructorArguments: ["ERC721Mock", "oNFT"],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
