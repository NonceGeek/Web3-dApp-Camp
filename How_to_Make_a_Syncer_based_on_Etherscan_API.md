# How to Make a Syncer based on Etherscan API

## Basic Concept

What is a Syncer?  It's a scheduled job to retrieve transactions from one contract regularly and persist them locally.  

The Syncer has two main parts:

* `Syncer`: responsible for retrieving transactions from the contract and persistence handling.
* `Syncer Server`: repsonsible for job scheduling and monitoring.

## Implementation in Elixir

### Syncer

The processing logic of Syncer contain below three main steps:  

1. Retrieves the latest block number of the blockchain.  
2. Based on the last locally persited block number, retrieves transactions from the chain using Etherscan API and persist locally.  
3. Update last block number of the contract locally.  

```elixir
# https://github.com/WeLightProject/tai_shang_nft_gallery/blob/main/lib/tai_shang_nft_gallery/nft/syncer.ex

defmodule TaiShangNftGallery.Nft.Syncer do
  alias TaiShangNftGallery.NftContract
  alias TaiShangNftGallery.TxHandler
  alias TaiShangNftGallery.Chain.Fetcher
  alias TaiShangNftGallery.ScanInteractor
  require Logger

  @api_keys %{
    "Moonbeam" => System.get_env("MOONBEAM_API_KEY")
  }
  def sync(chain, %{last_block: last_block} = nft_contract) do

    # Step 1
    best_block = Fetcher.get_block_number(chain)
    # Step 2
    do_sync(chain, nft_contract, last_block, best_block)
    # Step 3
    NftContract.update(
      nft_contract,
      %{last_block: best_block + 1}
    )
  end

  def do_sync(%{name: name} = chain, %{addr: addr} = nft_contract, last_block, best_block) do
    # Step 2.1 - Retrieves Txns by Etherscan API
    {:ok, %{"result" => txs}}=
      ScanInteractor.get_txs_by_contract_addr(
        chain,
        addr,
        last_block,
        best_block,
        @api_keys[name]
      )

    # Step 2.2 - Persist transactions locally
    handle_txs(chain, nft_contract, txs)
  end

  def handle_txs(chain, nft_contract, txs) do
    Enum.each(txs, fn tx ->
      Logger.info("Handling tx: #{inspect(tx)}")
      tx_atom_map = ExStructTranslator.to_atom_struct(tx)
      TxHandler.handle_tx(chain, nft_contract, tx_atom_map)
    end)
  end
end
```

### Syncer Server

Syncer Server is implemented by `GenServer`.  For those who do not know about it, you can imagine that it's some kind of process that runs forever.  If there is any error, it can automatically restart.  

The `GenServer` operates by handling the messages received, from itself or others.  There are two main functions here:  

* `init`: The initialization function.  It loads the Contract locally, store it in the process state and sends itself a `:sync` message.  
* `handle_info`: The `:sync` message handler that calls the API of the `Syncer` to do the actual work.  

After each processing, the `Process.send_after/3` function sends itself a `:sync` message after 10 minutes.  

```elixir
#https://github.com/WeLightProject/tai_shang_nft_gallery/blob/main/lib/tai_shang_nft_gallery/syncer_server.ex
defmodule TaiShangNftGallery.SyncerServer do
  @moduledoc """
    Genserver as Syncer
  """
  alias TaiShangNftGallery.Nft.Syncer
  alias TaiShangNftGallery.NftContract
  use GenServer
  require Logger

  @sync_interval 600_000 # 10 minutes
  # +-----------+
  # | GenServer |
  # +-----------+
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: :"#nft_syncer")
  end

  def init([nft_contract_id: nft_contract_id]) do
    Logger.info("SyncerServer started yet.")
    nft_contract =
      nft_contract_id
      |> NftContract.get_by_id()
      |> NftContract.preload()
      state =
        [nft_contract: nft_contract]
    send(self(), :sync)
    {:ok, state}
  end

  def handle_info(:sync, [nft_contract: nft_contract] = state) do
    Syncer.sync(nft_contract.chain, nft_contract)
    sync_after_interval()
    {:noreply, state}
  end

  def sync_after_interval() do
    Process.send_after(self(), :sync, @sync_interval)
  end
end
```


## Implementation in Node.js

### Syncer

Let's see how do we implement the Syncer in Node.js.  Using APIs provided by [Web3](https://web3js.readthedocs.io/en/v1.7.0/web3-eth.html#getblocknumber) and [Moonbeam](https://moonbeam.moonscan.io/apis), it's very easy to interact with Moonbeam chain.  

> ### getBlockNumber
>> web3.eth.getBlockNumber([callback])  
> Returns the current block number.  
> `Promise` returns `Number` - The number of the most recent block.  


> #### Get a list of 'Normal' Transactions By Address
> [Optional Parameters] startblock: starting blockNo to retrieve results, endblock: ending blockNo to retrieve results  
> 
>> https://api-moonbeam.moonscan.io/api?module=account&action=txlist&address=0x0000000000000000000000000000000000001004&startblock=1&endblock=99999999&sort=asc&apikey=YourApiKeyToken  
> (Returned 'isError' values: 0=No Error, 1=Got Error)  
> (Returns up to a maximum of the last 10000 transactions only)  
> 
> or  
> 
>> https://api-moonbeam.moonscan.io/api?module=account&action=txlist&address=0x0000000000000000000000000000000000001004&startblock=1&endblock=99999999&page=1&offset=10&sort=asc&apikey=YourApiKeyToken  
> (To get paginated results use page=\<page number> and offset=\<max records to return>)  
> 

Below is simplified Syncer implemented in JavaScript.  In this example, I simply persist the data in memory but you can choose anything you are familiar with.  And I simply use `setTimeout` and Catch-All-Error approach to simulate a forever running process.  

```javascript
import Web3 from 'web3';
import got from 'got';

const web3 = new Web3(new Web3.providers.HttpProvider('https://rpc.api.moonbeam.network'));

// Register in https://moonbeam.moonscan.io/apis#accounts and apply one API Key
const API_KEY = '';

const LOCAL_STORAGE = {
  lastBlockNumber: 200000,
  contractAaddress: '0xb6FC950C4bC9D1e4652CbEDaB748E8Cdcfe5655F',
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

    const lastBlockNumber = LOCAL_STORAGE.lastBlockNumber || latestBlock - 1000;

    // Step 2.1 - Retrieves Txns by Etherscan API
    const transactions = await getTransactionsOfContract(LOCAL_STORAGE.contractAaddress, lastBlockNumber, latestBlock);

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
```
