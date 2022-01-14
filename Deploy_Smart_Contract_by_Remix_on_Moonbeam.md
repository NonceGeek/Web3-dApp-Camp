# Deploy Smart Contract by Remix on Moonbeam | Moonbeam Branch 0x01

> 国内用户如需交流，可加微信：197626581.

Authors: **Leeduckgo@NonceGeek, Msfew@NonceGeek**

> Moonbeam is a Polkadot-based smart contract blockchain dedicated to providing development tools and networks familiar to Ethereum developers with compatible functionality. Moonbeam is a developer-friendly blockchain that enables full EVM compatibility, API compatibility with Web3.js, and a bridge to connect Moonbeam to the existing Ethereum network. Developers can easily deploy existing Solidity smart contracts and DApp front ends to Moonbeam with only minor modifications.
>
> Since Moonbeam is an EVM-compatible chain implemented on Substrate, developers and DApps can enjoy all the benefits of EVM while simultaneously enjoying the unlimited possibilities of Substrate in the future, creating an amazing potential with the dual support of Substrate * Ethereum.

On Moonbeam/Moonriver, how should we complete the whole process of "coding → debugging → code flattern → deployment → source code verification on browser" for smart contracts via Remix?

## 0x1 Remix Installation

Remix is our go-to tool for developing Solidity smart contracts, and sometimes we access the web online version of the Remix-IDE directly.

> https://remix.ethereum.org/

However, complicated smart contracts can cause Remix to be frozen, so it's best for us to set up Remix locally.

To set up Remix locally, you need to prepare two things: one is Remix-project, which serves as the front-end client of Remix; the other is Remixd, which serves as the back-end of Remix, and their Github repositories are

- https://github.com/ethereum/remix-project
- https://github.com/ethereum/remixd

### 1.1 Set up Remix-project

Set up Remix-project with Docker is recommended:

```
docker pull remixproject/remix-ide:latest
docker run -p 8080:80 remixproject/remix-ide:latest
```

Then we can access it through browser at port 8080.

![image-20201010220954147](https://tva1.sinaimg.cn/large/008i3skNgy1gyc2xf2v9cj30x40gzmyf.jpg)

### 1.2 Set up Remixd

The following is the steps for setting up Remixd:

1）Install Remixed via npm or yarn (yarn is recommended)

Via npm:

```
npm install remixd -g
```

Via yarn:

```
yarn install -g remixd
```

![pic1](https://tva1.sinaimg.cn/large/008i3skNgy1gyc2x9if1zj30zw0p0dl2.jpg)

2）Start Remix-IDE with one line of command

```
remixd -s [path/ur/solidity/files] --remix-ide http://localhost:8080
# The last parameter means which port is accessed, because we are mapping to the Remix-project of 8080, so fill in http://localhost:8080
```

> **Note:** Check the official doc for starting Remix.

3）Click on Remix-IDE

First, you click on Solidity, select specific environment; then click on Connect to Localhost to, of course, connect to localhost.

![img](https://tva1.sinaimg.cn/large/008i3skNgy1gyc2x9245mj31iq0u0tbr.jpg)

Now we are all set! We can use local contracts in Remix now.

![img](https://tva1.sinaimg.cn/large/008i3skNgy1gyc2xcda1xj31ir0u0770.jpg)

## 0x02 Writing and Debugging Smart Contract

When writing and debugging smart contract codes, we can debug in our local Remix VM.

Only when deploying smart contract, we need to have actual interaction with the blockchain network.

### 2.1 Create contract file

![img](https://tva1.sinaimg.cn/large/008i3skNgy1gyc2x8o9upj31k20qan0l.jpg)

### 2.2 Write contract code

Copy and paste those lines into `hello.sol`

```
pragma solidity^0.8.0;

contract hello {
    string public name;
    constructor() public {
        name = "welight";
    }
}
```

Here is how it looks:

![img](https://tva1.sinaimg.cn/large/008i3skNgy1gyc2x7aneaj31e20lo0v6.jpg)

After writing the code, we need to save it. If you are using windows, hit [ctrl + s]. If Unix, hit [command + s].

### 2.3 Switch to compile view and select specific compiler version

![image-20210318121523436](https://tva1.sinaimg.cn/large/008i3skNgy1gyc2xdo9ptj30hq0dnjs0.jpg)

### 2.4 Switch to environment view and deploy the contract

![image-20200520125102675](https://tva1.sinaimg.cn/large/008i3skNgy1gyc2xazfx2j31g20ou40w.jpg)

![image-20200520125230295](/Users/liaohua/Documents/008eGmZEly1gonyku25l2j316w0u0jz9.png)

### 2.5 Open up contract view and debug the function

![image-20200520125409304](https://tva1.sinaimg.cn/large/008i3skNgy1gyc2xen1wij31og0k0gno.jpg)

Click on Run to get the result.

![img](https://tva1.sinaimg.cn/large/008i3skNgy1gyc2x68lf4j31l00gkmym.jpg)

## 0x03 Flatten Code

In production environment, we normally don't "write" all the code, but use third party libraries like `open-zepplin`.

```
// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
```

Importing libraries are all good when deploying, but when doing source code verification (see `0x05`), it will generate problems like `File import callback not supported`.

So we can do `Flatten` operation for our code. We recommend usig `hardhat`.

Hardhat's tutorial resource is rich. Here is the link for one of the best.

> [Translated] Hardhat Intro Tutorial: https://learnblockchain.cn/article/1356

In this step, we use `hardhat flatten` function.

```
 npx hardhat flatten contracts/web3dev.sol
```

After the execution, `flattened` code will be displayed. Then we copy and paste them into Remix.

![image-20220112201227831](https://tva1.sinaimg.cn/large/008i3skNgy1gyc2x5qlu2j316o0iignr.jpg)

Note that `flatten` function is still not perfect, so we need to delete manully some of the `SPDX` and `pragma`.

## 0x04 Deploy Smart Contract

We can deploy the contract onto the blockchain by `Injected Web3`.

![image-20220112201608832](https://tva1.sinaimg.cn/large/008i3skNgy1gyc2x7o5arj30nk0fmaat.jpg)

Except for the network difference, contract deployment is the same as contract debugging in `0x02`.

We can easily add Moonbeam, Moonriver, and MoonbaseAlpha networks by clicking a few buttons with the help of the following doc.

> https://docs.moonbeam.network/tokens/connect/metamask/

![image-20220112202020362](https://tva1.sinaimg.cn/large/008i3skNgy1gyc2xe64poj31440qyq6b.jpg)

## 0x05 Verify Contract on Explorer

Verifying using browser API is indeed a choice, but it's a complicated one. We can verify just by inputting the source code.

Moonbeam explorer is at:

> https://moonbase.moonscan.io/

First we see an unverified contract on explorer.

![image-20220112202930685](https://tva1.sinaimg.cn/large/008i3skNgy1gyc2x9zexbj30u00v042d.jpg)

We click `Verify and Publish`.

Then select `Single File` and license:

![image-20220112203647704](https://tva1.sinaimg.cn/large/008i3skNgy1gyc2xbcxnlj313k0ti76d.jpg)

After that, we paste the flattened code from `0x03` into the field:

![image-20220112203808386](https://tva1.sinaimg.cn/large/008i3skNgy1gyc2xd6z9aj31340lqgn3.jpg)

Click on `Verify and Publish` to submit:

![image-20220112203835726](https://tva1.sinaimg.cn/large/008i3skNgy1gyc2x839srj30lq05wjrb.jpg)

We are all done when it shows `Succefully`。

![image-20220112203911660](https://tva1.sinaimg.cn/large/008i3skNgy1gyc2xaeq9cj31ee0hcmza.jpg)

Now we access the contract again. When we click on `Contract` page, `Read` and `Write` appears!

![image-20220112204021117](https://tva1.sinaimg.cn/large/008i3skNgy1gyc2xbt4m9j314i0lgmyy.jpg)

![leeduckgo](https://noncegeek.com/namecards/leeduckgo.svg?display=iframe)

![msfew](https://noncegeek.com/namecards/msfew.svg?display=iframe)
