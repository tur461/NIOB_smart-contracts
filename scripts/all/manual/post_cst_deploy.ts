import hre from 'hardhat';
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { CONTRACTS, ADDRESS, TAG } from "../../helpers/constants";
import Ether from "../../helpers/utils";
import { ethers } from "hardhat";

const func = async () => {
    const { deployments, getNamedAccounts } = hre;
    const { deployer } = await getNamedAccounts();
    
    const cstToken = await deployments.get(TAG.CST_TOKEN);
    const cstFaucet = await deployments.get(TAG.CST_FAUCET);
    
    let cstt = await ethers.getContractAt(cstToken.abi, cstToken.address);
    let cstf = await ethers.getContractAt(cstFaucet.abi, cstFaucet.address);

    Ether.init(deployer, cstToken.address, cstToken.abi as [], cstt.provider as any);
    try{
        console.log('post deploy script..');
        console.log('setting faucet address in cst Token..');
        await Ether.sendTx('setFaucet', [cstFaucet.address]);
        
        Ether.init(deployer, cstFaucet.address, cstFaucet.abi as [], cstf.provider as any);
        console.log('setting cst token address in cst faucet..')
        await Ether.sendTx('setToken', [cstToken.address]);
        console.log('completed.');
    } catch(e) {
        console.log(e);
    }
    
};

func();
