import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { CONTRACTS, ADDRESS, TAG, INIT_VAL } from "../../helpers/constants";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deployments, getNamedAccounts } = hre;
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    await deploy(TAG.STEEP_TOKEN, {
        contract: CONTRACTS.STEEP_TOKEN,
        from: deployer,
        args: [
            INIT_VAL.GEN_TOTAL_SUPPLY
        ],
        log: true,
        skipIfAlreadyDeployed: true,
    });
};

func.tags = [TAG.STEEP_TOKEN]; // optional
export default func;