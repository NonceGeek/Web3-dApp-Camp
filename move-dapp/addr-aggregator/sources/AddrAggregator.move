module MyAddr::AddrAggregator {
   use StarcoinFramework::Vector;
   use StarcoinFramework::Signer;
   use StarcoinFramework::Timestamp;
   use StarcoinFramework::Signature;
   use StarcoinFramework::BCS;
   use StarcoinFramework::Option::{Self, Option};
   #[test_only]
   use StarcoinFramework::Debug;

   struct AddrInfo has store, copy, drop {
      addr: address,
      description: vector<u8>,
      chain_name: vector<u8>,
      signature: vector<u8>,
      id : u64
   }

   struct AddrAggregator has key {
      key_addr: address,
      addr_infos: vector<AddrInfo>,
      max_id : u64
   }

   public fun create_addr_aggregator(acct: &signer){
      let addr_aggr =  AddrAggregator{
         key_addr: Signer::address_of(acct),
         addr_infos: Vector::empty<AddrInfo>(),
         max_id : 0
      };
      move_to<AddrAggregator>(acct, addr_aggr);
   }

   //split string by char 
   public fun split_char(v: &vector<u8>, ch: u8) :  vector<vector<u8>> {
      let result = Vector::empty<vector<u8>>();

      // let len = Vector::length(&string.bytes); 
      let len = Vector::length(v);
      let i = 0; 
      // let flag = false;
      let buffer = Vector::empty<u8>();
      while ( i < len ) {
         let byte = *Vector::borrow(v, i);
         if (byte != ch) {
            Vector::push_back(&mut buffer, byte);
         } else {
            Vector::push_back(&mut result, buffer);
            buffer = Vector::empty<u8>();
         };
         
         i = i+1; 
      };
      if (Vector::length(&buffer) != 0) {
         Vector::push_back(&mut result, buffer);
      }; 

      result
   }

   // vector<u8> transfter to timestamp 
   public fun transfer_timestamp(timestamp_vec: vector<u8>): u64{
         let prev_time  = 0;
         let prev_time_length = Vector::length(&timestamp_vec);
         if (prev_time_length != 10) {
            abort 1002
         };
         let i=0;
         while (i < prev_time_length) {
            let char = Vector::borrow(&mut timestamp_vec, i);
            if (*char >= 48 && *char <= 57) {
               prev_time = prev_time*10 + ((*char - 48) as u64);
            };
            i = i+1;
         };
         prev_time
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
         let msg_bytes = Option::borrow(&msg);
         let signature_bytes = Option::borrow(&signature);
         let split_vec = split_char(msg_bytes, 0x5f);

         // verify the format of msg is valid
         if (Vector::length(&mut split_vec) != 3) {
            abort 1001
         };

         // verify the signature for the msg addr_chain_name_timestamp
         let addr_bytes =BCS::to_bytes<address>(&addr);
         if (!Signature::secp256k1_verify(*signature_bytes, addr_bytes, *msg_bytes)) {
            abort 1002
         };

         let timestamp_vec = Vector::borrow(&split_vec, 2);
         let prev_time = transfer_timestamp(*timestamp_vec);
         let now_time = Timestamp::now_seconds();
         let elapsed_time = now_time - prev_time;

         // verify the timestamp - timestamp_now >= 2h is true
         if (elapsed_time < 2*60*60) {
            abort 1003
         };

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
      let id = addr_aggr.max_id + 1;

      let addr_info = AddrInfo{
         addr: addr, 
         chain_name: chain_name,
         description: description,
         signature: signature,
         id : id,
      };
      Vector::push_back(&mut addr_aggr.addr_infos, addr_info);
      addr_aggr.max_id = addr_aggr.max_id + 1;
   }

   // public fun update addr with sig
   public fun  update_addr_with_sig(
      acct: &signer,  
      addr: address,
      signature: vector<u8>) acquires AddrAggregator{
      let addr_aggr = borrow_global_mut<AddrAggregator>(Signer::address_of(acct));
      let length = Vector::length(&mut addr_aggr.addr_infos);
      let i = 0;
      while (i < length) {
         let addr_info = Vector::borrow_mut<AddrInfo>(&mut addr_aggr.addr_infos, i);
         if (addr_info.addr == addr) {
            addr_info.signature = signature;
            break
         }
      };
   }

   // public fun update addr with description and sig
   public fun update_addr_with_description_and_sig(
      acct: &signer,  
      addr: address,
      signature: vector<u8>,
      description: vector<u8>) acquires AddrAggregator{
      let addr_aggr = borrow_global_mut<AddrAggregator>(Signer::address_of(acct));
      let length = Vector::length(&mut addr_aggr.addr_infos);
      let i = 0;
      while (i < length) {
         let addr_info = Vector::borrow_mut<AddrInfo>(&mut addr_aggr.addr_infos, i);
         if (addr_info.addr == addr) {
            addr_info.signature = signature;
            addr_info.description = description;
            break
         }
      };
   }

   // public fun delete addr
   public fun delete_addr(
      acct: &signer,  
      addr: address) acquires AddrAggregator{
      let addr_aggr = borrow_global_mut<AddrAggregator>(Signer::address_of(acct));
      let length = Vector::length(&mut addr_aggr.addr_infos);
      let i = 0;
      while (i < length) {
         let addr_info = Vector::borrow(&mut addr_aggr.addr_infos, i);
         if (addr_info.addr == addr) {
            Vector::remove(&mut addr_aggr.addr_infos, i);
         }
      }
   }
   

   #[test]
   public fun split_char_test(){
      let origin = b"a_b_c";
      Debug::print(&origin);
      let result = split_char(&mut origin, 0x5f); // _ ansci is 0x5f
      Debug::print(&result);
      assert!(Vector::length(&mut result) == 3, 101);

      let origin = b"a_b_";
      Debug::print(&origin);
      let result = split_char(&mut origin, 0x5f); // _ ansci is 0x5f
      Debug::print(&result);
      assert!(Vector::length(&mut result) == 2, 101);

      let origin = b"a";
      Debug::print(&origin);
      let result = split_char(&mut origin, 0x5f); // _ ansci is 0x5f
      Debug::print(&result);
      assert!(Vector::length(&mut result) == 1, 101);
   }

   #[test]
   public fun transfer_timestamp_test() {
      let ts_str = b"1661049255";
      // let length = Vector::length(&ts_str);
      Debug::print(&ts_str);
      
      let expected_ts = 1661049255;
      let real_ts = transfer_timestamp(ts_str);
      Debug::print(&real_ts);
      assert!( real_ts==expected_ts,  110);
   }
}