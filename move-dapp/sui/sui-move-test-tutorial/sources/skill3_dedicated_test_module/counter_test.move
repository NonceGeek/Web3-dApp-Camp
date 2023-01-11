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
