## 0x01 最小必要知识

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
$ starcoin -n dev
# 启动一个本地 dev 节点的同时打开控制台，-d 参数可以确保每次打开控制台时都保有历史的数据而不是重开
$ mkdir [folder_name]
$ cd [folder_name]
$ pwd
$ starcoin -d [path_to_your_data_folder] -n dev console
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
$ git clone git@github.com:WeLightProject/Web3-dApp-Camp.git
$ cd Web3-dApp-Camp/move-dapp/my-counter
```

Move的包管理工具为Move Package Manager(mpm),它类似于Rust的Cargo或者Node的NPM。
可以通过`mpm package new my-counter`来创建一个新项目，典型的目录结构为:
```
my-counter
├── Move.toml
└── sources
    └── MyCounter.move 
```
- sources用来存档Move的模块,它类似于与Java中的类文件。
- Move.toml-用来存放配置文件：包括包的原数据、依赖和命名地址。
- 上述文件构成一个Move包(Move Package)
更详细的Move包管理参考[文档](https://starcoinorg.github.io/starcoin-cookbook/zh/docs/move/move-language/packages/)

修改`move.toml`中的地址为你用来部署的地址。

![image-20220727123922351](https://tva1.sinaimg.cn/large/e6c9d24egy1h4ldrxbqt8j217o0h8gom.jpg)



编译：

```bash
$ mpm release
```

接下来会在`release`文件夹中，看到你编译好的二进制文件。

![image-20220727124134402](https://tva1.sinaimg.cn/large/e6c9d24egy1h4lducyft6j20es066jri.jpg)


#### 1.3.2 控制台部署

在 Starcoin Console 中执行如下命令即可部署：

```bash
starcoin% dev deploy [path to blob] -s [addr] -b
```
> -s 即--sender,-b即--blocking，表示阻塞等待命令执行完成

如果遇到账户被锁，用 `unlock`命令解锁即可。

```bash
account unlock [addr] -p [pwd]
```

其中`pwd`即是在`1.2`中创建的密码。 

部署成功后能看到：

![image-20220727124625807](https://tva1.sinaimg.cn/large/e6c9d24egy1h4ldz8jd7lj213s0lmju5.jpg)

> 💡需要注意的是，在Move中代码存储在个人的地址上，而非像以太坊那样的公共地址上。因此合约部署后并不会创建新地址，当我们想要调用合约时需要采用部署合约人的地址+合约名来调用改合约。

#### 1.3.3 控制台调用

> https://starcoinorg.github.io/starcoin-cookbook/docs/move/interacting-with-the-contract

1. 调用 init_counter 脚本函数来初始化资源。

```
starcoin% account execute-function --function {MyCounterAddr-in-Move.toml}::MyCounter::init_counter -s 0x23dc2c167fcd16e28917765848e189ce -b
```
其中:
- `{MyCounterAddr-in-Move.toml}::MyCounter::init_counter`为完整的函数链上地址，包括合约所在地址+包名+函数名。
- -s 即--sender,-b即--blocking，表示阻塞等待命令执行完成

2. 查看Counter资源
```
starcoin% state get resource 0x23dc2c167fcd16e28917765848e189ce 0x23dc2c167fcd16e28917765848e189ce::MyCounter::Counter
```
在Move中合约的数据被称为`资源(resource)`，由于读取数据不改变链上状态，因此不需要-s -b，不会执行交易，也不消耗状态。

> 感兴趣的同学可以试着调用`incr_counter`，并再次查看`Counter`是否+1。


### 1.4 Your First Move dApp / Starcoin dApp

下载`starcoin-test-dapp-react`：

```bash
$ git clone git@github.com:starcoinorg/starcoin-test-dapp-react.git
```

#### 1.4.1 极速启动

```bash
$ yarn
$ yarn start
```

![image-20220729090935566](https://tva1.sinaimg.cn/large/e6c9d24egy1h4niy9kgp7j20zu0u010b.jpg)

#### 1.4.2 配置 Starmask

Starmask 是和 Metamask 一样的浏览器插件。

因此，我们可以使用相同的方式去配置：

- **确保节点 RPC 端口能访问**

```bash
$ lsof -i:9851
```

![image-20220729092714792](https://tva1.sinaimg.cn/large/e6c9d24egy1h4njgltcaej20x809iwh4.jpg)

* **添加端口为`9851` 的本地网络**

![image-20220729092609290](https://tva1.sinaimg.cn/large/e6c9d24egy1h4njfftt3lj20a80hojrt.jpg)

- **在 Starmask 中导入测试账户**

控制台中的导出私钥命令：

```bash
starcoin% account export 0x23dc2c167fcd16e28917765848e189ce
```

然后通过导入账户功能导入：

![image-20220729092931382](https://tva1.sinaimg.cn/large/e6c9d24egy1h4njiyc3yfj20a90h3dg8.jpg)

- **余额显示**

此时 Starmask、Starcoin Console 与 RPC 接口所查询到同一账户的 STC 余额应该一致。

其中 Starcoin RPC 的 Postman Collection 链接如下：

> https://www.postman.com/starcoinorg/workspace/starcoin-blockchain-api/request/13565741-fa891c12-6684-452a-86cb-6d938fc72f4e

![image-20220729093042286](https://tva1.sinaimg.cn/large/e6c9d24egy1h4njk6sd7jj20a70hlq3g.jpg)

![image-20220729093116486](https://tva1.sinaimg.cn/large/e6c9d24egy1h4njmxuj7yj21400iygo1.jpg)

![image-20220729093132604](https://tva1.sinaimg.cn/large/e6c9d24egy1h4njn0wdfyj21gc0skdjy.jpg)

#### 1.4.3 函数调用

调整 demo 中的合约。首先我们定位到相关代码处：

```bash
src/app.jsx
```

找到标签` {/* Contracts Function */}`：

```react
{/* Contracts Function */}
                <div className="mt-4 shadow-2xl rounded-2xl border-2 border-slate-50 p-2">
                  <div className="font-bold">Contract Function</div>
                  <div
                    className="mt-4 rounded-2xl bg-blue-900 flex justify-center text-white p-4 font-bold cursor-pointer hover:bg-blue-700 duration-300"
                    onClick={() => {
                      makeModal({
                        children: ({ onClose }) => {
                          return (
                            <>
                              <Mask onClose={onClose} />
                              <Account />
                            </>
                          );
                        },
                      });
                    }}
                  >
                    0x1::TransferScripts::peer_to_peer_v2
                  </div>
                </div>
```

将` 0x1::TransferScripts::peer_to_peer_v2`改为`Init_counter`。

定位到`src/modal.jsx`，修改`!! KEY PLACE`为相应的 func：

```react
try {
      // !! KEY PLACE
      const functionId = "0x2fe27a8d6a04d57583172cdda79df0e9::MyCounter::init_counter";
      // !! KEY PLACE
      const strTypeArgs = [];
      
      const tyArgs = utils.tx.encodeStructTypeTags(strTypeArgs);
      const sendAmount = parseFloat(amount, 10);
      if (!(sendAmount > 0)) {
        window.alert("Invalid sendAmount: should be a number!");
        return false;
      }
      const BIG_NUMBER_NANO_STC_MULTIPLIER = new BigNumber("1000000000");
      const sendAmountSTC = new BigNumber(String(sendAmount), 10);
      const sendAmountNanoSTC = sendAmountSTC.times(
        BIG_NUMBER_NANO_STC_MULTIPLIER
      );
      const sendAmountHex = `0x${sendAmountNanoSTC.toString(16)}`; // Multiple BcsSerializers should be used in different closures, otherwise, the latter will be contaminated by the former.
      const amountSCSHex = (function () {
        const se = new bcs.BcsSerializer();
        // eslint-disable-next-line no-undef
        se.serializeU128(BigInt(sendAmountNanoSTC.toString(10)));
        return hexlify(se.getBytes());
      })();

      // !! KEY PLACE
      const args = [];

      // const args = [arrayify(account), arrayify(amountSCSHex)];

      const scriptFunction = utils.tx.encodeScriptFunction(
        functionId,
        tyArgs,
        args
      );
```

 

#### 1.4.4 操作资源
在Move中合约的变量被称为资源，比如`Counter`，资源只能通过脚本间接来调用合约中的内容，而不能直接操作资源。本节的完整代码参见[Move 0x04](https://github.com/WeLightProject/Web3-dApp-Camp/tree/0x04).本节完成后共需要提交三个截图，在下文予以说明。
1.首先实现Counter资源的读取.
将上一节的`Modal.js`中的内容覆盖掉,主要增加了三个按钮`Get Counter`，`Incr_counter`和`Incr_counter_by`;其中`app.jsx`中的下面这行函数调用了读取Counter资源的工具函数。
```
  const getCounter = async () => {
    let res = await getResource(COUNTER_ADDRESS, COUNTER_RESOURCE_ID)
    setCounter(res.value)
  }
```
下面重点实现上面这个函数，创建`src/txs/counter.tx.js`:
```
import { utils, bcs, encoding, } from "@starcoin/starcoin"
import { starcoinProvider } from "../app";
import { arrayify, hexlify } from '@ethersproject/bytes'

export async function getResource(address, functionId) {
    const resourceType = `${address}::${functionId}`
    const resource = await starcoinProvider.getResource(address, resourceType)
    console.log(resource)
    return resource
}
```
通过`getResource`读取，其参数为资源所在账户的`地址`(回忆一下Move中资源存储在个人账户而非公共合约账户)和`完整的资源地址`，它由`账户地址`+`module名`+`资源名`构成，这里`funcitonId`把`module名`+`资源名`组合了起来。

为了方便后续对资源的读取，我们单独创建`/src/txs/config.js`定义所有相关的地址和functionId:
```
export const COUNTER_ADDRESS = "0x07Ffe973C72356C25e623E2470172A69"
export const COUNTER_RESOURCE_ID = "MyCounter::Counter"
export const INCR_COUNTER_FUNC_NAMW = "MyCounter::incr_counter"
export const INCR_COUNTERBY_FUNC_NAME = "MyCounter::incr_counter_by"
```
修改其中的`COUNTER_ADDRESS`为您的账户地址。

为了避免报错在`src/modal.jsx`最下面加入如下两行:
```
export const Counter = () => {}
export const IncreaseCounterBy = () => {}
```

OK，现在点击`Get Counter`可以得到以下截图(截图任务1):
![](/move-dapp/my-counter/front-end/IMG/1.4.4.1.png)

2. 实现incr
这包括两部分：合约的对Counter资源的修改和前端显示。
首先实现合约调用,在`/src/txs/conter.tx.js`中增加以下内容:
```
export async function executeFunction(address, functionName, strTypeArgs = [], args = []) {

    const functionId = `${address}::${functionName}`;
    const tyArgs = utils.tx.encodeStructTypeTags(strTypeArgs);
    if (args.length > 0) {
        args[0] = (function () {
            const se = new bcs.BcsSerializer();
            se.serializeU64(BigInt(args[0].toString(10)));
            return hexlify(se.getBytes());
        })();
    }
    args = args.map(arg => arrayify(arg))
    const scriptFunction = utils.tx.encodeScriptFunction(functionId, tyArgs, args);

    const payloadInHex = (() => {
        const se = new bcs.BcsSerializer();
        scriptFunction.serialize(se);
        return hexlify(se.getBytes());
    })();

    const txParams = {
        data: payloadInHex,
    };

    const transactionHash = await starcoinProvider
        .getSigner()
        .sendUncheckedTransaction(txParams);
    return transactionHash
}
```
Starcoin中合约的调用分为四部分:
1. 链接钱包(在app.jsx中我们已经连好了，只需要引入starcoinProvider)
2. 生成交易内容
3. 调用合约
4. 等待交易确认
现在关注的是交易内容生成，它主要包括三部分:
- functionId：函数签名，本例为账户地址+模块名+函数名
- tyArgs：这个比较晦涩，实际上定义的是转账的token类型而非参数类型，不需要转账时设置为[]即可，需要转账时设置为`0x01::STC::STC`
- args: 函数的参数,本例为[]，后面我们会展示包含一个参数的例子

调用交易则是最下面几行代码，调用后会返回交易的hash:
```
    const transactionHash = await starcoinProvider
        .getSigner()
        .sendUncheckedTransaction(txParams);
```

其次交易状态读取，这需要实现`app.jsx`中的`Counter`组件，删掉原来的:
`export const Counter = () => {}`并在`Modal.js`最下面加入一下内容:
```
import { executeFunction } from "./txs/counter.tx";
import { COUNTER_ADDRESS, INCR_COUNTER_FUNC_NAMW, INCR_COUNTERBY_FUNC_NAME } from "./txs/config";
...
export const Counter = (props) => {
  const [hash, setHash] = useState('')
  const [txStatus, setTxStatus] = useState()
  useEffect(() => {
    const incr_counter = async () => {
      let txHash = await executeFunction(COUNTER_ADDRESS, INCR_COUNTER_FUNC_NAMW)
      setHash(txHash)
      let timer = setInterval(async () => {
        const txnInfo = await starcoinProvider.getTransactionInfo(txHash);
        setTxStatus(txnInfo.status)
        if (txnInfo.status === "Executed") {
          clearInterval(timer);
        }
      }, 500);
    }
    incr_counter()

  }, [])

  const { isShow } = useFadeIn();
  return <div className={classnames(
    "fixed top-2/4 left-2/4 -translate-x-2/4 -translate-y-2/4 rounded-2xl shadow-2xl w-3/4 p-6 bg-white duration-300",
    isShow ? "opacity-100 scale-100" : "opacity-0 scale-50"
  )}>
    {hash && (
      <div className="text-center mt-2 text-gray-500 break-all">
        Transaction Hash: {hash}
      </div>

    )}
    {txStatus ? <div style={{ "textAlign": "Center" }}>{txStatus}</div> : null}
  </div>
}
export const IncreaseCounterBy = () => {}
```
我们不断轮询读取交易状态`await starcoinProvider.getTransactionInfo(txHash);`，知道交易成功。点击`Incr_counter`交易成功后应该看到如下界面(截图任务2):
![](/move-dapp/my-counter/front-end/IMG/1.4.4.2.png)

3. 实现带参数的资源调用
我们的目的是增加一个函数，可以输入需要增加的值X，然后对Counter加上X。首先修改上节的`MyCounter.move`增加以下代码:
```
     public fun incr_by(account: &signer, increasement: u64) acquires Counter {
        let counter = borrow_global_mut<Counter>(Signer::address_of(account));
        counter.value = counter.value + increasement;
     }
     
     public(script) fun incr_counter_by(account: signer,increasement: u64)  acquires Counter {
        Self::incr_by(&account, increasement)
     }
```
然后到`my-counter`文件夹下进行编译`mpm release`，
再进行部署,注意一定要先把dev测试网启动了，账户锁定需要解锁:
```
dev deploy [path to blob] -s [addr] -b
```
然后实现对改合约的调用，由于我们的`counter.tx.js`是一个通用的合约调用函数，因此不需要再针对incr_counter_by单独实现调用函数。只需要修改`/src/Modal.jsx`中的`IncreaseCounterBy`函数的内容，传入正确的合约调用参数即可:
```
export const IncreaseCounterBy = (props) => {
  const [plus, setPlus] = useState(2)
  const [txHash, setTxHash] = useState()
  const [disabled, setDisabled] = useState(false)
  const [txStatus, setTxStatus] = useState()
  const handleCall = () => {
    setDisabled(true)
    setTxStatus("Pending...")
    const incr_counter_by = async () => {
      const tyArgs = []
      const args = [parseInt(plus)]
      let txHash = await executeFunction(COUNTER_ADDRESS, INCR_COUNTERBY_FUNC_NAME, tyArgs, args)
      setTxHash(txHash)
      let timer = setInterval(async () => {
        const txnInfo = await starcoinProvider.getTransactionInfo(txHash);
        setTxStatus(txnInfo.status)
        if (txnInfo.status === "Executed") {
          setDisabled(false)
          clearInterval(timer);
        }
      }, 500);
    }
    incr_counter_by()

  }
  const { isShow } = useFadeIn();

  return (
    <div
      className={classnames(
        "fixed top-2/4 left-2/4 -translate-x-2/4 -translate-y-2/4 rounded-2xl shadow-2xl w-3/4 p-6 bg-white duration-300",
        isShow ? "opacity-100 scale-100" : "opacity-0 scale-50"
      )}
    >
      <div className="font-bold">To</div>
      <div className="mt-2 mb-2">
        <input
          type="text"
          className="focus:outline-none rounded-xl border-2 border-slate-700 w-full p-4"
          value={plus}
          onChange={(e) => setPlus(e.target.value)}
        />
      </div>
      <div
        className="mt-6 p-4 flex justify-center font-bold bg-blue-900 text-white rounded-lg hover:bg-blue-700 cursor-pointer"
        onClick={handleCall}
        disabled={disabled}
      >
        CALL
      </div>
      {txHash && (
        <div className="text-center mt-2 text-gray-500 break-all">
          Transaction: {txHash}
        </div>
      )}
      {txStatus ? <div style={{ "textAlign": "Center" }}>{txStatus}</div> : null}
    </div>
  );
};
```
此时点击Incr_counter_by按钮，会弹出如下交易界面(截图任务3)：
![](/move-dapp/my-counter/front-end/IMG/1.4.4.3.png)。等待交易成功即可。

本节的内容有点多，感谢大家follow到了最后，希望大家耐心完成并理解上述内容。

## 0x02 Move Contract + dApp 案例

### 2.1 PurposeHandler

#### 2.1.1 合约实战

#### 2.1.2 dApp实战

#### 2.1.3 知识点分析

### 2.2 MyToken

#### 2.2.1 合约实战

#### 2.2.2 dApp实战

#### 2.2.3 知识点分析

### 2.3 MyNFT

#### 2.3.1 合约实战

#### 2.3.2 dApp实战

#### 2.3.3 知识点分析

## 0x03

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





