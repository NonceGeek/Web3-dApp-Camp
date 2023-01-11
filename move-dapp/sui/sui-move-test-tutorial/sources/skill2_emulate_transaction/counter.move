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
}
