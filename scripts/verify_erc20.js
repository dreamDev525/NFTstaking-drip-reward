const hre = require("hardhat");

async function main() {
  await hre.run("verify:verify", {
    address: "0x4b7317FC24Fe57F1edaa7015f10A71421d1Dde19",
    contract: "contracts/Mock/ERC20Mock.sol:ERC20Mock",
    constructorArguments: ["ERC20Mock", "UP"],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
