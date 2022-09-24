import { ethers } from "hardhat";

// lib deploy
// async function main() {
//   const sqlHelpersLibrary = await ethers.getContractFactory("SQLHelpers");
//   const sqlHelpers = await sqlHelpersLibrary.deploy();

//   await sqlHelpers.deployed();
// }

// cryptoQuestDeploy contract deploy
async function main() {
  // db entities
  //await cryptoQuestDeploy();

  //main contract
  await cryptoQuestReduxDeploy();
}

async function cryptoQuestReduxDeploy() {
  const cryptoQuestReduxFactory = await ethers.getContractFactory("CryptoQuestRedux", {

  });

  const cryptoQuestRedux = await cryptoQuestReduxFactory.deploy();
  await cryptoQuestRedux.deployed();
}

async function cryptoQuestDeploy() {
  const cryptoQuestFactory = await ethers.getContractFactory("CryptoQuest", {
    libraries: {
      SQLHelpers: '0x4eAb2af45639A53Ae1D9d28b1Ee3E43b108C8608'
    }
  });

  //polygon mumbai chain
  const registry = "0x4b48841d4b32C4650E4ABc117A03FE8B51f38F68";
  const cryptoQuest = await cryptoQuestFactory.deploy(registry);
  await cryptoQuest.deployed();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
