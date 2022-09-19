import { ethers } from "hardhat";

// lib deploy
// async function main() {
//   const sqlHelpersLibrary = await ethers.getContractFactory("SQLHelpers");
//   const sqlHelpers = await sqlHelpersLibrary.deploy();

//   await sqlHelpers.deployed();
// }

// main contract deploy
async function main() {
  const sqlHelpersLibrary = await ethers.getContractFactory("CryptoQuest", {
    libraries: {
      SQLHelpers: '0x4eAb2af45639A53Ae1D9d28b1Ee3E43b108C8608'
    }
  });
  const mumbaiReg = "0x4b48841d4b32C4650E4ABc117A03FE8B51f38F68";
  const sqlHelpers = await sqlHelpersLibrary.deploy(mumbaiReg);

  await sqlHelpers.deployed();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
