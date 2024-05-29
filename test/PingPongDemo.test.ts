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

const TEN_LINK = BigInt("10000000000000000000");

describe("PingPongDemo", function () {
    let ping: Contract;
    let pong: Contract;
    let config: Config;
    let deployer;

    before(async function () {
        [deployer] = await ethers.getSigners();

        const localSimulatorFactory = await ethers.getContractFactory("CCIPLocalSimulator");
        const localSimulator = await localSimulatorFactory.deploy();

        config = await localSimulator.configuration();

        const PingPongDemoFactory = await ethers.getContractFactory("PingPongDemo");

        ping = await PingPongDemoFactory.deploy(config.sourceRouter_, config.linkToken_);
        await localSimulator.requestLinkFromFaucet(ping.address, TEN_LINK);

        pong = await PingPongDemoFactory.deploy(config.destinationRouter_, config.linkToken_);
        await localSimulator.requestLinkFromFaucet(pong.address, TEN_LINK);

        await ping.setCounterpart(config.chainSelector_, pong.address);
        await pong.setCounterpart(config.chainSelector_, ping.address);
    });

    it("should be able to Ping Pong", async function () {
        let tx = await ping.startPingPong();
        console.log(tx.events);
    });
});
