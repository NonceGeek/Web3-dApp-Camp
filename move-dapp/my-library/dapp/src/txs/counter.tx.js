import { utils, bcs, encoding, } from "@starcoin/starcoin"
import { starcoinProvider } from "../app";
import { arrayify, hexlify } from '@ethersproject/bytes'
import { LIBRARY_ADDRESS } from "./config";

export async function getResource(address, functionId) {
    const resourceType = `${LIBRARY_ADDRESS}::${functionId}`
    console.log(resourceType)
    const resource = await starcoinProvider.getResource(address, resourceType)
    console.log(resource)
    return resource
}

export async function executeFunction(address, functionName, strTypeArgs = [], args = []) {

    const functionId = `${address}::${functionName}`;
    const tyArgs = utils.tx.encodeStructTypeTags(strTypeArgs);
    if (args.length > 0) {
        args[0] = (function () {
            const se = new bcs.BcsSerializer();
            se.serializeU64(BigInt(args[0].toString(10)));
            return hexlify(se.getBytes());
        })();
    }
    args = args.map(arg => arrayify(arg))
    const scriptFunction = utils.tx.encodeScriptFunction(functionId, tyArgs, args);

    const payloadInHex = (() => {
        const se = new bcs.BcsSerializer();
        scriptFunction.serialize(se);
        return hexlify(se.getBytes());
    })();

    const txParams = {
        data: payloadInHex,
    };

    const transactionHash = await starcoinProvider
        .getSigner()
        .sendUncheckedTransaction(txParams);
    return transactionHash
}

export async function executeFunction2(address, functionName, strTypeArgs = [], args = []) {

    const functionId = `${address}::${functionName}`;
    const tyArgs = utils.tx.encodeStructTypeTags(strTypeArgs);
    const toNameHex = (function () {
        const se = new bcs.BcsSerializer();
        se.serializeStr(args[0]);
        return hexlify(se.getBytes());
    })();
    const tolinkHex = (function () {
        const se = new bcs.BcsSerializer();
        se.serializeStr(args[1]);
        return hexlify(se.getBytes());
    })();
    const as = [
        arrayify(toNameHex),
        arrayify(tolinkHex),
    ];
    const scriptFunction = utils.tx.encodeScriptFunction(functionId, tyArgs, as);

    const payloadInHex = (() => {
        const se = new bcs.BcsSerializer();
        scriptFunction.serialize(se);
        return hexlify(se.getBytes());
    })();

    const txParams = {
        data: payloadInHex,
    };

    const transactionHash = await starcoinProvider
        .getSigner()
        .sendUncheckedTransaction(txParams);
    return transactionHash
}




