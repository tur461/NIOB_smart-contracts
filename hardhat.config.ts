import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-ethers';
import 'hardhat-deploy';
import * as dotenv from 'dotenv';
import { HardhatUserConfig, task } from 'hardhat/config';

const chainIds = {
    goerli: 5,
    hardhat: 1337,
    kovan: 42,
    mainnet: 1,
    rinkeby: 4,
    ropsten: 3,
    bsctest: 97,
    bscmain: 56,
    cronosTest: 338,
};

dotenv.config();

const INFURA_TOKEN = process.env.INFURA_TOKEN;
const BSCSCAN_API_KEY = process.env.BSCSCAN_API_KEY;
const BSC_MORALIS_TOKEN = process.env.BSC_MORALIS_TOKEN;
const DEPLOYER_PRIVATE_KEY = process.env.DEPLOYER_PRIVATE_KEY;


// task("bsctest-verify", "verifies contracts on bsc tesnet")
//   .addParam("network", "network to verify on")
//   .setAction(async (taskArgs) => {
//     // Create the contract instance
//     const MyToken = await ethers.getContractFactory("MyToken");
//     const myToken = await Aus.attach("0x80c5...");

//     // Mint
//     await myToken.mint(taskArgs.address, taskArgs.amount);
// });


const config: HardhatUserConfig = {
    defaultNetwork: "bsctest",
    networks: {
        rinkeby: {
            url: `https://rinkeby.infura.io/v3/${INFURA_TOKEN}`,
            accounts: [`0x${DEPLOYER_PRIVATE_KEY}`],
            chainId: chainIds.rinkeby,
        },
        bsctest: {
            url: `https://speedy-nodes-nyc.moralis.io/${BSC_MORALIS_TOKEN}/bsc/testnet`,
            accounts: [`0x${DEPLOYER_PRIVATE_KEY}`],
            chainId: chainIds.bsctest,
            allowUnlimitedContractSize: true,
        },
        croTest: {
            url: `https://cronos-testnet-3.crypto.org:8545`,
            accounts: [`0x${DEPLOYER_PRIVATE_KEY}`],
            chainId: chainIds.cronosTest,
            allowUnlimitedContractSize: true,
        },
        bscmain: {
            url: `https://speedy-nodes-nyc.moralis.io/${BSC_MORALIS_TOKEN}/bsc/mainnet`,
            accounts: [`0x${DEPLOYER_PRIVATE_KEY}`],
            chainId: chainIds.bscmain,
            allowUnlimitedContractSize: true,
        },
        hardhat: {},
    },
    paths: {
        tests: "./test",
        cache: "./cache",
        sources: "./contracts",
        deploy: "./scripts/all",
        artifacts: "./artifacts",
        deployments: "./deployments",
    },
    solidity: {
        compilers: [
            {
                version: "0.8.10",
                settings: {
                    metadata: {
                        bytecodeHash: "none",
                    },
                    optimizer: {
                        enabled: true,
                        runs: 1,
                    },
                
                },
            },
            {
                version: "0.8.11",
                settings: {
                    metadata: {
                        bytecodeHash: "none",
                    },
                    optimizer: {
                        enabled: true,
                        runs: 1,
                    },
                },
            },
            {
                version: "0.8.4",
                settings: {
                    metadata: {
                        bytecodeHash: "none",
                    },
                    optimizer: {
                        enabled: true,
                        runs: 1,
                    },
                },
            },
            {
                version: "0.8.10",
                settings: {
                    metadata: {
                        bytecodeHash: "none",
                    },
                    optimizer: {
                        enabled: true,
                        runs: 1,
                    },
                },
            },
            {
                version: "0.7.5",
                settings: {
                    metadata: {
                        bytecodeHash: "none",
                    },
                    optimizer: {
                        enabled: true,
                        runs: 1,
                    },
                },
            },
            {
                version: "0.5.16",
            },
            {
                version: "0.8.10",
                settings: {
                    metadata: {
                        bytecodeHash: "none",
                    },
                    optimizer: {
                        enabled: true,
                        runs: 1,
                    },
                },
            },
        ],
        settings: {
            outputSelection: {
                "*": {
                    "*": ["storageLayout"],
                },
            },
        },
    },
    namedAccounts: {
        deployer: '0x84fF670281055e51FE317c0A153AAc2D26619798',
    },
    etherscan: {
        apiKey: BSCSCAN_API_KEY,
    },
    
    mocha: {
        timeout: 60000,
    },
};

export default config;
