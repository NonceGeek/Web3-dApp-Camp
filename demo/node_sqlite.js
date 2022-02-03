import Web3 from 'web3';
import got from 'got';
import sqlite3 from 'sqlite3';

const db = new sqlite3.Database('./sqlite.db');

const web3 = new Web3(new Web3.providers.HttpProvider('https://rpc.api.moonbeam.network'));

const API_KEY = 'Y6AIFQQVAJ3H38CC11QFDUDJWAWNCWE3U8';

const CONTRACT_ADDRESS = '0xb6FC950C4bC9D1e4652CbEDaB748E8Cdcfe5655F';

const INTERVAL = 1 * 60 * 1000 ; // 10 minute

async function sync() {
  try {
    const contract = await getContractInfo(CONTRACT_ADDRESS);

    // Step 1 - Retrieves the latest block number of the blockchain
    const latestBlock = await web3.eth.getBlockNumber();
    console.log(`Latest blockNumber is: ${latestBlock}`);

    db.get('SELECT COUNT(1) as txn_count FROM contract_transaction where contractId = $contractId', [contract.id], function(err, row) {
      console.log(`Contract ${contract.id} has ${row.txn_count} of transactions.`);
    })

    const lastBlockNumber = contract.lastBlockNumber || latestBlock - 100000;

    // Step 2.1 - Retrieves Txns by Etherscan API
    const transactions = await getTransactionsOfContract(contract.address, lastBlockNumber, latestBlock);
    console.log(`${transactions.length} transactions retrieved from Block ${lastBlockNumber} to ${latestBlock}.`);

    if (transactions.length > 0) {
      // Step 2.2 - Persist transactions
      await saveTransactions(contract, transactions);
      console.log(`${transactions.length} transactions saved.`);
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

async function _createTable(tableStatement) {
  return new Promise(function (resolve, reject) {
    db.run(tableStatement, function (err) {
      if (err) {
        return reject(err);
      }

      resolve();
    });
  })
}

async function createContractTable() {
  return _createTable(`CREATE TABLE IF NOT EXISTS contract (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    lastBlockNumber INTEGER NOT NULL,
    address TEXT NOT NULL
  )`);
}

async function createTransactionTable() {
  return _createTable(`CREATE TABLE IF NOT EXISTS contract_transaction (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    contractId INTEGER NOT NULL,
    blockNumber TEXT,
    timeStamp TEXT,
    hash TEXT,
    nonce TEXT,
    blockHash TEXT,
    transactionIndex TEXT,
    fromAddress TEXT,
    toAddress TEXT,
    value TEXT,
    gas TEXT,
    gasPrice TEXT,
    isError TEXT,
    txreceipt_status TEXT,
    input TEXT,
    contractAddress TEXT,
    cumulativeGasUsed TEXT,
    gasUsed TEXT,
    confirmations TEXT
  )`);
}

async function getContractInfo(address) {
  return new Promise(function(resolve, reject) {
    db.get('SELECT id, lastBlockNumber, address FROM contract WHERE address = $address', { $address: address }, function (err, result) {
      if (err) {
        return reject(err);
      }

      if (result) {
        return resolve(result);
      }

      if (!result) {
        const contract = {
          lastBlockNumber: 0,
          address
        };
        db.run('INSERT INTO contract (lastBlockNumber, address) VALUES ($lastBlockNumber, $address)', {
          $lastBlockNumber: contract.lastBlockNumber,
          $address: contract.address
        }, function(err) {
          if (err) {
            return reject(err);
          }

          contract.id = this.lastID;
          resolve(contract);
        });
      }
    });
  });
}

async function updateContractLastBlockNumber(contract) {
  return new Promise(function (resolve, reject) {
    db.run('UPDATE contract SET lastBlockNumber = $lastBlockNumber WHERE id = $id', {
      $lastBlockNumber: contract.lastBlockNumber,
      $id: contract.id
    }, function (err) {
      if (err) {
        return reject(err);
      }

      resolve();
    });
  })
}

async function saveTransactions(contract, transactions) {
  const params = transactions.map((transaction) => {
    return {
      $contractId: contract.id,
      $blockNumber: transaction.blockNumber,
      $timeStamp: transaction.timeStamp,
      $hash: transaction.hash,
      $nonce: transaction.nonce,
      $blockHash: transaction.blockHash,
      $transactionIndex: transaction.transactionIndex,
      $from: transaction.from,
      $to: transaction.to,
      $value: transaction.value,
      $gas: transaction.gas,
      $gasPrice: transaction.gasPrice,
      $isError: transaction.isError,
      $txreceipt_status: transaction.txreceipt_status,
      $input: transaction.input,
      $contractAddress: transaction.contractAddress,
      $cumulativeGasUsed: transaction.cumulativeGasUsed,
      $gasUsed: transaction.gasUsed,
      $confirmations: transaction.confirmations
    }
  });

  return new Promise(function(resolve, reject) {
    for (let i = 0; i < params.length; i++) {
      db.run(
        `INSERT INTO contract_transaction (contractId, blockNumber, timeStamp, hash, nonce, blockHash, transactionIndex, fromAddress, toAddress, value, gas, gasPrice, isError, txreceipt_status, input, contractAddress, cumulativeGasUsed, gasUsed, confirmations)
        VALUES ($contractId, $blockNumber, $timeStamp, $hash, $nonce, $blockHash, $transactionIndex, $from, $to, $value, $gas, $gasPrice, $isError, $txreceipt_status, $input, $contractAddress, $cumulativeGasUsed, $gasUsed, $confirmations)`,
        params[i],
        function (err) {
          if (err) {
            return reject(err);
          }
        }
      );
    }

    db.wait(resolve);
  });
}

async function execute() {
  await createContractTable();

  await createTransactionTable();

  await sync();
}

execute();
