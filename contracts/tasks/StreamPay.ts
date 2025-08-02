import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";

task("deploy-stream", "Deploys Stream contract").setAction(
  async (_args, hre: HardhatRuntimeEnvironment) => {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contracts with:", deployer.address);
    const StreamFactory = await hre.ethers.getContractFactory("StreamContract");
    const stream = await StreamFactory.deploy();
    await stream.waitForDeployment();
    const streamAddress = await stream.getAddress();
    console.log("StreamContract deployed at:", streamAddress);
  }
);
