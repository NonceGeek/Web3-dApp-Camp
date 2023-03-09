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
