import hre from 'hardhat';
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { CONTRACTS, ADDRESS, TAG } from "../../helpers/constants";
import { ethers } from "hardhat";
import Ether, { getIDOParams } from "../../helpers/utils";

const func = async () => {
    const { deployments, getNamedAccounts } = hre;
    const { deployer } = await getNamedAccounts();

    const idoOriginal = await deployments.get(TAG.IDO);
    const admin = await deployments.get(TAG.ADMIN);
    const adminProxy = await deployments.get(TAG.ADMIN_PROXY);
    
    let apContract = await ethers.getContractAt(admin.abi, adminProxy.address);

    try{
        console.log('Tests Start...');
        console.log('checking implementation address in admin proxy..');
        let rec = await Ether.sendTx('changeIdoOriginal', [idoOriginal.address]);
        console.log('Admin set ido original to new:', idoOriginal.address);
    } catch(e) {
        console.log(e);
    }
    
};

func();
