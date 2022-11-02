import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { CryptoQuest, CryptoQuestRedux, SQLHelpers } from "../typechain-types";

// contract deployment
async function deployCryptoQuestContract(): Promise<CryptoQuestRedux> {
    const cryptoQuestReduxFactory = await ethers.getContractFactory("CryptoQuestRedux");
    const cryptoQuest = await cryptoQuestReduxFactory.deploy();

    return await cryptoQuest.deployed();
}

async function deployCryptoQuestDbContract(): Promise<CryptoQuest> {
    //tableland-local registry
    const registry = '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512';

    const libraryFactory = await ethers.getContractFactory("SQLHelpers");
    const library = await libraryFactory.deploy();

    const libDeployment =  await library.deployed();

    const dbContractFactory = await ethers.getContractFactory("CryptoQuest", {
        libraries: {
            SQLHelpers: libDeployment.address
        }
    });
    const dbContract = await dbContractFactory.deploy(registry);

    return await dbContract.deployed();
}


describe("Deployment", async function () {
    const cryptoQuest = await loadFixture(deployCryptoQuestContract);
    const cryptoQuestDb = await loadFixture(deployCryptoQuestDbContract);

    it("cryptoQuest Should have the right owner", async function () {
        const [owner] = await ethers.getSigners();
        expect(await cryptoQuest.owner()).to.equal(owner.address);
    });

    it("cryptoQuestdb Should have the right owner", async function () {
        const [owner] = await ethers.getSigners();
        expect(await cryptoQuestDb.owner()).to.equal(owner.address);
    });
});

