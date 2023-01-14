module my_pkg::debug_print {
  use std::debug;
  
  const EAddTestError: u64 = 0;
  
  public fun add(a: u64, b: u64): u64 {
    let res = a + b;
    debug::print(&res);
    res
  }
  
  fun test_add() {
    assert!(add(4, 5) == 9, EAddTestError);
  }
}
