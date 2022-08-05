module MyAddr::AddrAggregator {
   use StarcoinFramework::Vector;
   use StarcoinFramework::Signer;
   use StarcoinFramework::Option;

   struct AddrInfo has store, copy, drop {
      addr: address,
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
   public fun add_addr(acct: &signer, addr: address, chain_name: vector<u8>, signature: Option<vector<u8>>) acquires AddrAggregator{
      if (Option::is_some(&signature)) {
         do_add_addr(acct, addr, chain_name, Option::destroy_some<vector<u8>>(signature));
      } else {
         do_add_addr(acct, addr, chain_name, Vector::empty());
      }
   }

   public fun do_add_addr(acct: &signer, addr: address, chain_name: vector<u8>, signature: vector<u8>) acquires AddrAggregator{
      let addr_aggr = borrow_global_mut<AddrAggregator>(Signer::address_of(acct));
      let addr_info = AddrInfo{
         addr: addr, 
         chain_name: chain_name,
         signature: signature
      };
      Vector::push_back(&mut addr_aggr.addr_infos, addr_info);
   }

   // //because the script function cannot have return value,
   // //query only can be done by: state get resource Addr Addr::MyLibraryV4::Library
   // public fun addBook(account: &signer,name:vector<u8>, link: vector<u8>) acquires  Library {
   //    let lib = borrow_global_mut<Library>(Signer::address_of(account));
   //    let id = Vector::length(&lib.books);
   //    Vector::push_back(&mut lib.books, Book{id:id,name:name,link:link});
   // }

   // public fun updateBookAtId(account: &signer,id:u64,name:vector<u8>, link: vector<u8>) acquires  Library {
   //    let lib = borrow_global_mut<Library>(Signer::address_of(account));
   //    let book = Vector::borrow_mut<Book>(&mut lib.books,id);
   //    book.name = name;
   //    book.link = link;
   // }

   // public fun deleteBookAtId(account: &signer,id:u64) acquires  Library {
   //    let lib = borrow_global_mut<Library>(Signer::address_of(account));
   //    Vector::remove(&mut lib.books, id);
   // }

   // public(script) fun init_library(account: signer){
   //    Self::create_library(&account)
   // }

   // public(script) fun s_add_book(account: signer, name:vector<u8>, link: vector<u8>) acquires  Library {
   //    Self::addBook(&account,name, link)
   // }

   // public(script) fun s_update_book_at_id(account: signer, id:u64,name:vector<u8>, link: vector<u8>) acquires  Library {
   //    Self::updateBookAtId(&account,id,name,link)
   // }

   // public(script) fun s_delete_book_at_id(account: signer, id:u64) acquires  Library {
   //    Self::deleteBookAtId(&account,id)
   // }
}
