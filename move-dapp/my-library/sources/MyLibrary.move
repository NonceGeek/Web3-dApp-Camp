module MyAddr::MyLibraryV5 {
   use StarcoinFramework::Signer;
   use StarcoinFramework::Vector;
   // each ability has matching keyword
   // multiple abilities are listed with comma
   struct Book has store, copy, drop {
      id: u64,
      name: vector<u8>,
      link: vector<u8>
   }

   // single ability is also possible
   struct Library has key {
      books: vector<Book>
   }

   public fun create_library(account: &signer){
      move_to<Library>(account, Library{books: Vector::empty<Book>()});
   }
   //because the script function cannot have return value,
   //query only can be done by: state get resource Addr Addr::MyLibraryV4::Library
   public fun addBook(account: &signer,name:vector<u8>, link: vector<u8>) acquires  Library {
      let lib = borrow_global_mut<Library>(Signer::address_of(account));
      let id = Vector::length(&lib.books);
      Vector::push_back(&mut lib.books, Book{id:id,name:name,link:link});
   }

   public fun updateBookAtId(account: &signer,id:u64,name:vector<u8>, link: vector<u8>) acquires  Library {
      let lib = borrow_global_mut<Library>(Signer::address_of(account));
      let book = Vector::borrow_mut<Book>(&mut lib.books,id);
      book.name = name;
      book.link = link;
   }

   public fun deleteBookAtId(account: &signer,id:u64) acquires  Library {
      let lib = borrow_global_mut<Library>(Signer::address_of(account));
      Vector::remove(&mut lib.books, id);
   }

   public(script) fun init_library(account: signer){
      Self::create_library(&account)
   }

   public(script) fun s_add_book(account: signer, name:vector<u8>, link: vector<u8>) acquires  Library {
      Self::addBook(&account,name, link)
   }

   public(script) fun s_update_book_at_id(account: signer, id:u64,name:vector<u8>, link: vector<u8>) acquires  Library {
      Self::updateBookAtId(&account,id,name,link)
   }

   public(script) fun s_delete_book_at_id(account: signer, id:u64) acquires  Library {
      Self::deleteBookAtId(&account,id)
   }
}
