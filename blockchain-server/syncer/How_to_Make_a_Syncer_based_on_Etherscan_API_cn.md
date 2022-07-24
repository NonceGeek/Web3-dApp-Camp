# 基于 MoonbeamScan 实现Blockchain Syncer

> MoonbeamScan 地址：
>
> https://moonbeam.moonscan.io/
>
> 代码示例中的`Web3Dev`合约：
>
> https://moonbeam.moonscan.io/address/0xb6FC950C4bC9D1e4652CbEDaB748E8Cdcfe5655F

## 0x01 什么是 Syncer？

Syncer 是什么？它是一个获取智能合约的交易，并存储到本地的定时任务。  

这个 Syncer 包含三大组件：

* `Syncer`: 负责获取智能合约的交易，并存储。  
* `Parser`：交易解析。
* `Syncer Server`: 负责定时任务的监控。  

Syncer 很有用，它可以对链上数据进行格式化与缓存，从而使各种dApp与服务可以更快捷地读取链上数据，从而提升体验。

传统的 Syncer 是通过连接区块链节点来实现的，这样的好处是更加稳定而且更加 Crypto；但我们还有一种更轻量的选择——通过调用 Etherscan 类浏览器的 API 来实现 Syncer！Etherscan 提供了获取特定合约所有交易的接口，因此我们可以用更低的复杂度来做 Syncer。这听上去没有那么 Web3，因为 Syncer 依赖于浏览器服务的正常运转，但是在大多数场景下，it works well！

## 0x02 Elixir 实现分析

> 源码地址：
>
> https://github.com/WeLightProject/tai_shang_nft_gallery

### 2.1 Syncer

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

### 2.2 Syncer 监控服务

Syncer 监控服务是通过 `GenServer` 来实现的。  对于不了解 Elixir 的同学来说，可以把它想像成一个永不停歇的进程。即使出错，它也能自动重启。  

`GenServer` 是通过接收从其它进程或自己发过来的消息，分配不同的处理逻辑。以下实现代码的两大函数是：  

* `init`：初始化函数。  它先从本地读出合约信息，然后保存于进程内，并发送一个 `:sync` 消息给自己。  
* `handle_info`：消息处理函数。 `:sync` 消息收到后，就调用 `Syncer` 的 API 来实现具体的交易同步功能。  

每次处理完成，`Process.send_after/3` 函数会在指定的时间（10分钟后）发送同样的一条 `:sync` 消息给自己看，从而实现定时的功能。

```elixir
# https://github.com/WeLightProject/tai_shang_nft_gallery/blob/main/lib/tai_shang_nft_gallery/syncer_server.ex
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


### 2.3 解析交易详情

不同的交易实质上是调用不同的合约方法，为了准确识别合约做了什么，我们可以对交易`Input`进行解析，交易`Input`长这样：

```
0x379607f5000000000000000000000000000000000000000000000000000000000000026d
```

`TxHandler.handle_tx/3` 借助`ABI`，调用了`ABIHandler.find_and_decode/2`方法，去完成`Input`的解析。

```elixir
# https://github.com/WeLightProject/tai_shang_nft_gallery/blob/main/lib/tai_shang_nft_gallery/tx_handler.ex
defmodule TaiShangNftGallery.TxHandler do
  @moduledoc """
      Handle Ethereum Tx.
  """

  alias TaiShangNftGallery.ABIHandler
  alias TaiShangNftGallery.NftContract

  def handle_tx(chain, nft_contract, tx) do
    %{
      from: from,
      to: to,
      value: value,
      input: input
    } = tx

    do_handle_tx(chain, from, to, value, input, nft_contract)
  end

  def do_handle_tx(chain, from, to, value, input, %{type: type} = nft_contract) do
    input_handled =
      nft_contract
      |> NftContract.preload(:deep)
      |> Map.get(:contract_abi)
      |> Map.get(:abi)
      |> ABIHandler.find_and_decode(input)

    "Elixir.TaiShangNftGallery.TxHandler.#{type}"
    |> String.to_atom()
    |> apply(:handle_tx, [chain, nft_contract, from, to, value, input_handled])
  end
end
```

```elixir
# https://github.com/WeLightProject/tai_shang_nft_gallery/blob/main/lib/tai_shang_nft_gallery/abi_handler.ex
defmodule TaiShangNftGallery.ABIHandler do
  alias Utils.TypeTranslator
  def find_and_decode(abi, input_hex) do
    abi
    |> ABI.parse_specification
    |> ABI.find_and_decode(TypeTranslator.hex_to_bin(input_hex))
  end
end
```

以`Web3DevNFT`为例，我们实现一个`ContractHandler`，解析了如下的方法。除此之外的方法，我们直接返回`{:ok, "Pass"}`。

* `safeTransferFrom` / `trasnferFrom`: 发送NFT给其他人（标准ERC721接口）
* `claim`: 申领NFT（标准ERC721接口）
* `setTokenInfo`:  设置Token中的信息

```elixir
# https://github.com/WeLightProject/tai_shang_nft_gallery/blob/main/lib/tai_shang_nft_gallery/tx_handler/web_3_dev.ex
defmodule TaiShangNftGallery.TxHandler.Web3Dev do
  alias TaiShangNftGallery.Nft
  alias TaiShangNftGallery.Nft.Interactor
  alias Utils.TypeTranslator

  require Logger
  def handle_tx(chain, nft_contract, from, to, value,
    {%{function: func_name}, data})  do
      do_handle_tx(
        func_name,
        nft_contract, from, to, value, data, chain
      )
  end

  def handle_tx(_chain, _nft_contract, _from, _to, _value, _others) do
    :pass
  end

  def do_handle_tx(func, _nft_contract, from, _to, _value,
    [_from_bin, to_bin, token_id], _chain) when
    func in ["safeTransferFrom", "transferFrom"] do
    # Change Owner
    to_str = TypeTranslator.bin_to_addr(to_bin)
    Logger.info("Transfer NFT from #{from} to #{to_str}")
    nft = Nft.get_by_token_id(token_id)
    Nft.update(nft, %{token_id: token_id, owner: to_str})
  end

  def do_handle_tx("claim", %{id: nft_c_id, addr: addr}, from, _to, _value, [token_id], chain) do
    # INIT Token
    uri = Interactor.get_token_uri(chain, addr, token_id)
    Nft.create(
      %{
        uri: uri,
        token_id: token_id,
        owner: from,
        nft_contract_id: nft_c_id
    })
  end

  def do_handle_tx(
    "setTokenInfo",
    %{id: nft_c_id}, _from, _to, _value,
    [token_id, badges_raw], _chain) do
    # UPDATE TokenInfo

    token_id
    |> Nft.get_by_token_id_and_nft_contract_id(nft_c_id)
    |> Nft.update(%{
        badges: Poison.decode!(badges_raw), token_id: token_id
    }, :with_badges)
  end

  def do_handle_tx(_others, _, _, _, _, _, _) do
    {:ok, "pass"}
  end
end
```

## 0x03 用 Node.js 实现相同的功能

该代码见：

> https://github.com/WeLightProject/Web3-dApp-Camp/tree/main/blockchain-server/syncer/syncer_demo_js

### 3.1 Syncer

通过 [Web3](https://web3js.readthedocs.io/en/v1.7.0/web3-eth.html#getblocknumber) 和 [Moonbeam](https://moonbeam.moonscan.io/apis) 提供的 API，实现起来非常容易。我们以和 Moonbeam 区块链的交互来举例。  

> #### getBlockNumber
>> web3.eth.getBlockNumber([callback])  
> Returns the current block number.  
> ##### Returns
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

以下是 Syncer 的 JavaScript 实现。这个样例代码知识把数据保存在 SQLite 里，但是你也可以使用其它你熟悉的数据库来实现。同时，我也只是简单使用 `setTimeout` 和 Catch 所有错误的方式来模拟一直保持运行的服务。  

```javascript
import Web3 from 'web3';
import got from 'got';
import sqlite3 from 'sqlite3';
import abiDecoder from 'abi-decoder';

const db = new sqlite3.Database('./sqlite.db');

const web3 = new Web3(new Web3.providers.HttpProvider('https://rpc.api.moonbeam.network'));

const INTERVAL = 1 * 60 * 1000; // 10 minutes
const API_KEY = 'Y6AIFQQVAJ3H38CC11QFDUDJWAWNCWE3U8';

const CONTRACT_ADDRESS = '0xb6FC950C4bC9D1e4652CbEDaB748E8Cdcfe5655F';
const CONTRACT_ABI = []; // ABI can be retrieved from https://moonbeam.moonscan.io/address/0xb6FC950C4bC9D1e4652CbEDaB748E8Cdcfe5655F#code

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

  return response.result;
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

async function execute() {
  // SQLite DB tables should be initialized first.

  await sync();
}

execute();
```

### 3.2 解析交易

同样，我们需要用到 Web3 提供的 API 来解析交易的详情。

> #### encodeFunctionCall
>> web3.eth.abi.encodeFunctionCall(jsonInterface, parameters);  
> Encodes a function call using its JSON interface object and given parameters.  
> ##### Parameters
> 1. `jsonInterface` - `Object`: The JSON interface object of a function.  
> 2. `parameters` - `Array`: The parameters to encode.  
> 3. `Function` - (optional) Optional callback, returns an error object as first parameter and the result as second.
> ##### Returns
> `String` - The ABI encoded function call. Means function signature + parameters.  
> ##### Example
>```javascript
> web3.eth.abi.encodeFunctionCall({
>   name: 'myMethod',
>   type: 'function',
>   inputs: [{
>       type: 'uint256',
>       name: 'myNumber'
>   },{
>       type: 'string',
>       name: 'myString'
>   }]
> }, ['2345675643', 'Hello!%']);
> "0x24ee0097000000000000000000000000000000000000000000000000000000008bd02b7b0000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000748656c6c6f212500000000000000000000000000000000000000000000000000"
>```

> #### call
>> web3.eth.call(callObject [, defaultBlock] [, callback])  
> Executes a message call transaction, which is directly executed in the VM of the node, but never mined into the blockchain.  
> ##### Parameters
> 1. `Object` - A transaction object, see web3.eth.sendTransaction. For calls the from property is optional however it is highly recommended to explicitly set it or it may default to address(0) depending on your node or provider.  
> 2. `Number|String|BN|BigNumber` - (optional) If you pass this parameter it will not use the default block set with web3.eth.defaultBlock. Pre-defined block numbers as "earliest", "latest" and "pending" can also be used.  
> 3. `Function` - (optional) Optional callback, returns an error object as first parameter and the result as second.
> ##### Returns
> `Promise` returns `String` - The returned data of the call, e.g. a smart contract functions return value.  
> ##### Example
>```javascript
> web3.eth.call({
>   to: "0x11f4d0A3c12e86B4b5F39B213F7E19D048276DAe", // contract address
>   data: "0xc6888fa10000000000000000000000000000000000000000000000000000000000000003"
> })
> .then(console.log);
> "0x000000000000000000000000000000000000000000000000000000000000000a"
>```

> #### hexToUtf8
>> web3.utils.hexToUtf8(hex)  
> Returns the UTF-8 string representation of a given HEX value.  
> ##### Parameters
> 1. `hex` - `String`: A HEX string to convert to a UTF-8 string.
> ##### Returns
> `String`: The UTF-8 string.  
> ##### Example
>```javascript
> web3.utils.hexToUtf8('0x49206861766520313030e282ac');
> "I have 100€"
>```


```javascript
const TRANSACTION_HANDLER = {
  safeTransferFrom: transferHandler,
  transferFrom: transferHandler,
  claim: claimHandler
}

async function handleTransactions(contract, transactions) {
  for (let i = 0; i < transactions.length; i++) {
    const transaction = transactions[i];
    const decodedMethod = abiDecoder.decodeMethod(transaction.input);

    const handler = TRANSACTION_HANDLER[decodedMethod.name];
    if (handler) {
      await handler(contract, transaction, decodedMethod.params);
    }
  }
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
```
