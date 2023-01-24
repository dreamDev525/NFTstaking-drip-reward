const hre = require("hardhat");

async function main() {
  await hre.run("verify:verify", {
    address: "0x25408f0f14C577A1E4dFa16037630Db65Da42B4e",
    contract: "contracts/UPNFTStaking_MR.sol:UPNFTStaking_MR",
    constructorArguments: ["0xeF61B8734fcdA4Dbedd25B76b0FE45eEa2298dE6"],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
