import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { CONTRACTS, ADDRESS, TAG, INIT_VAL } from "../../helpers/constants";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deployments, getNamedAccounts } = hre;
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    await deploy(TAG.CSTAR_TOKEN, {
        contract: CONTRACTS.CSTAR_TOKEN,
        from: deployer,
        args: [
            INIT_VAL.GEN_TOTAL_SUPPLY
        ],
        log: true,
        skipIfAlreadyDeployed: true,
    });
};

func.tags = [TAG.CSTAR_TOKEN]; // optional
export default func;