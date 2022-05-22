import { ethers,  } from "hardhat";

interface Typed {
    to: string,
    abi: [],
    from: string,
    provider: any,
}

const param: Typed = {
    to: '',
    abi: [],
    from: '',
    provider: {},
}

const Ether = {
    ...param,
    get iface() : any {
        return new ethers.utils.Interface(this.abi) as any;
    },
    init: function(f: any, t: any, a: [], p: any) : void {
        this.to = t,
        this.from = f;
        this.abi = a;
        this.provider = p;
    },
    bytecode: function(meth: any, values: any) : any {
        return this.iface.encodeFunctionData(meth, values);
    },
    sendTx: async function(meth: any, values: any) {
        let txo = {from: this.from, to: this.to, data: this.bytecode(meth, values)}
        let txHash = await this.provider.send('eth_sendTransaction', [txo]);
        return this.provider.waitForTransaction(txHash) as any;
    }
}

export function getIDOParams() {
    return {
        addresses: [
            '0x84fF670281055e51FE317c0A153AAc2D26619798',
            '0x6DF6a2D4ce73Fc937625Db2E5fb5762F248B30F3',
            '0x84fF670281055e51FE317c0A153AAc2D26619798',
            '0x83D685Ed8D7E2591c998bF2c87e01c5795Df55fd',
            '0x84fF670281055e51FE317c0A153AAc2D26619798',
            '0xA32daa29Be748DfaB1Bc9d092a9e7E420232680D',
            '0x284cEc882ce5956F774AF6249eC0a45C4957CaD9'
        ],
        timings: [
            0, // pub start
            Math.floor((Date.now() / 1000)) + 1 * 60 * 60 * 60, // pvt start
            0, // pub dur
            1 * 60 * 60 * 60 // pvt dur
        ],
        limits: [
            7,
            0,
            `123456${'0'.repeat(18)}`, // hcap
            `10${'0'.repeat(18)}`, // scap
            `10000${'0'.repeat(18)}`, // total supply
            `37${'0'.repeat(18)}`, // max alloc
            430 // lp share 4.3%
        ],
        pubsaleEn: false
    }
}

export default Ether;