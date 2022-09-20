import { ethers } from "hardhat";

// lib deploy
// async function main() {
//   const sqlHelpersLibrary = await ethers.getContractFactory("SQLHelpers");
//   const sqlHelpers = await sqlHelpersLibrary.deploy();

//   await sqlHelpers.deployed();
// }

// main contract deploy
async function main() {
  const cryptoQuestFactory = await ethers.getContractFactory("CryptoQuest", {
    libraries: {
      SQLHelpers: '0x4eAb2af45639A53Ae1D9d28b1Ee3E43b108C8608'
    }
  });
  const cryptoQuest = await cryptoQuestFactory.deploy();
  await cryptoQuest.deployed();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
