module MyAddr::MyLibraryV4 {
   // use StarcoinFramework::Signer;

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

   // TODO: A Library can CRUD the Books.

   // public fun create(account: &signer, the_id: u64, the_name: vector<u8>){
   //    Book{id: the_id, name: the_name};
   // }

   // public(script) fun create_book(account: signer, the_id: u64, the_name: vector<u8>){
   //    Self::create(&account, the_id, the_name)
   // }

}
