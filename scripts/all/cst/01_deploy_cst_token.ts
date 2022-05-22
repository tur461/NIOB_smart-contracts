import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { CONTRACTS, TAG, INIT_VAL } from "../../helpers/constants";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deployments, getNamedAccounts } = hre;
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    await deploy(TAG.CST_TOKEN, {
        contract: CONTRACTS.CST_TOKEN,
        from: deployer,
        args: [
            INIT_VAL.INITIAL_MINT_AMOUNT
        ],
        log: true,
        skipIfAlreadyDeployed: true,
    });
};
func.tags = [TAG.CST_TOKEN];
export default func;
