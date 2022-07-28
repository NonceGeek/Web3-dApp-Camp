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
```

starcoin 控制台命令：

```bash
# 指定账户获得测试代币
starcoin% dev get-coin 0xb7c46353c6c0e3a2559d5b12cad981e4 -v 100STC
# 账户列表
starcoin% account list
# 单一账户情况查看
starcoin% account show 0xb7c46353c6c0e3a2559d5b12cad981e4
# 创建新账户
starcoin% account create -p [pwd]
```

### 1.3 Contract Framework

最小可实践例子：

> https://github.com/starcoinorg/starcoin-cookbook/blob/main/examples/my-counter

```rust
module MyCounterAddr::MyCounter {
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

MyCounter 源码分析

module 是发布在特定地址下的打包在一起的一组函数和结构体。使用script时需要与已发布的module或标准库一起运行，而标准库本身就是在 0x1 地址下发布的一组module。

module MyCounterAddr::MyCounter{ } 则在该MyCounterAddr地址下(对应Move.toml下的MyCounterAddr = "0xb7c46353c6c0e3a2559d5b12cad981e4")创建一个module。

use StarcoinFramework::Signer，是使用标准库下的Signer module，Signer 是一种原生的类似 Resource 的不可复制的类型，它包含了交易发送者的地址。引入signer类型的原因之一是要明确显示哪些函数需要发送者权限，哪些不需要。因此，函数不能欺骗用户未经授权访问其 Resource。具体可参考[源码](https://github.com/starcoinorg/starcoin-framework/blob/main/sources/Signer.move)。
```rust
struct Counter has key, store {
        value:u64,
     }
```
使用struct定义了一个叫做Counter的结构体，同时被 key,store两种限制符修饰，Move的类型系统灵活，每种类型都可以被四种限制符所修饰。这四种限制符我们称之为 abilities，它们定义了类型的值是否可以被复制、丢弃和存储。
这四种 abilities 限制符分别是: Copy, Drop, Store 和 Key.

它们的功能分别是： 
- Copy - 被修饰的值可以被复制。 
- Drop - 被修饰的值在作用域结束时可以被丢弃。 
- Key - 被修饰的值可以作为键值对全局状态进行访问。 
- Store - 被修饰的值可以被存储到全局状态。

这里用key,store修饰，则表示它不能被复制，也不能被丢弃或重新使用，但是它却可以被安全地存储和转移。

下面则是定义的方法，
```rust
public fun init(account: &signer){
    move_to(account, Counter{value:0});
}
public fun incr(account: &signer) acquires Counter {
    let counter = borrow_global_mut<Counter>(Signer::address_of(account));
    counter.value = counter.value + 1;
}
```

定义格式则是:

public fun 函数名(参数：参数类型){ }

move函数默认是私有函数，只能在定义它们的模块中访问。关键字 public 将更改函数的默认可见性并使其公开，即可以从外部访问。

init方法参数是一个&signer，意味着该方法必须是一个账户合法签名过后才可以调用，move_to则是move的一个原语，作用是发布、添加Counter资源到 signer 的地址下。Move的账户模型，code和data是存储在一个账户地址下的。

下面是列举的常用原语

- move_to< T >(&signer, T)：发布、添加类型为 T 的资源到 signer 的地址下。
- move_from< T >(addr: address): T - 从地址下删除类型为 T 的资源并返回这个资源。
- borrow_global< T >(addr: address): &T - 返回地址下类型为 T 的资源的不可变引用。
- borrow_global_mut< T >(addr: address): &mut T - 返回地址下类型为 T 的资源的可变引用。
- exists< T >(address): bool：判断地址下是否有类型为 T 的资源。。

incr方法参数也是一个&signer，意味着该方法必须是一个账户合法签名过后才可以调用,

关键字 acquires，放在函数返回值之后，用来显式定义此函数获取的所有 Resource。

Signer::address_of(account) 从签名者中拿到address

borrow_global_mut上面有介绍到，可变借用到address下到resource Counter，然后将Counter结构体下的value进行+1操作。

这下面的两个方法则是script方法,它与上面两个函数有什么区别呢？

- public fun : 方法可以在任何模块中被调用。
- public(script) fun：script function 是模块中的入口方法，表示该方法可以通过控制台发起一个交易来调用，就像本地执行脚本一样

下个版本的 Move 会用 public entry fun 替代 public(script) fun

Self则是代表自身module。
```rust
  public(script) fun init_counter(account: signer){
        Self::init(&account)
     }

     public(script) fun incr_counter(account: signer)  acquires Counter {
        Self::incr(&account)
     }
```

#### 1.3.1 编译

下载第一个实例的源码：

```bash
$git clone git@github.com:WeLightProject/Web3-dApp-Camp.git
$cd Web3-dApp-Camp/move-dapp/my-counter
```

修改`move.toml`中的地址为你用来部署的地址。

![image-20220727123922351](https://tva1.sinaimg.cn/large/e6c9d24egy1h4ldrxbqt8j217o0h8gom.jpg)

// TODO：此处加上个知识点

编译：

```bash
$mpm release
```

接下来会在`release`文件夹中，看到你编译好的二进制文件。

![image-20220727124134402](https://tva1.sinaimg.cn/large/e6c9d24egy1h4lducyft6j20es066jri.jpg)

#### 1.3.2 部署

在 Starcoin Console 中执行如下命令即可部署：

```bash
starcoin% dev deploy [path to blob] -s [addr] -b
```

如果遇到账户被锁，用 `unlock`命令解锁即可。

```bash
account unlock [addr] -p [pwd]
```

其中`pwd`即是在`1.2`中创建的密码。 

部署成功后能看到：

![image-20220727124625807](https://tva1.sinaimg.cn/large/e6c9d24egy1h4ldz8jd7lj213s0lmju5.jpg)

#### 1.3.3 调用

// TODO

### 1.4 Your First Move dApp / Starcoin dApp



### 1.5 Variables 

// TODO

### 1.6 Basic Operations

// TODO

### 1.7 Functions

// TODO

### 1.8 Sructs

// TODO

### 1.9 Impl - DNA Generator

// TODO

### 1.10 Buidl A XiuXian Role

// TODO





