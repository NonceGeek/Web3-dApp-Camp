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
