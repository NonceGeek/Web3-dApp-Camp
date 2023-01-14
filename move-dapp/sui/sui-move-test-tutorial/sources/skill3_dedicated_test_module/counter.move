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
