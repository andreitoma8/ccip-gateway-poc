import { Contract, ContractFactory } from "ethers";
import { ethers } from "hardhat";

interface Config {
    chainSelector_: bigint;
    sourceRouter_: string;
    destinationRouter_: string;
    wrappedNative_: string;
    linkToken_: string;
    ccipBnM_: string;
    ccipLnM_: string;
}

const ONE_ETHER = BigInt("1000000000000000000");
const TEN_LINK = BigInt("10000000000000000000");

describe("SendWithAck", function () {
    let messageTracker: Contract;
    let acknowledger: Contract;
    let config: Config;
    let deployer;

    before(async function () {
        [deployer] = await ethers.getSigners();

        const localSimulatorFactory = await ethers.getContractFactory("CCIPLocalSimulator");
        const localSimulator = await localSimulatorFactory.deploy();

        config = await localSimulator.configuration();

        const MessageTrackerFactory = await ethers.getContractFactory("MessageTracker");
        messageTracker = await MessageTrackerFactory.deploy(config.sourceRouter_, config.linkToken_);
        console.log("MessageTracker address: ", messageTracker.address);

        // fund the MessageTracker contract with link
        await localSimulator.requestLinkFromFaucet(messageTracker.address, TEN_LINK);

        const AcknowledgerFactory = await ethers.getContractFactory("Acknowledger");
        acknowledger = await AcknowledgerFactory.deploy(config.destinationRouter_, config.linkToken_);

        // fund the Acknowledger contract with link
        await localSimulator.requestLinkFromFaucet(acknowledger.address, TEN_LINK);
    });

    it("should be able to send a message from MessageTracker to Acknowledger", async function () {
        // Whitelist the MessageTracker and Acknowledger contracts
        await messageTracker.allowlistDestinationChain(config.chainSelector_, true);
        await messageTracker.allowlistSourceChain(config.chainSelector_, true);
        await messageTracker.allowlistSender(acknowledger.address, true);

        await acknowledger.allowlistDestinationChain(config.chainSelector_, true);
        await acknowledger.allowlistSourceChain(config.chainSelector_, true);
        await acknowledger.allowlistSender(messageTracker.address, true);

        await messageTracker.sendMessagePayLINK(config.chainSelector_, acknowledger.address, "LALALA");
    });
});
