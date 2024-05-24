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

describe("CrossChainFlow", function () {
    let gatewayA: Contract;
    let gatewayB: Contract;
    let config: Config;
    let deployer;

    before(async function () {
        [deployer] = await ethers.getSigners();

        const localSimulatorFactory = await ethers.getContractFactory("CCIPLocalSimulator");
        const localSimulator = await localSimulatorFactory.deploy();

        config = await localSimulator.configuration();

        const GatewayAFactory = await ethers.getContractFactory("GatewayA");
        gatewayA = await GatewayAFactory.deploy(config.sourceRouter_);
        console.log("GatewayA address: ", gatewayA.address);

        // fund the GatewayA contract with native coin
        await deployer.sendTransaction({ to: gatewayA.address, value: ONE_ETHER });

        const GatewayBFactory = await ethers.getContractFactory("GatewayB");
        gatewayB = await GatewayBFactory.deploy(config.destinationRouter_);

        // fund the GatewayB contract with native coin
        await deployer.sendTransaction({ to: gatewayB.address, value: ONE_ETHER });
    });

    it("should be able to send a message from GatewayA to GatewayB", async function () {
        console.log("Before the flow");
        console.log("GatewayA data: ", await gatewayA.data());
        console.log("GatewayB data: ", await gatewayB.data());

        const message = "2-10";

        // start the flow
        await gatewayA.sendMessage(config.chainSelector_, gatewayB.address, message);

        console.log("After the flow");
        console.log("GatewayA data: ", await gatewayA.data());
        console.log("GatewayB data: ", await gatewayB.data());
    });
});
