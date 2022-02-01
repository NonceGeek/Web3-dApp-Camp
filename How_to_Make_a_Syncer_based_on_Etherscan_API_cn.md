# 如何基于 Etherscan API 来实现一个 Syncer

## 基本概念和需求

Syncer 是什么？它是一个获取智能合约的交易，并存储到本地的定时任务。  

这个 Syncer 包含两大组件：

* `Syncer`: 负责获取智能合约的交易，并存储。  
* `Syncer Server`: 负责定时任务的监控。  

## Elixir 实现分析

### Syncer

Syncer 的处理逻辑包含三大步骤：  

1. 获取智能合约所在区块链的最新的区块号。  
2. 基于上次查询的区块号，通过 Etherscan API 查询智能合约的交易数，并保存。  
3. 保存好第一步获取的最新区块号供下次查询使用。  

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

    # 步骤 1
    best_block = Fetcher.get_block_number(chain)
    # 步骤 2
    do_sync(chain, nft_contract, last_block, best_block)
    # 步骤 3
    NftContract.update(
      nft_contract,
      %{last_block: best_block + 1}
    )
  end

  def do_sync(%{name: name} = chain, %{addr: addr} = nft_contract, last_block, best_block) do
    # 步骤 2.1 - 通过 Etherscan API 获取交易数
    {:ok, %{"result" => txs}}=
      ScanInteractor.get_txs_by_contract_addr(
        chain,
        addr,
        last_block,
        best_block,
        @api_keys[name]
      )

    # 步骤 2.2 - 保存交易
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

### Syncer 监控服务

Syncer 监控服务是通过 `GenServer` 来实现的。  对于不了解 Elixir 的同学来说，可以把它想像成一个永不停歇的进程。即使出错，它也能自动重启。  

`GenServer` 是通过接收从其它进程或自己发过来的消息，分配不同的处理逻辑。以下实现代码的两大函数是：  

* `init`：初始化函数。  它先从本地读出合约信息，然后保存于进程内，并发送一个 `:sync` 消息给自己。  
* `handle_info`：消息处理函数。 `:sync` 消息收到后，就调用 `Syncer` 的 API 来实现具体的交易同步功能。  

每次处理完成，`Process.send_after/3` 函数会在指定的时间（10分钟后）发送同样的一条 `:sync` 消息给自己看，从而实现定时的功能。

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


## 在 Node.js 实现相同的功能

### Syncer

通过 [Web3](https://web3js.readthedocs.io/en/v1.7.0/web3-eth.html#getblocknumber) 和 [Moonbeam](https://moonbeam.moonscan.io/apis) 提供的 API，实现起来非常容易。我们以和 Moonbeam 区块链的交互来举例。  

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

以下是简化版的 Syncer 实现。这个样例代码知识把数据保存在内存里，但是你可以使用任何你熟悉的数据库来实现数据的永久保存。同时，我也只是简单使用 `setTimeout` 和 Catch 所有错误的方式来模拟一直保持运行的服务。  

```javascript
import Web3 from 'web3';
import got from 'got';

const web3 = new Web3(new Web3.providers.HttpProvider('https://rpc.api.moonbeam.network'));

// 在 https://moonbeam.moonscan.io/apis#accounts 注册可以申请 API Key
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
