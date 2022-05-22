import hre from 'hardhat';
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { CONTRACTS, ADDRESS, TAG } from "../../helpers/constants";
import { ethers } from "hardhat";
import Ether, { getIDOParams } from "../../helpers/utils";

const func = async () => {
    const { deployments, getNamedAccounts } = hre;
    const { deployer } = await getNamedAccounts();
    
    const cstToken = await deployments.get(TAG.CST_TOKEN);
    const cstFaucet = await deployments.get(TAG.CST_FAUCET);
    
    let spContract = await ethers.getContractAt(stakingProxy.abi, stakingProxy.address);
    Ether.init(deployer, stakingProxy.address, stakingProxy.abi as [], spContract.provider as any);
    try{
        console.log('Upgrading...');
        console.log('upgrading staking proxy to new implementation:', staking.address);
        let rec = await Ether.sendTx('upgradeTo', [staking.address]);
        console.log('staking upgrade success:', await spContract.implementation() == staking.address);
    } catch(e) {
        console.log(e);
    }
    
};

func();
