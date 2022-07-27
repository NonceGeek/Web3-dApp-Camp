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





