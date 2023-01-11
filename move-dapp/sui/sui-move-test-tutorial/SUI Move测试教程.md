# SUI Move 合约测试

## 概述
本篇文章主要介绍Sui上测试的基本流程，以及通过一个简化版的借贷合，一步步完善对其的测试，分享我对Sui Move测试的经验。

## 面向的读者
教程假设读者已经有一定的Sui Move合约编程经验，但不需要对Sui Move测试有所了解。
教程会从最简单的Sui Move测试入门过渡到复杂案例。

### 为啥要做合约测试
开始之前先问一下为什么。为什么要对合约进行全方位严格的测试？
智能合约是通过程序来实现的，与其他软件一样，智能合约也有可能存在缺陷或者错误。
如果智能合约在运行过程中发生错误，可能会导致严重的后果，甚至导致资产损失。
例如以太坊发展早期的[The Dao事件](https://zhuanlan.zhihu.com/p/52098416),造成ETH的硬分叉。
这背后的原因就是当时合约的程序漏洞被黑客捕获，造成巨大的损失。
因此，在发布智能合约之前，通常都会进行测试，以确保智能合约的正确性和可靠性。

## 目录
- Sui Move测试基础
- Sui Move测试进阶1 -- 打印中间数据
- Sui Move测试进阶2 -- 模拟用户操作
- Sui Move测试进阶3 -- 测试逻辑与业务逻辑分离
- 总结与展望

## Sui Move测试基础
下面通过一个简单例子说明Sui Move测试流程：
**(注意：合约里的中文注释需要在编译时去掉，目前Sui Move不支持中文注释)**
```move
module my_pkg::add {
  #[test_only] // 标注只在测试用到的数据
  const EAddTestError: u64 = 0;
  
  public fun add(a: u64, b: u64): u64 {
    a + b
  }
  
  #[test] // 必须打上test标签，才能被正确识别为测试用例
  fun test_add() {
    assert!(add(4, 5) == 9, EAddTestError);
  }
}
```
测试命令：
`sui move test --path <pkg_path>`
命令执行无报错则说明测试用例通过。

基本流程主要是3步：
1, 编写测试方法 (需打上test标签)
2, 对被测试的方法进行调用和评估结果是否符合预期
3, 运行测试命令

## Sui Move测试进阶1 -- 打印中间数据
在编程时，有时会遇到一下无法定位的bug。对上面的例子做一下修改。
```move
module my_pkg::add {
  ...
  use std::debug; // 引入debug模块
  
  public fun add(a: u64, b: u64): u64 {
    let res = a + b;
    debug::print(&res); // 打印计算结果
    res
  }
  ...
}
```
再次执行测试命令，会在terminal 打印出:
`[debug] 9 `

## Sui Move测试进阶2 -- 模拟用户操作
实际测试中，不光需要测试pure function，更多的是需要对用户的操作进行测试。
官方推出了一个对合约进行测试的基础模块-- Test Scenario。[官方Test Scenario教程英文版](https://docs.sui.io/devnet/build/move/build-test)
Test Senario模拟用户交易示例：
```move
module my_pkg::counter {
  use sui::object::{Self, UID};
  use sui::tx_context::TxContext;
  use sui::transfer;
  #[test_only]
  use sui::test_scenario; // 引入测试模块，用于模拟用户交易
  #[test_only]
  const EAddIncrementError: u64 = 0;
  
  struct Counter has key {
    id: UID,
    value: u64,
  }
  
  // 初始化一个value为0的共享counter
  fun init(ctx: &mut TxContext) {
    transfer::share_object( Counter { id: object::new(ctx), value: 0 } )
  }
  
  // 这里重复写一次专用的测试init，是因为目前Sui还不支持在测试里调用init方法，是一个workaround
  #[test_only]
  public fun init_test(ctx: &mut TxContext) {
    transfer::share_object( Counter { id: object::new(ctx), value: 0 } )
  }
  
  // 给counter的value 加1
  public entry fun increment(counter: &mut Counter) {
    counter.value = counter.value + 1;
  }
  
  public fun value(counter: &Counter): u64 {
    counter.value
  }
  
  #[test]
  fun test_increment() {
    let user = @0x0; // 可以是任意地址
    let senario_val = test_scenario::begin(user);
    let senario = &mut senario_val; // 这个senario会串联起后续所有测试
    init_test(test_scenario::ctx(senario)); // 模拟 模块初始化
    test_scenario::next_tx(senario, user); // 发起新的交易模拟，并结束上一笔交易模拟
    /*** 必须调用完next_tx才能拿到counter ***/
    let counter = test_scenario::take_shared<Counter>(senario); // 拿到初始化产生的counter对象
    assert!(counter.value == 0, 0); // 确保counter初始值为0
    increment(&mut counter); // 调用被测试方法
    assert!(counter.value == 1, 0); // 执行方法后，counter value加1
  }
}
```
到这里测试用例逻辑已经覆盖，执行测试命令，会报错:
```bash
The local variable 'counter' still contains a value.
The value does not have the 'drop' ability and must be consumed before the function returns
```
这个错误和Move语言机制有关：之前拿出来的counter在函数结束时没有被正确处理。
在测试结尾加上：
```move
#[test]
...
  fun test_increment() {
    ...
    test_scenario::return_shared(counter);
    test_scenario::end(senario_val);
  }
...
```
再次运行测试命令，可以顺利通过测试。

## Sui Move测试进阶3 -- 测试逻辑与业务逻辑分离
前面的例子将测试用例和业务逻辑写在一个文件，对于简单应用够用。但是业务逻辑复杂的情况下，一个文件代码太多，会增加代码的阅读难度。
下面的例子把counter的测试单独抽离成一个 counter_test模块，专注于测试逻辑。

改写过后的counter模块, 去掉了测试逻辑。
```move
module my_pkg::counter {
  use sui::object::{Self, UID};
  use sui::tx_context::TxContext;
  use sui::transfer;
  
  struct Counter has key {
    id: UID,
    value: u64,
  }
  
  fun init(ctx: &mut TxContext) {
    transfer::share_object( Counter { id: object::new(ctx), value: 0 } )
  }
  
  #[test_only]
  public fun init_test(ctx: &mut TxContext) {
    transfer::share_object( Counter { id: object::new(ctx), value: 0 } )
  }
  
  public entry fun increment(counter: &mut Counter) {
    counter.value = counter.value + 1;
  }
  
  public fun value(counter: &Counter): u64 {
    counter.value
  }
}
```

新的counter_test 模块
```move
#[test_only]
module my_pkg::counter_test {
  use sui::test_scenario;
  use my_pkg::counter::{Self, Counter};
  const EAddIncrementError: u64 = 0;
  
  #[test]
  fun test_increment() {
    let user = @0x0;
    let senario_val = test_scenario::begin(user);
    let senario = &mut senario_val;
    counter::init_test(test_scenario::ctx(senario));
    test_scenario::next_tx(senario, user);
    let counter = test_scenario::take_shared<Counter>(senario);
    assert!(counter::value(&counter) == 0, EAddIncrementError);
    counter::increment(&mut counter);
    assert!(counter::value(&counter) == 1, EAddIncrementError);
    
    test_scenario::return_shared(counter);
    test_scenario::end(senario_val);
  }
}
```
这种分离式写法适合大规模的应用测试，保持模块的可读性。区别只是，因为属于不同模块所以方法调用上需要通过模块间的方式，而不是内部调用。

## 总结和展望
教程分析基础的测试流程和常用的测试进阶知识，可以应付中小规模的Sui Move合约开发。
根据我们的开发经验，后续随着应用的复杂度提升，测试工作也会变得艰巨。因而需要提高对测试逻辑的复用：
- 例如通用测试逻辑的封装，例如参考web2测试，进行一些测试框架。
- 业务级别测试逻辑的复用，很多测试场景的setup，和destry可以复用。

后续我会根据我实际项目的经验，分享我是如何对复杂应用进行测试。