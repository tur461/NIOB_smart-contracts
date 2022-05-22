import hre from 'hardhat';
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { CONTRACTS, TAG } from "../../helpers/constants";
import { ethers } from "hardhat";
import Ether, { getIDOParams } from "../../helpers/utils";

const ADDRESS = '0xb108e6AAc7F7Cfa1C8b648556367F53249c9E737'

const func = async () => {
    const { deployments, getNamedAccounts } = hre;
    const { deployer } = await getNamedAccounts();

    // const idoOriginal = await deployments.get(TAG.IDO);
    const admin = await deployments.get(TAG.ADMIN);
    const adminProxy = await deployments.get(TAG.ADMIN_PROXY);
    
    let apContract = await ethers.getContractAt(admin.abi, adminProxy.address);
    Ether.init(deployer, adminProxy.address, admin.abi as [], apContract.provider as any);

    try{
        console.log('Tests Start...');
        console.log('adding new operator');
        await Ether.sendTx('addOperator', [ADDRESS]);
        console.log('added operator:', await apContract.hasRole(await apContract.OPERATOR(), ADDRESS));
    } catch(e) {
        console.log(e);
    }
    
};

func();
