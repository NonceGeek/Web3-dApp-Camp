module my_addr::nft_attr {
   use aptos_framework::signer;
   use std::vector;
   use std::string::{String};

   struct Attrs has key {
      max_id: u64,
      attrs: Table<u64, Attr>
   }
   struct Attr has store, copy, key {
      id: u64,
      description: String,
      level: u64,
      additional: String
   }

   public entry fun init_attrs(){
      let attrs = Attrs {
      max_id: 0,
      attrs: table::new(),
      }
      move_to<Attrs>(acct, attrs);
   }

   // TODO: only admin in Move.toml can set variables.
   public entry fun create_attr(
      acct: &signer,
      id: u64,
      description: String,
      level: u64,
      additional: String
      ){
      
      let attr =  Attr{
         id: id,
         description: description,
         level: value,
         additional: additional
      };

      // update the global table attrs.
      let attrs = borrow_global_mut<Attrs>(signer::address_of(acct));
      table::add(&mut addr_aggr.addr_infos_map, addr, addr_info);
      vector::push_back(&mut addr_aggr.addrs, addr);
      addr_aggr.max_id = addr_aggr.max_id + 1;

      // move attr to acct.
      move_to<Attr>(acct, attr);
   }

   // TODO: only admin in Move.toml can set variables.
   public entry fun update_attr(
      acct: &signer,
      id: u64,
      description: String,
      level: u64,
      additional: String
      ){
         // TODO
   }
}
