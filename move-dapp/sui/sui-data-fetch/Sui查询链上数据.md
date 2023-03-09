# Sui:查询链上数据

## 通过ID / address直接查询
在sui中查询数据最直接的方式就是通过Object Id获取object信息。

```rust
import { JsonPrcProvider } from '@mysten/sui.js'
const provider = new JsonRpcProvider();
// 查询单个对象数据
const objectId = '0xd7d27a9a68c11b9035be08428feceea9bf374510';
provider.getObject(objectId);

// 查询多个对象数据
const objectIds = [
  '0x9177ffd1ab19b7dfe6323f2674fb58c29c75bf7a',
  '0xa46d8caa8ac4d39791a0542ae99de1f8ffb9a18d'
];
provider.getObjectBatch(objectIds);

// 通过对象ID查询其包含的其他对象
provider.getObjectsOwnedByObject(objectId)

// 查询某个地址下拥有的对象
const address = '0x81b9154bf2135207168ee73ac47a45af20af6431';
provider.getObjectsOwnedByAddress(address)
```

## 利用devInspectTransaction 查询数据
devInspectTransaction原理是：利用实时的链上数据模拟方法调用，解析调用结果来获取需要的数据。

它的优势在于：
- 模拟调用，无需gas
- 可以直接调用非 entry的 public方法，并获取返回结果
- 自定义查询逻辑，支持各类复杂的查询需求

```rust
module test_query::test_query {
  
  use std::vector;
  use std::type_name::{TypeName, get};
  use sui::object::{Self, UID};
  use sui::table::{Self, Table};
  use sui::tx_context::TxContext;
  use sui::transfer;
  
  struct A has drop {}
  struct B has drop {}
  
  struct BalanceSheet has copy, store, drop {
    cash: u64,
    debt: u64
  }
  
  struct BalanceSheets has key {
    id: UID,
    table: Table<TypeName, BalanceSheet>
  }
  
  struct QueryResult has copy, drop {
    typeName: TypeName,
    balanceSheet: BalanceSheet,
  }
  
  fun init(ctx: &mut TxContext) {
    let balanceSheets = BalanceSheets {
      id: object::new(ctx),
      table: table::new(ctx)
    };
    table::add(&mut balanceSheets.table, get<A>(), BalanceSheet { cash: 100, debt: 20 });
    table::add(&mut balanceSheets.table, get<B>(), BalanceSheet { cash: 80, debt: 10 });
    transfer::share_object(balanceSheets)
  }
  
  public fun query(balanceSheets: &BalanceSheets): vector<QueryResult> {
    let res = vector::empty<QueryResult>();
    let typeA = get<A>();
    let balanceSheetA = table::borrow(&balanceSheets.table, typeA);
    let queryResultA = QueryResult { typeName: typeA, balanceSheet: *balanceSheetA };
    
    let typeB = get<B>();
    let balanceSheetB = table::borrow(&balanceSheets.table, typeB);
    let queryResultB = QueryResult { typeName: typeB, balanceSheet: *balanceSheetB };
    
    vector::push_back(&mut res, queryResultA);
    vector::push_back(&mut res, queryResultB);
    res
  }
}
```

上面这个合约中query就是返回对`BalanceSheets`下table数据的一个查询结果。

`query`方法自定了一套查询逻辑，并将结果包装成`QueryResult`列表返回出来。下面看看如何调用这个方法获取查询数据。

```rust
import { JsonPrcProvider, bcs } from '@mysten/sui.js'
const provider = new JsonRpcProvider();

/******* 第一步: 需要构造解析返回结果的bcs解析器 *******/

// 解析类型根据 合约中定义的struct对于填写，例如下面的BalanceSheet
/****
  struct BalanceSheet has copy, store, drop {
    cash: u64,
    debt: u64
  }
*****/
bcs.registerStructType('BalanceSheet', {
  cash: 'u64',
  debt: 'u64',
})


bcs.registerStructType('TypeName', {
  name: 'string'
})

bcs.registerStructType('QueryResult', {
  typeName: 'TypeName',
  balanceSheet: 'BalanceSheet',
})

function des(data: Uint8Array) {
  return bcs.de('vector<QueryResult>', data)
}

/******* 第二步: 通过devInspectMoveCall模拟调用query方法 *******/

(async () => {
  const balanceSheetsId = '0x92a403ee9467f3753a28a8725a053eda6f64cca4';
  const testPkgId = '0xd7d27a9a68c11b9035be08428feceea9bf374510';
  const sender = '7738ccc64bd64bb7b3524296db285042f7876281'; // 地址可以任意使用
  const res = await provider.devInspectTransaction(sender, {
    kind: 'moveCall',
    data: {
      packageObjectId: testPkgId,
      module: 'test_query',
      function: 'query',
      typeArguments: [],
      arguments: [balanceSheetsId] 
    }
  })
  // 下面这段解析逻辑是精华，返回的数据结构很复杂，并且需要bcs反序列化
  if ('Ok' in res.results) {
    const returnValues = res.results.Ok[0][1].returnValues;
    if (returnValues) {
      const returnData = returnValues[0][0];
      const d = Uint8Array.from(returnData);
      let decoded = des(d) // 在这里用到了第一步的bcs解析器
      console.log(decoded)
    }
  }
})()
```
成功的话会打印出结果：

```bash
[
  {
    typeName: { name: 'd7d27a9a68c11b9035be08428feceea9bf374510::test_dev::A' },
    balanceSheet: { cash: 100n, debt: 20n }
  },
  {
    typeName: { name: 'd7d27a9a68c11b9035be08428feceea9bf374510::test_dev::B' },
    balanceSheet: { cash: 80n, debt: 10n }
  }
]
```

## 总结

- 对于大多数简单查询，直接通过address，Id进行对象数据查询即可。
- devInSpectMoveCall可以做到查询任意数据，实现复杂的组合查询。代价就是需要自己写链上查询函数，以及链下的bcs解析逻辑。
