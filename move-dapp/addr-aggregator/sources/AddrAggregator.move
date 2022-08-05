module MyAddr::AddrAggregator {
   use StarcoinFramework::Vector;
   use StarcoinFramework::Signer;
   use StarcoinFramework::Option::{Self, Option};

   struct AddrInfo has store, copy, drop {
      addr: address,
      description: vector<u8>,
      chain_name: vector<u8>,
      signature: vector<u8>
   }

   struct AddrAggregator has key {
      key_addr: address,
      addr_infos: vector<AddrInfo>
   }

   public fun create_addr_aggregator(acct: &signer){
      let addr_aggr =  AddrAggregator{
         key_addr: Signer::address_of(acct),
         addr_infos: Vector::empty<AddrInfo>()
      };
      move_to<AddrAggregator>(acct, addr_aggr);
   }

   /// add addr without signature is permitted, and the owner can add signature later.
   public fun add_addr(
      acct: &signer, 
      addr: address, 
      chain_name: vector<u8>, 
      description: vector<u8>,
      msg: Option<vector<u8>>,
      signature: Option<vector<u8>>) acquires AddrAggregator{
      if (Option::is_some<vector<u8>>(&signature) && Option::is_some<vector<u8>>(&msg)) {
         // TODO:
         // verify the format of msg is valid
         // verify the signature for the msg addr_chain_name_timestamp
         // verify the timestamp - timestamp_now >= 2h is true
         // then add addr
         do_add_addr(acct, addr, chain_name, description, Option::destroy_some<vector<u8>>(signature));
      } else {
         do_add_addr(acct, addr, chain_name, description, Vector::empty());
      }
   }

   public fun do_add_addr(
      acct: &signer, 
      addr: address, 
      chain_name: vector<u8>, 
      description: vector<u8>,
      signature: vector<u8>) acquires AddrAggregator{
      let addr_aggr = borrow_global_mut<AddrAggregator>(Signer::address_of(acct));
      let addr_info = AddrInfo{
         addr: addr, 
         chain_name: chain_name,
         description, description,
         signature: signature
      };
      Vector::push_back(&mut addr_aggr.addr_infos, addr_info);
   }
   // TODO:
   // public fun update addr with sig
   // public fun update addr with description and sig
   // public fun delete addr
   
}
