## Module A. Making the Role

### 1.1 OverView

// TODO

### 1.2 Setup a node

下载最新的发行版 Starcoin 节点程序（MacOS 将其拷贝至`/usr/local/bin`目录即可）：

> https://github.com/starcoinorg/starcoin/releases

在此以`Starcoin`网络为基础，展现如何启动一个节点：

>  https://starcoinorg.github.io/starcoin-cookbook/docs/getting-started/setup/

太长不看版——关键命令合集：

```bash
# 启动一个本地 dev 节点
$starcoin -n dev
# 启动控制台
$starcoin -n dev console
# 指定账户获得测试代币
$ dev get-coin 0xb7c46353c6c0e3a2559d5b12cad981e4 -v 100STC
# 账户列表
$ account list
# 单一账户情况查看
$ account show 0xb7c46353c6c0e3a2559d5b12cad981e4
```

### 1.3 Contract Framework

最小可实践例子：

> https://github.com/starcoinorg/starcoin-cookbook/blob/main/examples/my-counter

```rust
module MyCounter::MyCounter {
     use StarcoinFramework::Signer;

     struct Counter has key, store {
        value:u64,
     }
     public fun init(account: &signer){
        move_to(account, Counter{value:0});
     }
     public fun incr(account: &signer) acquires Counter {
        let counter = borrow_global_mut<Counter>(Signer::address_of(account));
        counter.value = counter.value + 1;
     }

     public(script) fun init_counter(account: signer){
        Self::init(&account)
     }

     public(script) fun incr_counter(account: signer)  acquires Counter {
        Self::incr(&account)
     }
}
```

// TODO 源码分析

### 1.4 Variables 

// TODO

### 1.5 Basic Operations

// TODO

### 1.6 Functions

// TODO

### 1.7 Sructs

// TODO

### 1.8 Impl - DNA Generator

// TODO

### 1.9 Buidl A XiuXian Role

// TODO





