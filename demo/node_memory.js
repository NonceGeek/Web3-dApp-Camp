import Web3 from 'web3';
import got from 'got';

const web3 = new Web3(new Web3.providers.HttpProvider('https://rpc.api.moonbeam.network'));

const API_KEY = 'Y6AIFQQVAJ3H38CC11QFDUDJWAWNCWE3U8';

const LOCAL_STORAGE = {
  lastBlockNumber: 200000,
  contractAddress: '0xb6FC950C4bC9D1e4652CbEDaB748E8Cdcfe5655F',
  transactions: []
}

const INTERVAL = 1 * 60 * 1000 ; // 10 minute

async function getTransactionsOfContract(contractAddress, fromBlock, toBlock) {
  const url = `https://api-moonbeam.moonscan.io/api?module=account&action=txlist&address=${contractAddress}&startblock=${fromBlock}&endblock=${toBlock}&sort=asc&apikey=${API_KEY}`;
  const response = await got(url).json();

  // Result is an array of transaction objects:
  // {
  //   "blockNumber": "262972",
  //   "timeStamp": "1643033466",
  //   "hash": "0x7ebfa330656b1e72ce6265e6f4805a6e3a3245b5a4aa6ae7b468647b60c20790",
  //   "nonce": "0",
  //   "blockHash": "0xc7f8da296c2dd14230cee58819c21f4e039f93457f4320a4cb804deac1e008c0",
  //   "transactionIndex": "3",
  //   "from": "0x713c8c77112858a3bd14a5fb380fa0c4c5b1a8bd",
  //   "to": "0xb6fc950c4bc9d1e4652cbedab748e8cdcfe5655f",
  //   "value": "0",
  //   "gas": "318834",
  //   "gasPrice": "100000000000",
  //   "isError": "0",
  //   "txreceipt_status": "1",
  //   "input": "0x379607f5000000000000000000000000000000000000000000000000000000000000026d",
  //   "contractAddress": "",
  //   "cumulativeGasUsed": "423899",
  //   "gasUsed": "135169",
  //   "confirmations": "54223"
  // }
  return response.result;
}

async function sync() {
  try {
    // Step 1 - Retrieves the latest block number of the blockchain
    const latestBlock = await web3.eth.getBlockNumber();

    const lastBlockNumber = LOCAL_STORAGE.lastBlockNumber || latestBlock - 100000;

    // Step 2.1 - Retrieves Txns by Etherscan API
    const transactions = await getTransactionsOfContract(LOCAL_STORAGE.contractAddress, lastBlockNumber, latestBlock);

    // Step 2.2 - Persist transactions locally
    LOCAL_STORAGE.transactions.push(...transactions);

    // Step 3 - Persist the latest block number locally
    LOCAL_STORAGE.lastBlockNumber = latestBlock + 1;

    console.log(`${transactions.length} transactions retrieved from Block ${lastBlockNumber} to ${latestBlock}.`);
  } catch (error) {
    console.error('Failed to sync transactions.', error);
  }

  nextRun();
}

function nextRun() {
  setTimeout(sync, INTERVAL);
}

sync();
