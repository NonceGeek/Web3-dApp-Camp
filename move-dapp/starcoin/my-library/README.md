# Resource 的限制
在代码中，Resource 类型有几个主要限制：
- Resource 存储在帐户下。因此，只有在分配帐户后才会存在，并且只能通过该帐户访问。
- 一个帐户同一时刻只能容纳一个某类型的 Resource。
- Resource 不能被复制；与它对应的是一种特殊的kind：resource，它与copyable不同，这一点在泛型章节中已经介绍。
- Resource 必需被使用，这意味着必须将新创建的 Resource move到某个帐户下，从帐户移出的Resource 必须被解构或存储在另一个帐户下。

> 下文所有的代码的console调用都参见[scripts.sh](../my-counter/sources/scripts.sh)

# 创建
Library资源创建后必须move到账户的存储下，否则后面无法访问。
```
   public fun create_library(account: &signer){
      move_to<Library>(account, Library{books: Vector::empty<Book>()});
   }
```
后面所有的`script`代码均略去。

# 增加
```
   public fun addBook(account: &signer,name:vector<u8>, link: vector<u8>) acquires  Library {
      let lib = borrow_global_mut<Library>(Signer::address_of(account));
      let id = Vector::length(&lib.books);
      Vector::push_back(&mut lib.books, Book{id:id,name:name,link:link});
   }
```
对资源修改首先需要通过`borrow_global_mut<Library>`获取对资源的可变引用，然后通过内建库`Vector`操作可变的books:`&mut lib.books`将新创建的Struct添加进去。需要注意的是函数中操作的所有资源需要再函数签名最后用`acquires  Library`表示。
相关知识点参见对资源的[读取和修改](https://move-book.com/cn/resources/resource-by-example/access-resource-with-borrow.html)和[Vector API](https://github.com/diem/diem/blob/latest/language/move-stdlib/docs/Vector.md):
- Function empty
- Function length
- Function borrow
- Function push_back
- Function borrow_mut
- Function pop_back
- Function destroy_empty
- Function swap
- Function singleton
- Function reverse
- Function append
- Function is_empty
- Function contains
- Function index_of
- Function remove
- Function swap_remove

# 删除
与增加类似
```
   public fun deleteBookAtId(account: &signer,id:u64) acquires  Library {
      let lib = borrow_global_mut<Library>(Signer::address_of(account));
      Vector::remove(&mut lib.books, id);
   }
```

# 更新
这一步与增加的操作类似，只是需要通过`Vector::borrow_mut`获取到单个book的可变引用。
```
   public fun updateBookAtId(account: &signer,id:u64,name:vector<u8>, link: vector<u8>) acquires  Library {
      let lib = borrow_global_mut<Library>(Signer::address_of(account));
      let book = Vector::borrow_mut<Book>(&mut lib.books,id);
      book.name = name;
      book.link = link;
   }
```

# 查询
由于Starcoin中script不能有返回值，因此只能通过getresource来读取。
参见[scripts.sh](../my-counter/sources/scripts.sh)

