import Web3 from 'web3';
import got from 'got';
import sqlite3 from 'sqlite3';
import abiDecoder from 'abi-decoder';

const db = new sqlite3.Database('./sqlite.db');

const web3 = new Web3(new Web3.providers.HttpProvider('https://rpc.api.moonbeam.network'));

const INTERVAL = 1 * 60 * 1000; // 10 minutes
const API_KEY = 'Y6AIFQQVAJ3H38CC11QFDUDJWAWNCWE3U8';

const CONTRACT_ADDRESS = '0xb6FC950C4bC9D1e4652CbEDaB748E8Cdcfe5655F';
const CONTRACT_ABI = [{ "inputs": [], "stateMutability": "nonpayable", "type": "constructor" }, { "anonymous": false, "inputs": [{ "indexed": true, "internalType": "address", "name": "owner", "type": "address" }, { "indexed": true, "internalType": "address", "name": "approved", "type": "address" }, { "indexed": true, "internalType": "uint256", "name": "tokenId", "type": "uint256" }], "name": "Approval", "type": "event" }, { "anonymous": false, "inputs": [{ "indexed": true, "internalType": "address", "name": "owner", "type": "address" }, { "indexed": true, "internalType": "address", "name": "operator", "type": "address" }, { "indexed": false, "internalType": "bool", "name": "approved", "type": "bool" }], "name": "ApprovalForAll", "type": "event" }, { "anonymous": false, "inputs": [{ "indexed": true, "internalType": "address", "name": "previousOwner", "type": "address" }, { "indexed": true, "internalType": "address", "name": "newOwner", "type": "address" }], "name": "OwnershipTransferred", "type": "event" }, { "anonymous": false, "inputs": [{ "indexed": true, "internalType": "address", "name": "from", "type": "address" }, { "indexed": true, "internalType": "address", "name": "to", "type": "address" }, { "indexed": true, "internalType": "uint256", "name": "tokenId", "type": "uint256" }], "name": "Transfer", "type": "event" }, { "inputs": [{ "internalType": "address", "name": "to", "type": "address" }, { "internalType": "uint256", "name": "tokenId", "type": "uint256" }], "name": "approve", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "address", "name": "owner", "type": "address" }], "name": "balanceOf", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "baseURL", "outputs": [{ "internalType": "string", "name": "", "type": "string" }], "stateMutability": "view", "type": "function" }, { "inputs": [{ "internalType": "uint256", "name": "tokenId", "type": "uint256" }], "name": "claim", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "uint256", "name": "tokenId", "type": "uint256" }], "name": "getApproved", "outputs": [{ "internalType": "address", "name": "", "type": "address" }], "stateMutability": "view", "type": "function" }, { "inputs": [{ "internalType": "uint256", "name": "tokenId", "type": "uint256" }], "name": "getFifth", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [{ "internalType": "uint256", "name": "tokenId", "type": "uint256" }], "name": "getFirst", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [{ "internalType": "uint256", "name": "tokenId", "type": "uint256" }], "name": "getFourth", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [{ "internalType": "uint256", "name": "tokenId", "type": "uint256" }], "name": "getSecond", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [{ "internalType": "uint256", "name": "tokenId", "type": "uint256" }], "name": "getSixth", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [{ "internalType": "uint256", "name": "tokenId", "type": "uint256" }], "name": "getThird", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [{ "internalType": "uint256", "name": "_tokenId", "type": "uint256" }], "name": "getTokenInfo", "outputs": [{ "internalType": "string", "name": "", "type": "string" }], "stateMutability": "view", "type": "function" }, { "inputs": [{ "internalType": "address", "name": "owner", "type": "address" }, { "internalType": "address", "name": "operator", "type": "address" }], "name": "isApprovedForAll", "outputs": [{ "internalType": "bool", "name": "", "type": "bool" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "name", "outputs": [{ "internalType": "string", "name": "", "type": "string" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "owner", "outputs": [{ "internalType": "address", "name": "", "type": "address" }], "stateMutability": "view", "type": "function" }, { "inputs": [{ "internalType": "uint256", "name": "tokenId", "type": "uint256" }], "name": "ownerOf", "outputs": [{ "internalType": "address", "name": "", "type": "address" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "renounceOwnership", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [], "name": "rule", "outputs": [{ "internalType": "string", "name": "", "type": "string" }], "stateMutability": "view", "type": "function" }, { "inputs": [{ "internalType": "address", "name": "from", "type": "address" }, { "internalType": "address", "name": "to", "type": "address" }, { "internalType": "uint256", "name": "tokenId", "type": "uint256" }], "name": "safeTransferFrom", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "address", "name": "from", "type": "address" }, { "internalType": "address", "name": "to", "type": "address" }, { "internalType": "uint256", "name": "tokenId", "type": "uint256" }, { "internalType": "bytes", "name": "_data", "type": "bytes" }], "name": "safeTransferFrom", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "address", "name": "operator", "type": "address" }, { "internalType": "bool", "name": "approved", "type": "bool" }], "name": "setApprovalForAll", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "string", "name": "_rule", "type": "string" }], "name": "setRule", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "uint256", "name": "_tokenId", "type": "uint256" }, { "internalType": "string", "name": "_tokenInfo", "type": "string" }], "name": "setTokenInfo", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "string", "name": "_commitHash", "type": "string" }], "name": "setWalletDappCommitHash", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "string", "name": "_baseURL", "type": "string" }], "name": "setbaseURL", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "bytes4", "name": "interfaceId", "type": "bytes4" }], "name": "supportsInterface", "outputs": [{ "internalType": "bool", "name": "", "type": "bool" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "symbol", "outputs": [{ "internalType": "string", "name": "", "type": "string" }], "stateMutability": "view", "type": "function" }, { "inputs": [{ "internalType": "uint256", "name": "index", "type": "uint256" }], "name": "tokenByIndex", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [{ "internalType": "address", "name": "owner", "type": "address" }, { "internalType": "uint256", "name": "index", "type": "uint256" }], "name": "tokenOfOwnerByIndex", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [{ "internalType": "uint256", "name": "tokenId", "type": "uint256" }], "name": "tokenURI", "outputs": [{ "internalType": "string", "name": "", "type": "string" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "totalSupply", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [{ "internalType": "address", "name": "from", "type": "address" }, { "internalType": "address", "name": "to", "type": "address" }, { "internalType": "uint256", "name": "tokenId", "type": "uint256" }], "name": "transferFrom", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "address", "name": "newOwner", "type": "address" }], "name": "transferOwnership", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [], "name": "walletDappCommitHash", "outputs": [{ "internalType": "string", "name": "", "type": "string" }], "stateMutability": "view", "type": "function" }];

abiDecoder.addABI(CONTRACT_ABI);

async function sync() {
  try {
    const contract = await getContractInfo(CONTRACT_ADDRESS);

    // Step 1 - Retrieves the latest block number of the blockchain
    const latestBlock = await web3.eth.getBlockNumber();
    console.log(`Latest blockNumber is: ${latestBlock}`);

    const lastBlockNumber = contract.lastBlockNumber || latestBlock - 100000;

    // Step 2.1 - Retrieves Txns by Etherscan API
    const transactions = await getTransactionsOfContract(contract.address, lastBlockNumber, latestBlock);
    console.log(`${transactions.length} transactions retrieved from Block ${lastBlockNumber} to ${latestBlock}.`);

    if (transactions.length > 0) {
      // Step 2.2 - Handle transactions
      await handleTransactions(contract, transactions);
    }

    // Step 3 - Persist the latest block number
    contract.lastBlockNumber = latestBlock + 1;
    await updateContractLastBlockNumber(contract);
    console.log(`lastBlockNumber of contract ${contract.id} is updated to ${contract.lastBlockNumber}.`);
  } catch (error) {
    console.error('Failed to sync transactions.', error);
  }

  nextRun();
}

function nextRun() {
  setTimeout(sync, INTERVAL);
}

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

async function _runSQL(tableStatement, params = {}) {
  return new Promise(function (resolve, reject) {
    db.run(tableStatement, params, function (err) {
      if (err) {
        return reject(err);
      }

      resolve(this.lastID); // Only value for INSERT statement
    });
  })
}

async function createContractTable() {
  return _runSQL(`CREATE TABLE IF NOT EXISTS contract (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    lastBlockNumber INTEGER NOT NULL,
    address TEXT NOT NULL
  )`);
}

async function createNftTable() {
  return _runSQL(`CREATE TABLE IF NOT EXISTS nft (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    contractId INTEGER NOT NULL,
    tokenId INTEGER NOT NULL,
    uri TEXT,
    owner TEXT
  )`);
}

async function _getContract(address) {
  return new Promise(function (resolve, reject) {
    db.get('SELECT id, lastBlockNumber, address FROM contract WHERE address = $address', { $address: address }, function (err, result) {
      if (err) {
        return reject(err);
      }

      return resolve(result);
    });
  });
}

async function getContractInfo(address) {
  let contract = await _getContract(address);
  if (contract) {
    return contract;
  }

  contract = {
    lastBlockNumber: 0,
    address
  };
  const contractId = await _runSQL(
    'INSERT INTO contract (lastBlockNumber, address) VALUES ($lastBlockNumber, $address)',
    {
      $lastBlockNumber: contract.lastBlockNumber,
      $address: contract.address
    }
  );
  contract.id = contractId;
  return contract;
}

async function updateContractLastBlockNumber(contract) {
  return _runSQL(
    'UPDATE contract SET lastBlockNumber = $lastBlockNumber WHERE id = $id',
    {
      $lastBlockNumber: contract.lastBlockNumber,
      $id: contract.id
    }
  );
}

function _getParam(params, name) {
  return params.find(param => param.name === name);
}

/**
 * Transfer the ownership of the NTF token
 * @param {*} contract The NFT contract
 * @param {*} transaction The transaction executing the claim method
 * @param {*} params Decoded parameters provided to the method.  Sample:
 *  [
 *    {
 *      name: 'from',
 *      value: '0xc994b5384c0d0611de2ece7d6ff1ad16c34a812f',
 *      type: 'address'
 *    },
 *    {
 *      name: 'to',
 *      value: '0x9c88a415f6a8043d7eaf14db721efbd8309e7365',
 *      type: 'address'
 *    },
 *    { name: 'tokenId', value: '888888', type: 'uint256' }
 *  ]
 */
async function transferHandler(contract, transaction, params) {
  const to = _getParam(params, 'to').value;
  const tokenId = parseInt(_getParam(params, 'tokenId').value);

  return _runSQL(
    `UPDATE nft SET owner = $owner WHERE contractId = $contractId and tokenId = $tokenId`,
    { $owner: to, $contractId: contract.id, $tokenId: tokenId }
  );
}

/**
 * Initialize the NFT token
 * @param {*} contract The NFT contract
 * @param {*} transaction The transaction executing the claim method
 * @param {*} params Decoded parameters provided to the method.  Sample: [{ name: 'tokenId', value: '199398', type: 'uint256' }]
 */
async function claimHandler(contract, transaction, params) {
  const tokenId = parseInt(_getParam(params, 'tokenId').value);
  const uri = await getTokenUri(contract.address, tokenId);
  // console.log(`Token uri: ${uri}`);
  const nft = {
    $contractId: contract.id,
    $tokenId: tokenId,
    $uri: uri,
    $owner: transaction.from,
  };

  return _runSQL(
    `INSERT INTO nft (contractId, tokenId, uri, owner) VALUES ($contractId, $tokenId, $uri, $owner)`,
    nft
  );
}

async function getTokenUri(contractAddress, tokenId) {
  const data = web3.eth.abi.encodeFunctionCall({
    name: 'tokenURI',
    type: 'function',
    inputs: [{
      type: 'uint256',
      name: 'tokenId'
    }]
  }, [tokenId]);

  const uriHex = await web3.eth.call({
    to: contractAddress, // contract address
    data
  });

  return web3.utils.hexToUtf8(uriHex);
}

const TRANSACTION_HANDLER = {
  safeTransferFrom: transferHandler,
  transferFrom: transferHandler,
  claim: claimHandler
}

async function handleTransactions(contract, transactions) {
  for (let i = 0; i < transactions.length; i++) {
    const transaction = transactions[i];
    const decodedMethod = abiDecoder.decodeMethod(transaction.input);
    // console.log('--------------------', transaction.from);
    // console.log(JSON.stringify(decodedMethod, null, 2));
    const handler = TRANSACTION_HANDLER[decodedMethod.name];
    if (handler) {
      await handler(contract, transaction, decodedMethod.params);
    }
  }
}

async function execute() {
  await createContractTable();

  await createNftTable();

  await sync();
}

execute();
