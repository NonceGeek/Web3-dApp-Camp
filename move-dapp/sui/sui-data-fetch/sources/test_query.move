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
