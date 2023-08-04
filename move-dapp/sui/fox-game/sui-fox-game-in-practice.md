# Sui 类狼羊游戏项目开发实践

这篇文章将向你介绍 Sui Move 版本的类狼羊游戏的合约和前端编写过程。阅读前，建议先熟悉以下内容：

1. Sui 命令行的基本操作；
2. Move 语法（[基础](https://mp.weixin.qq.com/s/epwJmR6oXCgtKtSbBqJyAw)和[高级](https://mp.weixin.qq.com/s/OXLyiUKzpFzAzc-PVxLvTA)）和 Sui Move 的对象语法；
3. React 基本语法。

项目代码：

- 合约：[https://github.com/Plor3r/foxgame-contracts](https://github.com/Plor3r/foxgame-contracts)
- 前端： [https://github.com/Plor3r/foxgame-interface](https://github.com/Plor3r/foxgame-interface)

在线 Demo： [https://fox-game-interface.vercel.app/](https://fox-game-interface.vercel.app/)

![Untitled](https://user-images.githubusercontent.com/3297411/215304366-1aeb3308-5859-4613-a61a-f353d0b48877.png)

## 0x1 狼羊游戏的规则

狼羊游戏是以太坊上的 NFT 游戏，玩家通过购买NFT，然后将 NFT 质押来获取游戏代币 $WOOL，游戏代币 $WOOL 可用于之后的 NFT 铸造。有趣的是，狼羊游戏在这个过程中引入了随机性，让单纯的质押过程增加了不确定性，因而吸引了大量玩家参与到游戏中，狼羊游戏的可玩性也是建立在这个基础之上。具体的游戏规则为：

### 1.1 **羊**

你有90%的概率铸造一只羊，每只羊都有独特的特征。以下是他们可以采取的行动：

1. 进入谷仓（Stake）
2. 每天累积 10,000 羊毛 $WOOL
3. 剪羊毛 $WOOL (Claim)
    
    收到的羊毛80%累积在羊的身上，狼对剪下的羊毛收取20%的税，作为不攻击谷仓的回报。征税的 $WOOL 分配给目前在谷仓中质押的所有狼，数量与他们的 Alpha 分数成正比。
    
4. 离开谷仓（Unstake）
    
    羊被从谷仓中移除，所有 $WOOL 都被剪掉了。只有当羊积累了2天价值的 $WOOL 时才能离开谷仓，离开谷仓时你所有累积的 $WOOL 有50%的几率被狼全部偷走。被盗 $WOOL 分配给当前在谷仓中质押的所有狼，数量与他们的 Alpha 分数成正比。
    
5. 使用 $WOOL 铸造一个新羊
    
    铸造的 NFT 有10%的可能性实际上是狼！新的羊或狼有10%的几率被质押的狼偷走。每只狼的成功机会与他们的 Alpha 分数成正比。
    

### 1.2 **狼**

你有 10% 的机会铸造一只狼，每只狼都有独特的特征，包括 5~8 的 Alpha 值。Alpha值越高，狼从税收中赚取的 $WOOL 部分越高，偷一只新铸造的羊或狼的概率也越高。只有被质押的狼才能偷羊或赚取 $WOOL 税。

例子：狼A的 Alpha 为8，狼B的 Alpha 为6，并且他们都被质押。

- 如果累计 70,000 羊毛作为税款，狼A将能够获得 40,000 羊毛，狼B将能够获得 30,000 羊毛；
- 如果新铸造的羊或狼被盗，狼A有57%概率获得，狼B有43%的概率获得。

本次项目实践，我们将在 Sui 区块链上通过 Move 智能合约语言来实现游戏铸造，质押和获取 NFT 过程，并使用新的游戏元素：狐狸，鸡和鸡蛋，其中狐狸对应狼，鸡对应羊，鸡蛋对应羊毛，其他过程不变，我们将这个游戏命名为**狐狸游戏**。

## 0x2 合约开发

我们首先进行智能合约的编写，大致分为以下几个部分：

- 创建 NFT
- 铸造 NFT（Mint）
- 质押 NFT （Stake）
- 鸡蛋（EGG）代币和收集鸡蛋（Collect/Claim）
- 提取 NFT（Unstake）

### 2.1 NFT 结构

首先我们定义狐狸和鸡的 NFT 的结构，我们使用一个结构体 `FoxOrChicken` 来表示这个 NFT， 通过 `is_chicken` 来进行区分：

```rust
 // 文件：token_helper.move
    /// Defines a Fox or Chicken attribute. Eg: `pattern: 'panda'`
    struct Attribute has store, copy, drop {
        name: vector<u8>,
        value: vector<u8>,
    }

    struct FoxOrChicken has key, store {
        id: UID,
        index: u64, // 索引
        is_chicken: bool, // 是否是鸡
        alpha: u8, // 狐狸的 alpha
        url: Url, // 图片
        link: Url, // NFT 链接
        item_count: u8, // 当前 NFT 的数量
        attributes: vector<Attribute>, // 属性
    }
```

其中， `url` 既可以是指向 NFT 图片的链接，也可以是 base64 编码的字符串，比如 `data:image/svg+xml;base64,PHN2Zy......`。`link` 是一个指向 NFT 的页面。

### 2.2 创建 NFT 对象

整个创建 NFT 的逻辑大致就是根据随机种子生成对应属性索引，根据属性索引构建对应的属性列表和图片，从而创建 NFT。

创建 NFT 使用到 `FoCRegistry` 结构体，这个数据结构用于记录关于 NFT 的一些数据，比如 `foc_born` 记录生产的 NFT 总数，`foc_hash` 用于在生产 NFT 时产生随机数，该随机数用于生成 NFT 的属性，`foc_hash` 可以看作是 NFT 的基因。具体的属性值记录如下：

```rust
// 文件：token_helper.move

        struct FoCRegistry has key, store {
        id: UID,
        foc_born: u64, // NFT supply
        foc_hash: vector<u8>, // NFT gene
        rarities: vector<vector<u8>>, // 属性值概率
        aliases: vector<vector<u8>>, // 属性值索引
        types: Table<ID, bool>, // NFT 对象 ID 与类型（是否为鸡）的对应
        alphas: Table<ID, u8>, // 狐狸的 Alpha 值
        trait_data: Table<u8, Table<u8, Trait>>, // 属性值，第一个u8是类型编号，第二个u8是属性索引
        trait_types: vector<vector<u8>>, // 属性类型名称
    }
```

创建 NFT 方法 `create_foc` 如下：

```rust
// 文件：token_helper.move
        public(friend) fun create_foc(
        reg: &mut FoCRegistry, ctx: &mut TxContext
    ): FoxOrChicken {
        let id = object::new(ctx);
        reg.foc_born = reg.foc_born + 1;
        // 根据 UID 与旧 foc_hash 生产新的 foc_hash
        vec::append(&mut reg.foc_hash, object::uid_to_bytes(&id));
        reg.foc_hash = hash(reg.foc_hash);
        // 随机产生 trait，并生成属性对 attributes
        let fc = generate_traits(reg);
        let attributes = get_attributes(reg, &fc);

        let alpha = *vec::borrow(&ALPHAS, (fc.alpha_index as u64));
        // 记录ID对应类型
        table::add(&mut reg.types, object::uid_to_inner(&id), fc.is_chicken);
        if (!fc.is_chicken) {
            table::add(&mut reg.alphas, object::uid_to_inner(&id), alpha);
        };
        // 生成事件
        emit(FoCBorn {
            id: object::uid_to_inner(&id),
            index: reg.foc_born,
            attributes: *&attributes,
            created_by: tx_context::sender(ctx),
        });
        // 返回生成的 FoxOrChicken
        FoxOrChicken {
            id,
            index: reg.foc_born,
            is_chicken: fc.is_chicken,
            alpha: alpha,
            url: img_url(reg, &fc),
            link: link_url(reg.foc_born, fc.is_chicken),
            attributes,
            item_count: 0,
        }
    }
```

其中 `genetate_traits` 用于根据 `foc_hash` 生成 NFT 的属性值，此处属性为对应属性值的索引，`select_trait` 根据 A.J. Walker's Alias 算法根据预先设置好的每一个属性的随机概率（`rarities`）来快速生成对应的属性索引。详情可以参考文章 [https://zhuanlan.zhihu.com/p/436785581](https://zhuanlan.zhihu.com/p/436785581) 中 A.J. Walker's Alias 算法一节****。****

```rust
// 文件： token_helper.move
        // generates traits for a specific token, checking to make sure it's unique
    public fun generate_traits(
        reg: &FoCRegistry,
        // seed: &vector<u8>
    ): Traits {
        let seed = reg.foc_hash;
        let is_chicken = *vec::borrow(&seed, 0) >= 26; // 90% 0f 255
        let shift = if (is_chicken) 0 else 9;
        // 根据随机种子生成属性
                Traits {
            is_chicken,
            fur: select_trait(reg, *vec::borrow(&seed, 1), *vec::borrow(&seed, 10), 0 + shift),
            head: select_trait(reg, *vec::borrow(&seed, 2), *vec::borrow(&seed, 11), 1 + shift),
            ears: select_trait(reg, *vec::borrow(&seed, 3), *vec::borrow(&seed, 12), 2 + shift),
            eyes: select_trait(reg, *vec::borrow(&seed, 4), *vec::borrow(&seed, 13), 3 + shift),
            nose: select_trait(reg, *vec::borrow(&seed, 5), *vec::borrow(&seed, 14), 4 + shift),
            mouth: select_trait(reg, *vec::borrow(&seed, 6), *vec::borrow(&seed, 15), 5 + shift),
            neck: select_trait(reg, *vec::borrow(&seed, 7), *vec::borrow(&seed, 16), 6 + shift),
            feet: select_trait(reg, *vec::borrow(&seed, 8), *vec::borrow(&seed, 17), 7 + shift),
            alpha_index: select_trait(reg, *vec::borrow(&seed, 9), *vec::borrow(&seed, 18), 8 + shift),
        }
    }
    // 根据 A.J. Walker's Alias 算法计算属性值
        fun select_trait(reg: &FoCRegistry, seed1: u8, seed2: u8, trait_type: u64): u8 {
        let trait = (seed1 as u64) % vec::length(vec::borrow(&reg.rarities, trait_type));
        if (seed2 < *vec::borrow(vec::borrow(&reg.rarities, trait_type), trait)) {
            return (trait as u8)
        };
        *vec::borrow(vec::borrow(&reg.aliases, trait_type), trait)
    }
```

而 `get_attributes` 则是根据属性索引值对应从 `trait_types` 和 `trait_data` 中将属性的真实值取出并构建成属性数组。

```rust
fun get_attributes(reg: &mut FoCRegistry, fc: &Traits): vector<Attribute>
```

而 `img_url` 则通过上述生成的特征构建出对应的 base64 编码的 svg 图片。

```rust
        /// Construct an image URL for the NFT.
    fun img_url(reg:&mut FoCRegistry, fc: &Traits): Url {
        url::new_unsafe_from_bytes(token_uri(reg, fc))
    }
        fun token_uri(reg: &mut FoCRegistry, foc: &Traits): vector<u8> {
        let uri = b"data:image/svg+xml;base64,";
        vec::append(&mut uri, base64::encode(&draw_svg(reg, foc)));
        uri
    }
```

至此，我们可以通过 `create_foc` 方法创建一个 FoxOrChicken NFT。

### 2.3 铸造 NFT

接下来我们看到铸造 NFT 过程，大致过程为：

1. 判断总供给量是否满足条件；
2. 如果在 SUI 代币购买阶段，则转移 SUI 代币，否则，需要支付 EGG 代币进行铸造，EGG 的铸造和销毁在之后的章节中介绍；
3. 铸造 NFT 并根据50%概率判断是否被质押的狐狸盗走；
4. 如果选择质押则将 NFT 转入质押，否则转入铸造者的账户中。

```rust
// 文件： fox.move
    /// mint a fox or chicken
    public entry fun mint(
        global: &mut Global,
        treasury_cap: &mut TreasuryCap<EGG>,
        amount: u64,
        stake: bool,
        pay_sui: vector<Coin<SUI>>,
        pay_egg: vector<Coin<EGG>>,
        ctx: &mut TxContext,
    ) {
        assert_enabled(global);
        // 检查供应量是否超出总供应量
        assert!(amount > 0 && amount <= config::max_single_mint(), EINVALID_MINTING);
        let token_supply = token_helper::total_supply(&global.foc_registry);
        assert!(token_supply + amount <= config::target_max_tokens(), EALL_MINTED);

        let receiver_addr = sender(ctx);
        // 处理 SUI 代币付款
        if (token_supply < config::paid_tokens()) {
            assert!(vec::length(&pay_sui) > 0, EINSUFFICIENT_SUI_BALANCE);
            assert!(token_supply + amount <= config::paid_tokens(), EALL_MINTED);
            let price = config::mint_price() * amount;
            let (paid, remainder) = merge_and_split(pay_sui, price, ctx);
            coin::put(&mut global.balance, paid);
            transfer(remainder, sender(ctx));
        } else {
            // EGG 代币付款阶段返还 SUI 代币
            if (vec::length(&pay_sui) > 0) {
                transfer(merge(pay_sui, ctx), sender(ctx));
            } else {
                vec::destroy_empty(pay_sui);
            };
        };
        let id = object::new(ctx);
        let seed = hash(object::uid_to_bytes(&id));
        let total_egg_cost: u64 = 0;
        let tokens: vector<FoxOrChicken> = vec::empty<FoxOrChicken>();
        let i = 0;
        while (i < amount) {
            let token_index = token_supply + i + 1;
            // 判断是否被狐狸盗走
            let recipient: address = select_recipient(&mut global.pack, receiver_addr, seed, token_index);
            let token = token_helper::create_foc(&mut global.foc_registry, ctx);
            if (!stake || recipient != receiver_addr) {
                transfer(token, receiver_addr);
            } else {
                vec::push_back(&mut tokens, token);
            };
            // 计算 EGG 代币花费
            total_egg_cost = total_egg_cost + mint_cost(token_index);
            i = i + 1;
        };
        // 如果需要 EGG 代币花费，则转移并销毁 EGG 代币
        if (total_egg_cost > 0) {
            assert!(vec::length(&pay_egg) > 0, EINSUFFICIENT_EGG_BALANCE);
            // burn EGG
            let total_egg = merge(pay_egg, ctx);
            assert!(coin::value(&total_egg) >= total_egg_cost, EINSUFFICIENT_EGG_BALANCE);
            let paid = coin::split(&mut total_egg, total_egg_cost, ctx);
            egg::burn(treasury_cap, paid);
            transfer(total_egg, sender(ctx));
        } else {
            if (vec::length(&pay_egg) > 0) {
                transfer(merge(pay_egg, ctx), sender(ctx));
            } else {
                vec::destroy_empty(pay_egg);
            };
        };
        // 铸造的同时质押，则将 NFT 转入重要中
        if (stake) {
            barn::stake_many_to_barn_and_pack(
                &mut global.barn_registry,
                &mut global.barn,
                &mut global.pack,
                tokens,
                ctx
            );
        } else {
            vec::destroy_empty(tokens);
        };
        object::delete(id);
    }
```

### 2.4 质押 NFT

质押 NFT 时，我们通过 NFT 的属性值 `is_chicken` 来将不同的NFT放置到不同的容器中。其中，狐狸放置在 Pack 中，鸡放置在 Barn 中。每一个 NFT 在放置的同时记录对应的 owner 地址和用于计算质押收益的时间戳。

对于 `Barn`，除了记录 NFT 对象 `ID` 与 `Stake` 之间对应关系的 `items`，还增加了一个 `dynamic_field`，用于记录 owner 地址所有质押的 NFT 的数组： `dynamic_field: <address, vector<ID>>` 。

同理，`Pack` 也用 `items` 记录了质押的所有 NFT，用 Alpha 进行了分类存储，在 `ObjectTable<u8, ObjectTable<u64, Stake>>` 的结构中，第一个 `u8` 对应于 Alpha 值，第二个 `ObjectTable<u64, Stake>` 则是用 `ObjectTable` 实现了 `vector` 的功能，`u64` 对应 `Stake` 的索引，因此，item_size 这个属性记录了每个 Alpha 值对应 `ObjectTable` 的大小。

`pack_indices` 用于记录每个 NFT 所在数组中的索引，最后还有一个 `dynamic_field` 记录了 owner 地址的所有质押的 NFT 的数组。

以上关于 Barn 和 Pack 的设计目的在于：

1. 当 `FoxOrChicken` 成为 `Stake` 的一个属性时，在区块链上无法追踪，因此，只能通过 `Stake` 的 Object ID 进行追踪，items 都是为了保证能直接通过 NFT 的 Object ID 来对应到 Stake；
2. 记录 owner 地址的所有质押的 NFT ID 的数组是为了方便在业务中查询某个地址的质押的 NFT，`dynamic_field` 可以方便查询。

```rust
        // struct to store a stake's token, owner, and earning values
    struct Stake has key, store {
        id: UID,
        item: FoxOrChicken,
        value: u64, // 用于质押收益计算的时间戳
        owner: address,
    }

    struct Barn has key, store {
        id: UID,
        items: ObjectTable<ID, Stake>,
        // staked: Table<address, vector<ID>>, // address -> stake_id
    }

    struct Pack has key, store {
        id: UID,
        items: ObjectTable<u8, ObjectTable<u64, Stake>>,
        // alpha -> index -> Stake
        item_size: vector<u64>,
        // size for each alpha
        pack_indices: Table<ID, u64>,
        // staked: Table<address, vector<ID>>, // address -> stake_id
    }
```

我们接下来看到如何质押一个 Chicken 的 NFT，方法调用层级为 `stake_many_to_barn_and_pack -> stake_chicken_to_barn -> add_chicken_to_barn, record_staked` ：

```rust
// 文件： Token_helper.move
        // 质押多个 NFT
        public fun stake_many_to_barn_and_pack(
        reg: &mut BarnRegistry,
        barn: &mut Barn,
        pack: &mut Pack,
        tokens: vector<FoxOrChicken>,
        ctx: &mut TxContext,
    ) {
        let i = vec::length<FoxOrChicken>(&tokens);
        while (i > 0) {
            let token = vec::pop_back(&mut tokens);
            // 通过属性 is_chicken 判断质押方向
            if (token_helper::is_chicken(&token)) {
                // 更新收益
                update_earnings(reg, ctx);
                stake_chicken_to_barn(reg, barn, token, ctx);
            } else {
                stake_fox_to_pack(reg, pack, token, ctx);
            };
            i = i - 1;
        };
        vec::destroy_empty(tokens)
    }

        fun stake_chicken_to_barn(reg: &mut BarnRegistry, barn: &mut Barn, item: FoxOrChicken, ctx: &mut TxContext) {
        reg.total_chicken_staked = reg.total_chicken_staked + 1;
        let stake_id = add_chicken_to_barn(reg, barn, item, ctx);
                // 记录 owner 地址的所有质押的 NFT
        record_staked(&mut barn.id, sender(ctx), stake_id);
    }

        fun add_chicken_to_barn(reg: &mut BarnRegistry, barn: &mut Barn, item: FoxOrChicken, ctx: &mut TxContext): ID {
        let foc_id = object::id(&item);
        // 获取当前时间戳
        let value = timestamp_now(reg, ctx);
        let stake = Stake {
            id: object::new(ctx),
            item,
            value,
            owner: sender(ctx),
        };
        // 生成并添加质押
        let stake_id = object::id(&stake);
        emit(FoCStaked { id: foc_id, owner: sender(ctx), value });
        object_table::add(&mut barn.items, foc_id, stake);
        stake_id
    }

        fun record_staked(staked: &mut UID, account: address, stake_id: ID) {
        if (dof::exists_(staked, account)) {
            vec::push_back(dof::borrow_mut(staked, account), stake_id);
        } else {
            dof::add(staked, account, vec::singleton(stake_id));
        };
    }
```

同理，质押 Fox 进入 Pack 中的过程也是类似的，这里就不再赘述，方法调用层级为 `stake_many_to_barn_and_pack ->` `stake_fox_to_pack ->``add_fox_to_pack, record_staked` 。

### 2.5 提取 NFT

提取 Chicken NFT 时，方法调用层级为 `claim_many_from_barn_and_pack -> claim_chicken_from_barn -> remove_chicken_from_barn, remove_staked` 

主要的过程为：

1. 判断 NFT 类型，根据类型从不同的容器中提取 NFT；
2. 判断 NFT 是否存在，是否超过最小质押时间；
3. 计算质押收益；
4. 如果选择提取 NFT，则收益50%概率被狐狸全部拿走；
5. 如果只收集鸡蛋，则需要交 20% 作为保护费。

```rust
// 文件： token_helper.move
    // 提取多个 NFT
        public fun claim_many_from_barn_and_pack(
        foc_reg: &mut FoCRegistry,
        reg: &mut BarnRegistry,
        barn: &mut Barn,
        pack: &mut Pack,
        treasury_cap: &mut TreasuryCap<EGG>,
        tokens: vector<ID>,
        unstake: bool,
        ctx: &mut TxContext,
    ) {
        // 更新收益
        update_earnings(reg, ctx);
        let i = vec::length<ID>(&tokens);
        let owed: u64 = 0;
        while (i > 0) {
            let token_id = vec::pop_back(&mut tokens);
            // 通过 ID 判断是否为 chickena
            // 计算提取收益 owed
            if (token_helper::is_chicken_from_id(foc_reg, token_id)) {
                owed = owed + claim_chicken_from_barn(reg, barn, token_id, unstake, ctx);
            } else {
                owed = owed + claim_fox_from_pack(foc_reg, reg, pack, token_id, unstake, ctx);
            };
            i = i - 1;
        };
        // 根据 owed 的数量为地址铸造 EGG 代币
        if (owed == 0) { return };
        egg::mint(treasury_cap, owed, sender(ctx), ctx);
        vec::destroy_empty(tokens)
    }

        fun claim_chicken_from_barn(
        reg: &mut BarnRegistry,
        barn: &mut Barn,
        foc_id: ID,
        unstake: bool,
        ctx: &mut TxContext
    ): u64 {
        // 判断需要提取的 NFT 是否存在
        assert!(object_table::contains(&barn.items, foc_id), ENOT_IN_PACK_OR_BARN);
        let stake_time = get_chicken_stake_value(barn, foc_id);
        let timenow = timestamp_now(reg, ctx);
        // 判断是否超过了 48 小时的最小质押时间
        assert!(!(unstake && timenow - stake_time < MINIMUM_TO_EXIT), ESTILL_COLD);
        let owed: u64;
        // 判断是否超过了最大 EGG 铸造量，并计算质押所得
        if (reg.total_egg_earned < MAXIMUM_GLOBAL_EGG) {
            owed = (timenow - stake_time) * DAILY_EGG_RATE / ONE_DAY_IN_SECOND;
        } else if (stake_time > reg.last_claim_timestamp) {
            owed = 0; // $WOOL production stopped already
        } else {
            // stop earning additional $EGG if it's all been earned
            owed = (reg.last_claim_timestamp - stake_time) * DAILY_EGG_RATE / ONE_DAY_IN_SECOND;
        };
                
        if (unstake) {
            // 如果进行提取，则有50%的概率 EGG 全部被盗走
            let id = object::new(ctx);
            // FIXME
            if (random::rand_u64_range_with_seed(hash(object::uid_to_bytes(&id)), 0, 2) == 0) {
                // 50% chance of all $EGG stolen
                pay_fox_tax(reg, owed);
                owed = 0;
            };
            object::delete(id);
            // 更新质押数据，并移除质押，转移 NFT 给 owner 地址
            reg.total_chicken_staked = reg.total_chicken_staked - 1;
            let (item, stake_id) = remove_chicken_from_barn(barn, foc_id, ctx);
            remove_staked(&mut barn.id, sender(ctx), stake_id);
            transfer::transfer(item, sender(ctx));
        } else {
             // 如果只是收集 EGG，则 20% 作为保护费交给狐狸
            // percentage tax to staked foxes
            pay_fox_tax(reg, owed * EGG_CLAIM_TAX_PERCENTAGE / 100);
            // remainder goes to Chicken owner
            owed = owed * (100 - EGG_CLAIM_TAX_PERCENTAGE) / 100;
            // 重设质押状态
            set_chicken_stake_value(barn, foc_id, timenow);
        };
        emit(FoCClaimed { id: foc_id, earned: owed, unstake });
        owed
    }
```

同理，从 Pack 中提取 Fox  中的过程也是类似的，这里就不再赘述。

### 2.6 创建 EGG 代币和收集 EGG 代币

EGG 代币创建过程使用了 one-time-witness 模式，具体可以参考：[Move 高阶语法 | 共学课优秀笔记](https://mp.weixin.qq.com/s/OXLyiUKzpFzAzc-PVxLvTA) 中的 Witness 模式一节。

代币的铸造能力 `treasury_cap: TreasuryCap<EGG>` 保存为共享对象，但是 `mint` 和 `burn` 方法t通过 `friend` 关键字限制了只能在 `fox` 和 `barn` 模块中调用，因此控制了代币的产生和销毁的权限。

```rust
// 文件： egg.move
module fox_game::egg {
    use std::option;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::transfer;
    use sui::tx_context::TxContext;

    friend fox_game::fox;
    friend fox_game::barn;

    struct EGG has drop {}

    fun init(witness: EGG, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency<EGG>(
            witness,
            9,
            b"EGG",
            b"Fox Game Egg",
            b"Fox game egg coin",
            option::none(),
            ctx
        );
        transfer::freeze_object(metadata);
        transfer::share_object(treasury_cap)
    }

    /// Manager can mint new coins
    public(friend) fun mint(
        treasury_cap: &mut TreasuryCap<EGG>, amount: u64, recipient: address, ctx: &mut TxContext
    ) {
        coin::mint_and_transfer(treasury_cap, amount, recipient, ctx)
    }

    /// Manager can burn coins
    public(friend) fun burn(treasury_cap: &mut TreasuryCap<EGG>, coin: Coin<EGG>) {
        coin::burn(treasury_cap, coin);
    }
}
```

### 2.7 初始化方法和 entry 方法

`fox` 模块作为整个包的入口模块，将对所有模块进行初始化，并提供 entry 方法。

我们在 fox 模块中设置了 `Global` 作为全局参数的结构体，用来保存不同模块需要用到的不同对象，一来方便我们看到系统需要处理的对象信息，二来减少了方法调用时需要传入的参数个数，通过Global对象将不同模块的对象进行分发，可以有效减少代码复杂度。

```rust
// 文件: fox.move
        struct Global has key {
        id: UID,
        minting_enabled: bool,
        balance: Balance<SUI>,
        pack: Pack,
        barn: Barn,
        barn_registry: BarnRegistry,
        foc_registry: FoCRegistry,
    }

    fun init(ctx: &mut TxContext) {
        // 初始化 FoC 管理权限
        transfer(token_helper::init_foc_manage_cap(ctx), sender(ctx));
        // 初始化全局设置
        share_object(Global {
            id: object::new(ctx),
            minting_enabled: true,
            balance: balance::zero(),
            barn_registry: barn::init_barn_registry(ctx),
            pack: barn::init_pack(ctx),
            barn: barn::init_barn(ctx),
            foc_registry: token_helper::init_foc_registry(ctx),
        });
        // 初始化时间设置权限
        transfer(config::init_time_manager_cap(ctx), @0xa3e46ec682bb5082849c240d2f2d20b0f6e054aa);
    }
```

除了之前介绍过的 mint 方法，我们还提供用于质押和提取 NFT 的 entry 方法：

```rust
// 文件： fox.move
        public entry fun add_many_to_barn_and_pack(
        global: &mut Global,
        tokens: vector<FoxOrChicken>,
        ctx: &mut TxContext,
    ) {
        barn::stake_many_to_barn_and_pack(&mut global.barn_registry, &mut global.barn, &mut global.pack, tokens, ctx);
    }

    public entry fun claim_many_from_barn_and_pack(
        global: &mut Global,
        treasury_cap: &mut TreasuryCap<EGG>,
        tokens: vector<ID>,
        unstake: bool,
        ctx: &mut TxContext,
    ) {
        barn::claim_many_from_barn_and_pack(
            &mut global.foc_registry,
            &mut global.barn_registry,
            &mut global.barn,
            &mut global.pack,
            treasury_cap,
            tokens,
            unstake,
            ctx
        );
    }
```

### 2.8 时间戳问题

目前 Sui 区块链还没有完全实现区块时间，而目前提供的 `tx_context::epoch()` 的精度为24小时，无法满足游戏需求。因此在游戏中，我们通过手动设置时间戳来模拟时间增加，以确保游戏顺利进行。

```rust
// 文件: barn.move

        struct BarnRegistry has key, store {
        id: UID,
        // 其他属性省略
        // fake_timestamp
        timestamp: u64,
    }
        public(friend) fun set_timestamp(reg: &mut BarnRegistry, current: u64, _ctx: &mut TxContext) {
        reg.timestamp = current;
    }
        // 当前时间戳
    fun timestamp_now(reg: &mut BarnRegistry, _ctx: &mut TxContext): u64 {
        reg.timestamp
    }
```

在初始化时，将设置时间的能力给到了一个预先生成的专门用于设置时间戳的地址 `0xa3e46ec682bb5082849c240d2f2d20b0f6e054aa`。

```rust
// 文件: config.move
        // Manager cap to set time
    struct TimeManagerCap has key, store { id: UID }

    public(friend) fun init_time_manager_cap(ctx: &mut TxContext): TimeManagerCap {
        TimeManagerCap { id: object::new(ctx) }
    }

// 文件: fox.move
        fun init(ctx: &mut TxContext) {
        transfer(config::init_time_manager_cap(ctx), @0xa3e46ec682bb5082849c240d2f2d20b0f6e054aa);
    }

        public entry fun set_timestamp(_: &TimeManagerCap, global: &mut Global, current: u64, ctx: &mut TxContext) {
        barn::set_timestamp(&mut global.barn_registry, current, ctx)
    }
```

之后，我们可以设置定时任务进行时间戳更新，通过调用设置时间的命令进行，详细结果可以查看 3.2 节合约命令行调用：

```bash
sui client call --function set_timestamp --module fox --package ${fox_game} --args ${time_cap} ${global} \"$(date +%s)\" --gas-budget 30000
```

至此，我们介绍了合约部分的主要功能，详细的代码可以阅读项目仓库。

## 0x3 合约部署和调用

下面，我们首先将部署合约，并通过命令行进行方法的调用。

### 3.1 合约部署

通过以下命令可以编译和部署合约：

```bash
sui move build
sui client publish . --gas-budget 300000
```

输出结果为：

```bash
$ sui client publish . --gas-budget 300000
UPDATING GIT DEPENDENCY https://github.com/MystenLabs/sui.git
INCLUDING DEPENDENCY MoveStdlib
INCLUDING DEPENDENCY Sui
BUILDING fox_game
----- Certificate ----
Transaction Hash: 5FZi4YxiiBJsCj67JSSzkVZvHdJjKKPtMMMrfGbmPXvH
Transaction Signature: AA==@G9yAoybgfIEi7Wj8HFYeEFwG5WPtJ4FlJ+/jaMXFPyjWg4pUun3WQpB4VH5gim/FzqspMY7QAJcd0iTyJ910Dw==@htyihgkhXVia7MCmWeGtDeU96b7w1ivXPKBAV37DZoo=
Signed Authorities Bitmap: RoaringBitmap<[0, 1, 2]>
Transaction Kind : Publish
Sender: 0xefbb0d3f2dc566f1f4fa844621bee76b43c9579a
Gas Payment: Object ID: 0x0942e72397f46a831ce61003601cbb05697e7a83, version: 0x20f, digest: 0xc318f23ac2772738efe1b958be0b51e3c49d9c772d5aede9f41e1dc69edeb2ea
Gas Price: 1
Gas Budget: 300000
----- Transaction Effects ----
Status : Success
Created Objects:
    - 省略了其他的创建的对象
  - ID: 0x17db4feb4652b8b5ce9ebf6dc7d29463b08e234e , Owner: Shared
  - ID: 0x1d525318e381f93dd2b2f043d2ed96400b4f16d9 , Owner: Immutable
  - ID: 0x59a85fbef4bc17cd73f8ff89d227fdcd6226c885 , Owner: Immutable
  - ID: 0xe364474bd00b7544b9393f0a2b0af2dbea143fd3 , Owner: Account Address ( 0xa3e46ec682bb5082849c240d2f2d20b0f6e054aa )
  - ID: 0xe4ffefc480e20129ff7893d7fd550b17fda0ab0f , Owner: Shared
  - ID: 0xe572b53c8fa93602ae97baca3a94e231c2917af6 , Owner: Account Address ( 0xefbb0d3f2dc566f1f4fa844621bee76b43c9579a )
Mutated Objects:
  - ID: 0x0942e72397f46a831ce61003601cbb05697e7a83 , Owner: Account Address ( 0xefbb0d3f2dc566f1f4fa844621bee76b43c9579a )
```

可以通过交易哈希 `5FZi4YxiiBJsCj67JSSzkVZvHdJjKKPtMMMrfGbmPXvH` 在 sui explorer 中查看部署的合约信息：

![Untitled 1](https://user-images.githubusercontent.com/3297411/215304390-507211a2-638c-4c97-ae58-56ea419e8fcd.png)

通过 `sui client object <object_id>` 可以查看创建的 object 的属性，可以知道：

- `0x17db4feb4652b8b5ce9ebf6dc7d29463b08e234e` 为代币 EGG 的 TreasuryCap 的 ObjectId
- `0x1d525318e381f93dd2b2f043d2ed96400b4f16d9` 为 EGG 的 CoinMetadata
- `0x59a85fbef4bc17cd73f8ff89d227fdcd6226c885` 为部署的地址
- `0xe364474bd00b7544b9393f0a2b0af2dbea143fd3` 为 TimeManagerCap
- `0xe4ffefc480e20129ff7893d7fd550b17fda0ab0f` 为 Global 对象
- `0xe572b53c8fa93602ae97baca3a94e231c2917af6` 为 FoCManagerCap 对象

这些对象将在之后的命令行调用和前端项目中使用到。其他省略的创建的对象为 Trait 对象，在之后不会使用到。

### 3.2 合约命令行调用

1. 设置环境变量
    
    ```bash
    export fox_game=0x59a85fbef4bc17cd73f8ff89d227fdcd6226c885
    export global=0xe4ffefc480e20129ff7893d7fd550b17fda0ab0f
    export egg_treasury=0x17db4feb4652b8b5ce9ebf6dc7d29463b08e234e
    export time_cap=0xe364474bd00b7544b9393f0a2b0af2dbea143fd3
    ```
    
2. 设置时间戳
    
    ```bash
    # 需要切换到时间戳的管理地址 0xa3e46ec682bb5082849c240d2f2d20b0f6e054aa
    sui client switch --address 0xa3e46ec682bb5082849c240d2f2d20b0f6e054aa
    # 设置时间戳
    sui client call --function set_timestamp --module fox --package ${fox_game} --args ${time_cap} ${global} \"$(date +%s)\" --gas-budget 30000
    
    # 查看当前时间戳
    curl https://fullnode.devnet.sui.io:443 -H "Content-Type: application/json" -d '{
      "jsonrpc": "2.0",
      "id": 1,
      "method": "sui_getObject",
      "params":[
          "0xe4ffefc480e20129ff7893d7fd550b17fda0ab0f"
      ]
    }' | jq .result.details.data.fields.barn_registry
    
    # 输出结果，可以看到时间戳已经被设置为 1674831518
    {
      "type": "0x59a85fbef4bc17cd73f8ff89d227fdcd6226c885::barn::BarnRegistry",
      "fields": {
        "egg_per_alpha": "0",
        "id": {
          "id": "0x48136d916ea8a148ab864fdb1fc668f6e6dcf3ff"
        },
        "last_claim_timestamp": "0",
        "timestamp": "1674831518",
        "total_alpha_staked": "0",
        "total_chicken_staked": "0",
        "total_egg_earned": "0",
        "unaccounted_rewards": "8518518"
      }
    }
    ```
    
    之后的每一步操作前都需要同步一次时间戳，保证数据正确。
    
3. 铸造 NFT
    
    使用以下命令进行铸造：
    
    ```bash
    # 查看当前gas
    sui client switch --address 0x659f89084673bf4a993cdea89a94dabf93a2ddb4
    sui client gas
    
    # 输出结果
    Object ID                  |  Gas Value 
    ----------------------------------------------------------------------
     0x0bd32adfbfc73e8daa42eef21b4e4e6cc7081240 |    25219   
     0x2ad1e472502aefd87c3767157391ebc1f169c6b5 |   9928743  
     0x3cd2bb1e03326e5141203cc008e6d2eb44a0df05 |  10000000  
     0x5f2c80c89bedddf92f0dc32cfa16b0ecf76a4680 |  10000000  
     0x635ce8d2e9a9c0056ff1cd8591baee16fe010911 |  10000000
    
    # Mint 1 个 NFT
    sui client call --function mint --module fox --package ${fox_game} --args ${global} ${egg_treasury} \"1\" false \[0x3cd2bb1e03326e5141203cc008e6d2eb44a0df05\] \[\] --gas-budget 100000
    
    # 结果
    ----- Certificate ----
    Transaction Hash: 7p1nmTPYE9884gBCJL6sah2t6Vzh9P59MUeFVURXaEFx
    Transaction Signature: AA==@TNx7guUd7EjEg4s8jyOf+kTkuhVqmzrZWGKzcJNM3iHqcCRk0+pzITmFth8dYM6qKnYAvT3eeSkKNDUaQF2LAA==@oC1nequkpzyJfYuKx7DqIZFNUfF66e+6DEF1Urqo/EM=
    Signed Authorities Bitmap: RoaringBitmap<[1, 2, 3]>
    Transaction Kind : Call
    Package ID : 0x59a85fbef4bc17cd73f8ff89d227fdcd6226c885
    Module : fox
    Function : mint
    Arguments : ["0xe4ffefc480e20129ff7893d7fd550b17fda0ab0f", "0x17db4feb4652b8b5ce9ebf6dc7d29463b08e234e", [1,0,0,0,0,0,0,0], "", ["0x3cd2bb1e03326e5141203cc008e6d2eb44a0df05"], []]
    Type Arguments : []
    Sender: 0x659f89084673bf4a993cdea89a94dabf93a2ddb4
    Gas Payment: Object ID: 0x2ad1e472502aefd87c3767157391ebc1f169c6b5, version: 0x215, digest: 0x197c624ca59151af7cd968b985062fa3e0dbf21711777d7b4602215664233c5b
    Gas Price: 1
    Gas Budget: 100000
    ----- Transaction Effects ----
    Status : Success
    Created Objects:
      - ID: 0x185aa8a244c74ddfe83c38618b46c744425cd7f5 , Owner: Object ID: ( 0x2ba674fcac290baa2927ff26110463f337237f0d )
      - ID: 0x6917cbcf0e6e58184a98e05ad6bbc70a75755d28 , Owner: Object ID: ( 0x2ed343ceebf792a36b2ff0e918b801e34399f4ed )
      - ID: 0x84fe8e597bcb9387b2911b5ef39b90bb111e71a2 , Owner: Account Address ( 0x659f89084673bf4a993cdea89a94dabf93a2ddb4 )
    Mutated Objects:
      - ID: 0x17db4feb4652b8b5ce9ebf6dc7d29463b08e234e , Owner: Shared
      - ID: 0x2ad1e472502aefd87c3767157391ebc1f169c6b5 , Owner: Account Address ( 0x659f89084673bf4a993cdea89a94dabf93a2ddb4 )
      - ID: 0x3cd2bb1e03326e5141203cc008e6d2eb44a0df05 , Owner: Account Address ( 0x659f89084673bf4a993cdea89a94dabf93a2ddb4 )
      - ID: 0xe4ffefc480e20129ff7893d7fd550b17fda0ab0f , Owner: Shared
    ```
    
    其中：
    
    - `\"1\"` 表示铸造的数量为 1；
    - `false` 表示不质押，如果要铸造的同时进行质押，可以修改为 `true`；
    - `\[0x3cd2bb1e03326e5141203cc008e6d2eb44a0df05\]` 是用于支付 0.0099 SUI 铸造费用的 SUI 对象；
    - `\[\]` 表示用于支付 `EGG` 的对象。
    
    可以看到生成的对象中， `0x84fe8e597bcb9387b2911b5ef39b90bb111e71a2` 在地址 `0x659f89084673bf4a993cdea89a94dabf93a2ddb4` 之下，查看属性可以看到对应的 type 为 `0x59a85fbef4bc17cd73f8ff89d227fdcd6226c885::token_helper::FoxOrChicken` ，这个就是我们铸造得到的 NFT，相应的其他属性也可以查看到，命令输出结果可以查看此 [gist](https://gist.github.com/qiwihui/86e7385c635f88b539ed2f032018ca28)。
    
    或者，我们可以通过 `sui_getObjectsOwnedByAddress` RPC 接口可以查看地址所拥有的对象，比如对于地址 `0x659f89084673bf4a993cdea89a94dabf93a2ddb4` ，可以查看所有对象，过滤即可找到创建的对象。
    
    ```bash
    $ curl https://fullnode.devnet.sui.io:443 -H "Content-Type: application/json" -d '{
      "jsonrpc": "2.0",
      "id": 1,
      "method": "sui_getObjectsOwnedByAddress",
      "params":[
          "0x659f89084673bf4a993cdea89a94dabf93a2ddb4"
      ]
    }'
    ```
    
4. 质押 NFT
    
    通过以下命令对前一步铸造的 NFT 进行质押：
    
    ```bash
    sui client call --function add_many_to_barn_and_pack --module fox --package ${fox_game} --args ${global} \[0x84fe8e597bcb9387b2911b5ef39b90bb111e71a2\] --gas-budget 100000
    ```
    
5. 获取收益和 提取 NFT
    
    通过以下命令获取质押收益 EGG：
    
    ```bash
    sui client call --function claim_many_from_barn_and_pack --module fox --package ${fox_game} --args ${global} ${egg_treasury} '["0x84fe8e597bcb9387b2911b5ef39b90bb111e71a2"]' false --gas-budget 100000
    ```
    
    等 48 小时之后，将 `false` 变为 `true`，可以进行 Unstake，将质押的 NFT 提取出来。
    

至此，命令行操作完成。

## 0x4 前端开发

### 4.1 scaffold-move 开发脚手架

这个项目基于 NonceGeek DAO 的 scaffold-move 开发脚手架，这个脚手架目前包含 Aptos 和 Sui 两个公链的前端开发实例，可以可以在这个基础上快速进行 Sui 的前端部分开发。

通过运行以下步骤可以设置开发环境：

```bash
git clone https://github.com/NonceGeek/scaffold-move.git
cd scaffold-move/scaffold-sui/
yarn
yarn dev
```

### 4.2 项目页面结构

项目页面主要包括三部分，位于 `src/pages` 目录：index，game 和 whitepapers：

- index：入口页面，做为游戏的引导页面；
- game：主要的逻辑页面，涉及铸造，质押和提取；
- whitepaper：白皮书页面，介绍游戏机制和玩法。

我们之后的部分主要聚焦在 game 页面。game 页面功能主要包括三部分：

- 菜单栏：包含logo，页面导航以及链接钱包；
- 左侧 Mint 栏：主要当前 mint 状态和 mint 操作；
- 右侧 Stake 栏：主要是 Stake，Unstale 和 Collect EGG 的操作。

![Untitled 2](https://user-images.githubusercontent.com/3297411/215304399-47738ec4-8dc2-4063-9d1a-fa5ab05f963b.png)

其中，质押和提取时进行的多选操作，可以通过设置选择变量进行过滤来实现：

```tsx
  const [unstakedSelected, setUnstakedSelected] = useState<Array<string>>([])
  const [stakedSelected, setStakedSelected] = useState<Array<string>>([]);
    
    // 设置添加和删除操作
    function addStaked(item: string) {
    setUnstakedSelected([])
    setStakedSelected([...stakedSelected, item])
  }

  function removeStaked(item: string) {
    setUnstakedSelected([])
    setStakedSelected(stakedSelected.filter(i => i !== item))
  }

  function addUnstaked(item: string) {
    setStakedSelected([])
    setUnstakedSelected([...unstakedSelected, item])
  }

  function removeUnstaked(item: string) {
    setStakedSelected([])
    setUnstakedSelected(unstakedSelected.filter(i => i !== item))
  }
    // 之后添加元素的点击事件
    // 处理未质押的
  function renderUnstaked(item: any, type: string) {
    const itemIn = unstakedSelected.includes(item.objectId);
    return <div key={item.objectId} style={{ marginRight: "5px", marginLeft: "5px", border: itemIn ? "2px solid red" : "2px solid rgb(0,0,0,0)", overflow: 'hidden', display: "inline-block" }}>
      <div className="flex flex-col items-center">
        <div style={{ fontSize: "0.75rem", height: "1rem" }}>#{item.index}</div>
        <Image src={`${item.url}`} width={48} height={48} alt={`${item.objectId}`} onClick={() => itemIn ? removeUnstaked(item.objectId) : addUnstaked(item.objectId)} />
      </div>
    </div>
  }
  // 处理质押的
  function renderStaked(item: any, type: string) {
    const itemIn = stakedSelected.includes(item.objectId);
    return <div key={item.objectId} style={{ marginRight: "5px", marginLeft: "5px", border: itemIn ? "2px solid red" : "2px solid rgb(0,0,0,0)", overflow: 'hidden', display: "inline-block" }}>
      <div className="flex flex-col items-center">
        <div style={{ fontSize: "0.75rem", height: "1rem" }}>#{item.index}</div>
        <Image src={`${item.url}`} width={48} height={48} alt={`${item.objectId}`} onClick={() => itemIn ? removeStaked(item.objectId) : addStaked(item.objectId)} />
      </div>
    </div>
  }
```

### 4.3 连接钱包

我们使用 Suiet 钱包开发的 `@suiet/wallet-kit` 包连接 Sui 钱包，从包对应的 WalletContextState 可以看出， `useWallet` 包含了我们在构建 App 时会使用到的基本信息和功能，比如钱包信息，链信息，连接状态信息，以及发送交易，签名信息等。

```tsx
export interface WalletContextState {
    configuredWallets: IWallet[];
    detectedWallets: IWallet[];
    allAvailableWallets: IWallet[];
    chains: Chain[];
    chain: Chain | undefined;
    name: string | undefined;
    adapter: IWalletAdapter | undefined;
    account: WalletAccount | undefined;
    address: string | undefined;
    connecting: boolean;
    connected: boolean;
    status: "disconnected" | "connected" | "connecting";
    select: (walletName: string) => void;
    disconnect: () => Promise<void>;
    getAccounts: () => readonly WalletAccount[];
    signAndExecuteTransaction(transaction: SuiSignAndExecuteTransactionInput): Promise<SuiSignAndExecuteTransactionOutput>;
    signMessage: (input: {
        message: Uint8Array;
    }) => Promise<ExpSignMessageOutput>;
    on: <E extends WalletEvent>(event: E, listener: WalletEventListeners[E]) => () => void;
}
export declare const WalletContext: import("react").Context<WalletContextState>;
export declare function useWallet(): WalletContextState;
```

在 `src/components/SuiConnect.tsx` 中，我们可以很方便的设置钱包连接功能：

```tsx
import {
  ConnectButton,
} from '@suiet/wallet-kit';

export function SuiConnect() {
  return (
      <ConnectButton>Connect Wallet</ConnectButton>
  );
}
```

之后，我们将需要使用的信息在 `src/pages/game.tsx` 中引入：

```tsx
import {
  useWallet,
} from '@suiet/wallet-kit';

export default function Home() {

  const { signAndExecuteTransaction, connected, account, status } = useWallet();

    // 省略
```

其中， `signAndExecuteTransaction` 方法用来签名并执行交易，支持 `moveCall` ， `transferSui`， `transferObject` 等交易。

### 4.4 RPC 接口调用

我们使用官方提供的 `@mysten/sui.js` 库调用 Sui 的 RPC 接口，这个库支持了大部分 [Sui JSON-RPC](https://docs.sui.io/sui-jsonrpc)，同时，还提供了一些额外的方法方便开发，例如：

- `selectCoinsWithBalanceGreaterThanOrEqual` ：获取大于等于指定数量的coin对象ID数组
- `selectCoinSetWithCombinedBalanceGreaterThanOrEqual`：获取总和大于等于指定数量的coin对象ID数组

这两个方法在需要在 NFT 铸造时支付 SUI 或者其他代币时十分有用。我们在 `game.tsx` 中引入 JsonProvider 进行初始化：

```tsx
// 文件: src/pages/game.tsx
import { JsonRpcProvider } from '@mysten/sui.js';

export default function Home() {
    // 操作 client
  const provider = new JsonRpcProvider();
    // 调用
    const suiObjects = await provider.selectCoinSetWithCombinedBalanceGreaterThanOrEqual(account!.address, suiCost)
// 其他省略
```

其他方法的介绍可以参考库的文档，这里不多赘述。

### 4.5 铸造 NFT 等 entry 方法

我们首先看到如何铸造 NFT：

```tsx
// 文件: src/pages/game.tsx 
  async function mint_nft() {
    let suiObjectIds = [] as Array<string>
    let eggObiectIds = [] as Array<string>
        // 获取足够的 SUI 或者 EGG 代币的对象ID
    if (collectionSupply < PAID_TOKENS) {
      const suiObjects = await provider.selectCoinSetWithCombinedBalanceGreaterThanOrEqual(account!.address, suiCost)
      suiObjectIds = suiObjects.filter(item => item.status === "Exists").map((item: any) => item.details.data.fields.id.id)
    } else {
      const eggObjects = await provider.selectCoinSetWithCombinedBalanceGreaterThanOrEqual(account!.address, eggCost, `${PACKAGE_ID}::egg::EGG`)
      eggObiectIds = eggObjects.filter(item => item.status === "Exists").map((item: any) => item.details.data.fields.id.id)
    }
    try {
            // 调用 moveCall 方法，构造交易并签名
      const resData = await signAndExecuteTransaction({
        transaction: {
          kind: 'moveCall',
          data: mint(false, suiObjectIds, eggObiectIds),
        },
      });
            // 检查结果
      if (resData.effects.status.status !== "success") {
        console.log('failed', resData);
      }
      // 设置 Mint 交易
      setMintTx('https://explorer.sui.io/transaction/' + resData.certificate.transactionDigest)
    } catch (e) {
      console.error('failed', e);
    }
  }
    
    // 构造 mint 方法所需要的参数
  function mint(stake: boolean, sui_objects: Array<string>, egg_objects: Array<string>) {
    return {
      packageObjectId: PACKAGE_ID,
      module: 'fox',
      function: 'mint',
      typeArguments: [],
      arguments: [
        GLOBAL, EGG_TREASUTY, mintAmount.toString(), stake, sui_objects, egg_objects
      ],
      gasBudget: 1000000,
    };
  }

  return (
        // 其他部分省略
        <div className="text-center font-console pt-1" onClick={() => mint_nft()}>Mint</div>
    )
```

其中 `arguments` 参数对应 mint 方法所需要的参数。

同理，其他的 entry 方法的调用和签名也与 Mint 方法类似，分别为：

```tsx
// 铸造并质押
async function mint_nft_stake()
// 质押
async function stake_nft()
// 提取
async function unstake_nft()
// 收集 EGG
async function claim_egg()
```

### 4.6 合约数据读取

对于 Sui 公链，除了调用合约，另一块难点是合约数据的读取。相对于 EVM 合约，Move的合约数据结构更复杂，更难读取。由于在 Sui 中，Object 对象被包装后可能无法进行追踪（详情可以参考官方 [Object 教程系列](https://docs.sui.io/build/programming-with-objects)），因此在之前的数据结构设计中，Pack 和 Barn 中存储的 NFT 需要使用能进行追踪的数据结构。因此，ObjectTable 被做为基本的键值存储结构区别于不可追踪的 Table 数据类型。相应地，可以使用  `sui_getDynamicFieldObject` 来读取其中的数据，例如，通过读取保存在 PackStaked 中的 NFT 对象质押列表，从而通过 `getObjectBatch` 可以获取当前地址所有的质押的 NFT。

```tsx
        // 读取 Pack 中质押的 Fox NFT
        const objects: any = await sui_client.getDynamicFieldObject(packStakedObject, account!.address);
          if (objects != null) {
            const fox_staked = objects.details.data.fields.value
            const fox_stakes = await provider.getObjectBatch(fox_staked)
            const staked = fox_stakes.filter(item => item.status === "Exists").map((item: any) => {
              let foc = item.details.data.fields.item
              return {
                objectId: foc.fields.id.id,
                index: parseInt(foc.fields.index),
                url: foc.fields.url,
              }
            })
            setStakedFox(staked)
          }
        }
```

其中， `packStakedObject` 对象ID通过 `GLOBAL` 对象 ID 获取得到。

```tsx
            const globalObject: any = await provider.getObject(GLOBAL)

      const pack_staked = globalObject.details.data.fields.pack.fields.id.id
      setPackStakedObject(pack_staked)
```

对于当前地址所拥有的未质押的NFT，需要通过读取全部对象ID后进行类型过滤才能得到：

```tsx
                // 获取所有对象
                const objects = await provider.getObjectsOwnedByAddress(account!.address)
        // 过滤 FoxOrChicken 对象
                const foc = objects
          .filter(item => item.type === `${PACKAGE_ID}::token_helper::FoxOrChicken`)
          .map(item => item.objectId)
        const foces = await provider.getObjectBatch(foc)
                // 过滤并读取信息，然后排序
        const unstaked = foces.filter(item => item.status === "Exists").map((item: any) => {
          return {
            objectId: item.details.data.fields.id.id,
            index: parseInt(item.details.data.fields.index),
            url: item.details.data.fields.url,
            is_chicken: item.details.data.fields.is_chicken,
          }
        }).sort((n1, n2) => n1.index - n2.index)
                // 存储
        setUnstakedFox(unstaked.filter(item => !item.is_chicken))
        setUnstakedChicken(unstaked.filter(item => item.is_chicken))
```

最后，对于当前地址中包含的 EGG 代币的余额，可以通过 `getCoinBalancesOwnedByAddress` 获得所有余额对象并进行求和得到。

```tsx
        const balanceObjects = await provider.getCoinBalancesOwnedByAddress(account!.address, `${PACKAGE_ID}::egg::EGG`)
        const balances = balanceObjects.filter(item => item.status === 'Exists').map((item: any) => parseInt(item.details.data.fields.balance))
        const initialValue = 0;
        const sumWithInitial = balances.reduce(
          (accumulator, currentValue) => accumulator + currentValue,
          initialValue
        )
        setEggBalance(sumWithInitial);
```

## 总结

至此，我们完成了狐狸游戏合约和前端代码的介绍。我们实现的狐狸游戏虽然功能上只有铸造，质押和提取这几个主要的功能，但是涉及 NFT 创建以及 Sui Move 的诸多语法，整体项目具有一定的难度。

这篇文章希望对有兴趣于 Sui 上的 NFT 的操作的同学有所帮助，也希望大家提出宝贵的建议和意见。项目目前只完成了初步的逻辑功能，还需要继续补充测试和形式验证，欢迎有兴趣的同学提交 Pull Request。

## 参考文档

- [https://docs.sui.io/](https://docs.sui.io/)
- [https://zhuanlan.zhihu.com/p/439236444](https://zhuanlan.zhihu.com/p/439236444)