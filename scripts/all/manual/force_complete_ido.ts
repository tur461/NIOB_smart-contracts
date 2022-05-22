//forceCompleteIdo
import hre from "hardhat";
import { DeployFunction } from "hardhat-deploy/types";
import { CONTRACTS, ADDRESS, TAG } from "../../helpers/constants";
import { ethers } from "hardhat";
import Ether, { getIDOParams } from "../../helpers/utils";

const func = async () => {
    const { deployments, getNamedAccounts } = hre;
    const { deployer } = await getNamedAccounts();

    const ido = await deployments.get(TAG.IDO);
    const admin = await deployments.get(TAG.ADMIN);
    const adminProxy = await deployments.get(TAG.ADMIN_PROXY);
    
    try{
        console.log('Tests Start...');
        let AdminContract = await ethers.getContractAt(admin.abi, admin.address);
        let adminViaProxy = AdminContract.attach(adminProxy.address);

        let deployed = await adminViaProxy.getIdoByOwner('0xF19250A3320bE69B80daf65D057aE05Bb12F0919');
        if(deployed) {
            console.log('it seems owner has an ido already:', deployed);
            console.log('forcefully completing ido');
            let idoContract = await ethers.getContractAt(ido.abi, deployed);
            Ether.init(deployer, deployed, ido.abi as [], idoContract.provider as any);
            await Ether.sendTx('forceCompleteIdo', []);
            let completed = await idoContract._idoCompleted();
            console.log('ido completed success:', completed);
        }
        
        console.log('Admin Test Completed.');
    } catch(e) {
        console.log(e);
    }
    
};
func();
