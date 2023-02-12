# Sui 数据类型讲解

这篇文章中，我们将介绍 Sui 中常见的数据结构，这些结构包含 Sui Move 和 Sui Framework 中提供的基础类型和数据结构，理解和熟悉这些数据结构对于 Sui Move 的理解和应用大有裨益。

首先，我们先快速复习一下 Sui Move 中使用到的基础类型。

### 无符号整型（Integer）

Move 包含六种无符号整型：`u8`，`u16` `u32`，`u64`，`u128`和 `u256`。值的范围从 0 到 与类型大小相关的最大值。

这些类型的字面值为数字序列（例如 112）或十六进制文字，例如 `0xFF`。 字面值的类型可以选择添加为后缀，例如 `112u8`。 如果未指定类型，编译器将尝试从使用文字的上下文中推断类型。 如果无法推断类型，则假定为 `u64`。

对无符号整型支持的运算包括：

- 算数运算： `+` `-`  `*`  `%` `/`
- 位运算： `&` `|` `^`  `>>` `<<`
- 比较运算： `>` `<` `>=` `<=`  `==` `!=`
- 类型转换： `as`
    - 注意，类型转换不会截断，因此如果结果对于指定类型而言太大，转换将中止。

简单示例：

```rust
let a: u64 = 4;
let b = 2u64;
let hex_u64: u64 = 0xCAFE;

assert!(a+b==6, 0);
assert!(a-b==2, 0);
assert!(a*b==8, 0);
assert!(a/b==2, 0);

let complex_u8 = 1;
let _unused = 10 << complex_u8;

(b as u128)
```

### 布尔类型（Bool）

Move 布尔值包含两种，`true` 和 `false` 。支持与 `&&`，或`||`  和非 `!` 运算。可以用于 Move 的控制流和 `assert!` 中。 `assert!` 是 Move 提供的用于断言，当判断的值是 `false` 时，程序会抛出错误并停止。

```rust
if (bool) { ... }
while (bool) { .. }
assert!(bool, u64)
```

### 地址（Address）

address 也是 Move 的原生类型，可以在地址下保存模块和资源。Sui 中地址的长度为 20 字节。

在表达式中，地址需要使用前缀 `@` ，例如：

```rust
let a1: address = @0xDEADBEEF; // shorthand for 0x00000000000000000000000000000000DEADBEEF
let a2: address = @0x0000000000000000000000000000000000000002;
```

### Tuples 和 Unit

Tuples 和 Unit `()` 在 Move 中主要用作函数返回值。只支持解构（destructuring）运算。

```rust
module ds::tuples {
    // all 3 of these functions are equivalent
    fun returns_unit() {}
    fun returns_2_values(): (bool, bool) { (true, false) }
    fun returns_4_values(x: &u64): (&u64, u8, u128, vector<u8>) { (x, 0, 1, b"foobar") }

    fun examples(cond: bool) {
        let () = ();
        let (x, y): (u8, u64) = (0, 1);
        let (a, b, c, d) = (@0x0, 0, false, b"");

        () = ();
        (x, y) = if (cond) (1, 2) else (3, 4);
        (a, b, c, d) = (@0x1, 1, true, b"1");
    }

    fun examples_with_function_calls() {
        let () = returns_unit();
        let (x, y): (bool, bool) = returns_2_values();
        let (a, b, c, d) = returns_4_values(&0);

        () = returns_unit();
        (x, y) = returns_2_values();
        (a, b, c, d) = returns_4_values(&1);
    }
}
```

接下来，我们从 Vector 开始，介绍 Sui 和 Sui Framework 中支持的集合类型。

### 数组（Vector）

`vector<T>` 是 Move 提供的唯一的原生集合类型。`vector<T>` 是由一组相同类型的值组成的数组，比如 `vector<u64>`， `vector<address>` 等。

`vector` 支持的主要操作有：

- 末尾添加元素：`push_back`
- 末尾删除元素： `pop_back`
- 读取或者修改： `borrow` ，`borrow_mut`
- 判断是否包含： `contains`
- 交换元素： `swap`
- 读取元素索引： `index_of`

```rust
module ds::vectors {
    use std::vector;

    public entry fun example() {
        let v = vector::empty<u64>();
        vector::push_back(&mut v, 5);
        vector::push_back(&mut v, 6);

        assert!(vector::contains(&mut v, &5), 42);
        
        let (exists, index) = vector::index_of(&mut v, &5);
        assert!(exists, 42);
        assert!(index == 0, 42);

        assert!(*vector::borrow(&v, 0) == 5, 42);
        assert!(*vector::borrow(&v, 1) == 6, 42);

        vector::swap(&mut v, 0, 1);

        assert!(vector::pop_back(&mut v) == 5, 42);
        assert!(vector::pop_back(&mut v) == 6, 42);
    }
}
```

编译并运行示例：

```bash
# 编译并发布
sui client publish . --gas-budget 300000

# 获取上一步编译得到的包的ID
export package_id=0xee2961ee26916285ebef57c68caaa5f67a3d8dbd

sui client call \
  --function example \
  --module vectors \
  --package ${package_id} \
  --gas-budget 30000
```

下面我们介绍几种基于 `vector`  的数据类型。

### 字符串（String）

Move 没有字符串的原生类型，但它使用 `vector<u8>` 表示字节数组。目前， `vector<u8>` 字面量有两种：字节字符串（byte strings）和十六进制字符串（hex strings）。

字节字符串是以 `b` 为前缀的字符串文字，例如 `b"Hello!\n"`。

十六进制字符串是以 `x` 为前缀的字符串文字，例如 `x"48656C6C6F210A"` 。每一对字节的范围从 `00` 到 `FF`，表示一个十六进制的 `u8`。因此我们可以知道： `b"Hello" == x"48656C6C6F"`。

在 `vector<u8>` 的基础上，Move 提供了 `string` 包处理 UTF8 字符串的操作。

我们以创建 Name NFT 的为例：

```rust
module ds::strings {
    use sui::object::{Self, UID};
    use sui::tx_context::{sender, TxContext};
    use sui::transfer;

    // 使用 std::string 作为 UTF-8 字符串
    use std::string::{Self, String};

    /// 保存 String 类型
    struct Name has key, store {
        id: UID,

        /// String 类型
        name: String
    }

    fun create_name(
        name_bytes: vector<u8>, ctx: &mut TxContext
    ): Name {
        Name {
            id: object::new(ctx),
            name: string::utf8(name_bytes)
        }
    }

    /// 传入原始字节（raw bytes）来创建
    public entry fun issue_name_nft(
        name_bytes: vector<u8>, ctx: &mut TxContext
    ) {
        transfer::transfer(
            create_name(name_bytes, ctx),
            sender(ctx)
        );
    }
}
```

编译后命令行中调用：

```bash
$ sui client call \
  --function issue_name_nft \
  --module strings \
  --package ${package_id} \
  --args "my_nft" --gas-budget 30000

# 部分输出结果

----- Transaction Effects ----
Status : Success
Created Objects:
  - ID: 0xf53891c8d200125bcfdba69557b158395bdf9390 , Owner: Account Address ( 0xf28e73e59f2305edf4df88756f78fa1f5d7e78b0 )
Mutated Objects:
  - ID: 0xd1de857a7a5452a73c9c176cd7c9db1b06671723 , Owner: Account Address ( 0xf28e73e59f2305edf4df88756f78fa1f5d7e78b0 )
```

可以在 Transaction Effects 中看到新创建的对象，ID 为 `0xf53891c8d200125bcfdba69557b158395bdf9390`，通过 Sui 提供的 RPC-API 接口 `sui_getObject` 可以看到其中保存的内容：

```json
curl -H 'Content-Type: application/json' https://fullnode.devnet.sui.io:443 -d '{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "sui_getObject",
  "params":[
      "0xf53891c8d200125bcfdba69557b158395bdf9390"
  ]
}'
```

输出结果

```json
{
    "jsonrpc": "2.0",
    "result": {
        "status": "Exists",
        "details": {
            "data": {
                "dataType": "moveObject",
                "type": "0xee2961ee26916285ebef57c68caaa5f67a3d8dbd::strings::Name",
                "has_public_transfer": true,
                "fields": {
                    "id": {
                        "id": "0xf53891c8d200125bcfdba69557b158395bdf9390"
                    },
                    "name": "my_nft"
                }
            },
            "owner": {
                "AddressOwner": "0xf28e73e59f2305edf4df88756f78fa1f5d7e78b0"
            },
            "previousTransaction": "7AfcBmJCioSbdZD6ZdYU2iUuGiSc62AuhZn7Yi3TfLDa",
            "storageRebate": 13,
            "reference": {
                "objectId": "0xf53891c8d200125bcfdba69557b158395bdf9390",
                "version": 1614,
                "digest": "/SEDlnh4xXq//ZGOCZVQM5QfyR2fPzJWaYWELhrSn2o="
            }
        }
    },
    "id": 1
}
```

### VecMap 和 VecSet

Sui 在 `vector` 的基础上实现了两种数据结构，映射 `vec_map` 和集合 `vec_set` 。

`vec_map` 是一种映射结构，保证不包含重复的键，但是条目按照插入顺序排列，而不是按键的顺序。所有的操作时间复杂度为 `0(N)`，N 为映射的大小。`vec_map` 只是为了提供方便的操作映射的接口，如果需要保存大型的映射，或者是需要按键的顺序排序的映射都需要另外处理。可以考虑使用之后介绍的 `table` 数据结构。

主要操作包括：

- 创建空映射: `empty`
- 插入键值对： `insert`
- 获取键对应的值： `get`， `get_mut`
- 删除键： `remove`
- 判断是否包含键： `contains`
- 映射大小： `size`
- 将映射转为键值对的数组： `into_keys_values`
- 获取映射键的数组： `keys`
- 删除空映射： `destroy_empty`
- 通过插入的顺序索引键值对： `get_entry_by_idx`，`get_entry_by_idx_mut`

```rust
module ds::v_map {
    use sui::vec_map;
    use std::vector;

    public entry fun example() {
        let m = vec_map::empty();
        let i = 0;
        while (i < 10) {
            let k = i + 2;
            let v = i + 5;
            vec_map::insert(&mut m, k, v);
            i = i + 1;
        };
        assert!(!vec_map::is_empty(&m), 0);
        assert!(vec_map::size(&m) == 10, 1);
        let i = 0;
        // make sure the elements are as expected in all of the getter APIs we expose
        while (i < 10) {
            let k = i + 2;
            assert!(vec_map::contains(&m, &k), 2);
            let v = *vec_map::get(&m, &k);
            assert!(v == i + 5, 3);
            assert!(vec_map::get_idx(&m, &k) == i, 4);
            let (other_k, other_v) = vec_map::get_entry_by_idx(&m, i);
            assert!(*other_k == k, 5);
            assert!(*other_v == v, 6);
            i = i + 1;
        };
        // 移出所有元素
        let (keys, values) = vec_map::into_keys_values(copy m);
        let i = 0;
        while (i < 10) {
            let k = i + 2;
            let (other_k, v) = vec_map::remove(&mut m, &k);
            assert!(k == other_k, 7);
            assert!(v == i + 5, 8);
            assert!(*vector::borrow(&keys, i) == k, 9);
            assert!(*vector::borrow(&values, i) == v, 10);

            i = i + 1;
        }
    }
}
```

`vec_set` 结构保证其中不包含重复的键。所有的操作时间复杂度为 `O(N)`，N 为映射的大小。同样， `vec_set` 提供了方便的集合操作接口，按插入顺序进行排序，如果需要使用按键进行排序的集合，也需要另外处理。

主要操作包括：

- 创建空集合: `empty`
- 插入元素： `insert`
- 删除元素： `remove`
- 判断是否包含元素： `contains`
- 集合大小： `size`
- 将集合转为元素的数组： `into_keys`

```rust
module ds::v_set {
    use sui::vec_set;
    use std::vector;

    public entry fun example() {
        let m = vec_set::empty();
        let i = 0;
        while (i < 10) {
            let k = i + 2;
            vec_set::insert(&mut m, k);
            i = i + 1;
        };
        assert!(!vec_set::is_empty(&m), 0);
        assert!(vec_set::size(&m) == 10, 1);
        let i = 0;
        // make sure the elements are as expected in all of the getter APIs we expose
        while (i < 10) {
            let k = i + 2;
            assert!(vec_set::contains(&m, &k), 2);
            i = i + 1;
        };
        // 移出所有元素
        let keys = vec_set::into_keys(copy m);
        let i = 0;
        while (i < 10) {
            let k = i + 2;
            vec_set::remove(&mut m, &k);
            assert!(*vector::borrow(&keys, i) == k, 9);
            i = i + 1;
        }
    }
}
```

### 优先队列（PriorityQueue）

还有一种基于 `vector` 构建的数据结构：优先队列，他使用基于 `vector` 实现的大顶堆（max heap）来实现。

大顶堆是一种二叉树结构，每个节点的值都大于或等于其左右孩子节点的值，这样，这个二叉树的根节点始终都是所有节点中值最大的节点。

在优先队列中，我们为每一个节点赋予一个权重，我们基于权重构建一个大顶堆，从大顶堆顶部弹出根节点则为权重最大的节点。这样就形成过了一个按优先级弹出的队列。

优先队列主要包含的操作为：

- 创建条目列表： `create_entries` ，结果作为 `new` 方法参数
- 创建： `new`
- 插入： `insert`
- 弹出最大： `pop_max`

示例：

```rust
module ds::pq {
    use sui::priority_queue::{PriorityQueue, pop_max, create_entries, new, insert};

    /// 检查弹出的最大值及其权重
    fun check_pop_max(h: &mut PriorityQueue<u64>, expected_priority: u64, expected_value: u64) {
        let (priority, value) = pop_max(h);
        assert!(priority == expected_priority, 0);
        assert!(value == expected_value, 0);
    }

    public entry fun example() {
        let h = new(create_entries(vector[3, 1, 4, 2, 5, 2], vector[10, 20, 30, 40, 50, 60]));
        check_pop_max(&mut h, 5, 50);
        check_pop_max(&mut h, 4, 30);
        check_pop_max(&mut h, 3, 10);
        insert(&mut h, 7, 70);
        check_pop_max(&mut h, 7, 70);
        check_pop_max(&mut h, 2, 40);
        insert(&mut h, 0, 80);
        check_pop_max(&mut h, 2, 60);
        check_pop_max(&mut h, 1, 20);
        check_pop_max(&mut h, 0, 80);
    }
}
```

### 结构体（Struct）

Move语言中，结构体是包含类型化字段的用户定义数据结构。 结构可以存储任何非引用类型，包括其他结构。示例：

```rust
module ds::structs {
    // 二维平面点
    struct Point has copy, drop, store {
        x: u64,
        y: u64,
    }
    // 圆
    struct Circle has copy, drop, store {
        center: Point,
        radius: u64,
    }
    // 创建结构体
    public fun new_point(x: u64, y: u64): Point {
        Point {
            x, y
        }
    }
    // 访问结构体数据
    public fun point_x(p: &Point): u64 {
        p.x
    }

    public fun point_y(p: &Point): u64 {
        p.y
    }

    fun abs_sub(a: u64, b: u64): u64 {
        if (a < b) {
            b - a
        }
        else {
            a - b
        }
    }
    // 计算点之间的距离
    public fun dist_squared(p1: &Point, p2: &Point): u64 {
        let dx = abs_sub(p1.x, p2.x);
        let dy = abs_sub(p1.y, p2.y);
        dx * dx + dy * dy
    }

    public fun new_circle(center: Point, radius: u64): Circle {
        Circle { center, radius }
    }
    // 计算两个圆之间是否相交
    public fun overlaps(c1: &Circle, c2: &Circle): bool {
        let d = dist_squared(&c1.center, &c2.center);
        let r1 = c1.radius;
        let r2 = c2.radius;
        d * d <= r1 * r1 + 2 * r1 * r2 + r2 * r2
    }
}
```

### 对象（Object）

对象是 Sui Move 中新引入的概念，也是 Sui 安全和高并发等众多特性的基础。定义一个对象，需要为结构体添加 `key` 能力，同时结构体的第一个字段必须是 `UID` 类型的 id。

对象结构中除了可以使用基础数据结构外，也可以包含另一个对象，即对象可以进行包装，在一个对象中使用另一个对象。

对象有不同的所有权形式，可以存放在一个地址下面，也可以设置成不可变对象或者全局对象。不可变对象永远不能被修改，转移或者删除，因此它不属于任何人，但也可以被任何人访问。比如合约包对象，Coin Metadata 对象。

我们可以通过 `transfer` 包中的方法对对象进行处理：

- `transfer`：将对象放到某个地址下
- `freeze_object`：创建不可变对象
- `share_object`：创建共享对象

```rust
module ds::objects {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct ColorObject has key {
        id: UID,
        red: u8,
        green: u8,
        blue: u8,
    }

    fun new(red: u8, green: u8, blue: u8, ctx: &mut TxContext): ColorObject {
        ColorObject {
            id: object::new(ctx),
            red,
            green,
            blue,
        }
    }

    public entry fun create(red: u8, green: u8, blue: u8, ctx: &mut TxContext) {
        let color_object = new(red, green, blue, ctx);
        transfer::transfer(color_object, tx_context::sender(ctx))
    }

    public fun get_color(self: &ColorObject): (u8, u8, u8) {
        (self.red, self.green, self.blue)
    }

    /// Copies the values of `from_object` into `into_object`.
    public entry fun copy_into(from_object: &ColorObject, into_object: &mut ColorObject) {
        into_object.red = from_object.red;
        into_object.green = from_object.green;
        into_object.blue = from_object.blue;
    }

    public entry fun delete(object: ColorObject) {
        let ColorObject { id, red: _, green: _, blue: _ } = object;
        object::delete(id);
    }

    public entry fun transfer(object: ColorObject, recipient: address) {
        transfer::transfer(object, recipient)
    }

    public entry fun freeze_object(object: ColorObject) {
        transfer::freeze_object(object)
    }

    public entry fun create_shareable(red: u8, green: u8, blue: u8, ctx: &mut TxContext) {
        let color_object = new(red, green, blue, ctx);
        transfer::share_object(color_object)
    }

    public entry fun create_immutable(red: u8, green: u8, blue: u8, ctx: &mut TxContext) {
        let color_object = new(red, green, blue, ctx);
        transfer::freeze_object(color_object)
    }

    public entry fun update(
        object: &mut ColorObject,
        red: u8, green: u8, blue: u8,
    ) {
        object.red = red;
        object.green = green;
        object.blue = blue;
    }
}
```

编译后调用：

1. 创建共享对象

```bash
sui client call \
  --function create_shareable \
  --module objects \
  --package ${package_id} \
  --args 1 2 3 --gas-budget 30000

# 结果输出
----- Transaction Effects ----
Status : Success
Created Objects:
  - ID: 0x3b25eba3bf836088b56bdfd36e39ec440db8bf59 , Owner: Shared
```

1. 创建不可变对象

```bash
sui client call \
  --function create_immutable \
  --module objects \
  --package ${package_id} \
  --args 1 2 3 --gas-budget 30000

# 结果输出
----- Transaction Effects ----
Status : Success
Created Objects:
  - ID: 0x88f8f210635af6503a8a07835ef12e147fa60aa3 , Owner: Immutable
```

1. 将对象放入某个地址下

```bash
sui client call \
  --function create \
  --module objects \
  --package ${package_id} \
  --args 1 2 3 --gas-budget 30000

# 结果输出
----- Transaction Effects ----
Status : Success
Created Objects:
  - ID: 0xf36144c71cde87c1e00f1bf00ee44653bc05228c , Owner: Account Address ( 0xf28e73e59f2305edf4df88756f78fa1f5d7e78b0 )
```

可以看到，不同所有权类型的对象会在创建时显示不同的类型结果。

1. 修改共享对象或者是地址所拥有的对象：传入对象 ID 作为参数

```bash
sui client call \
  --function update \
  --module objects \
  --package ${package_id} \
  --args 0x3b25eba3bf836088b56bdfd36e39ec440db8bf59 4 5 6 --gas-budget 30000

# 结果输出
----- Transaction Effects ----
Status : Success
Mutated Objects:
  - ID: 0x3b25eba3bf836088b56bdfd36e39ec440db8bf59 , Owner: Shared
```

可以在结果中看到 `Mutated Objects` 中对象已经发生了变化。

### Dynamic field 和 Dynamic object field

对象虽然可以进行包装，但是也有一些局限，一是对象中的字段是有限的，在结构体定义是已经确定；二是包含其他对象的对象可能非常大，可能会导致交易 gas 很高，Sui 默认结构体大小限制为 2MB；再者，当遇到要储存不一样类型的对象集合时，问题就会比较棘手，Move 中的 `vector` 只能存储相同的类型的数据。

因此，Sui 提供了 dynamic field，可以使用任意名字做字段，也可以动态添加和删除。唯一影响的是 gas 的消耗。

dynamic field 包含两种类型，field 和 Object field，区别在于，field 可以存储任何有 `store` 能力的值，但是如果是对象的话，对象会被认为是被包装而不能通过 ID 被外部工具（浏览器，钱包等）访问；而 Object field 的值必须是对象（有 `key` 能力且第一个字段是 `id: UID`），对象仍然能从外部工具通过 ID 访问。

dynamic filed 的名称可以是任何拥有 `copy`，`drop` 和 `store` 能力的值，这些值包括 Move 中的基本类型（整数，布尔值，字节串），以及拥有 `copy`，`drop` 和 `store` 能力的结构体。

下面我们通过例子来看看具体的操作：

- 添加字段： `add`
- 访问和修改字段： `borrow`， `borow_mut`
- 删除字段

```rust
module ds::fields {
    use sui::object::{Self, UID};
    use sui::dynamic_object_field as dof;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct Parent has key {
        id: UID,
    }

    struct Child has key, store {
        id: UID,
        count: u64,
    }

    public entry fun initialize(ctx: &mut TxContext) {
        transfer::transfer(Parent { id: object::new(ctx) }, tx_context::sender(ctx));
        transfer::transfer(Child { id: object::new(ctx), count: 0 }, tx_context::sender(ctx));
    }

    public entry fun add_child(parent: &mut Parent, child: Child) {
        dof::add(&mut parent.id, b"child", child);
    }

    public entry fun mutate_child(child: &mut Child) {
        child.count = child.count + 1;
    }

    public entry fun mutate_child_via_parent(parent: &mut Parent) {
        mutate_child(dof::borrow_mut<vector<u8>, Child>(
            &mut parent.id,
            b"child",
        ));
    }

    public entry fun delete_child(parent: &mut Parent) {
        let Child { id, count: _ } = dof::remove<vector<u8>, Child>(
            &mut parent.id,
            b"child",
        );
        object::delete(id);
    }

    public entry fun reclaim_child(parent: &mut Parent, ctx: &mut TxContext) {
        let child = dof::remove<vector<u8>, Child>(
            &mut parent.id,
            b"child",
        );
        transfer::transfer(child, tx_context::sender(ctx));
    }
}
```

编译并调用 `initialize` 和 `add_child` 方法：

```bash
sui client call \
  --function initialize \
  --module fields \
  --package ${package_id} \
  --gas-budget 30000

# 输出结果
----- Transaction Effects ----
Status : Success
Created Objects:
  - ID: 0x55536ca8123ffb606398da9f7d2472888ca5bfd1 , Owner: Account Address ( 0xf28e73e59f2305edf4df88756f78fa1f5d7e78b0 )
  - ID: 0xf1206f0f7d97908aae907c23d69a4cd97120dc82 , Owner: Account Address ( 0xf28e73e59f2305edf4df88756f78fa1f5d7e78b0 )
```

```bash
sui client call \
  --function add_child \
  --module fields \
  --package ${package_id} \
  --args 0xf1206f0f7d97908aae907c23d69a4cd97120dc82 0x55536ca8123ffb606398da9f7d2472888ca5bfd1 --gas-budget 30000

# 输出结果
----- Transaction Effects ----
Status : Success
Created Objects:
  - ID: 0xdf694f282f739f328325bc922b3083bd45f31cae , Owner: Object ID: ( 0xf1206f0f7d97908aae907c23d69a4cd97120dc82 )
Mutated Objects:
  - ID: 0x55536ca8123ffb606398da9f7d2472888ca5bfd1 , Owner: Object ID: ( 0xdf694f282f739f328325bc922b3083bd45f31cae )
  - ID: 0xf1206f0f7d97908aae907c23d69a4cd97120dc82 , Owner: Account Address ( 0xf28e73e59f2305edf4df88756f78fa1f5d7e78b0 )
```

可以通过 `sui_getDynamicFields` 方法查看添加的字段：

```bash
curl -H 'Content-Type: application/json' https://fullnode.devnet.sui.io:443 -d '{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "sui_getDynamicFields",
  "params":[
      "0xf1206f0f7d97908aae907c23d69a4cd97120dc82"
  ]
}'
```

结果：

```json
{
    "jsonrpc": "2.0",
    "result": {
        "data": [
            {
                "name": "vector[99u8, 104u8, 105u8, 108u8, 100u8]",
                "type": "DynamicObject",
                "objectType": "0xee2961ee26916285ebef57c68caaa5f67a3d8dbd::fields::Child",
                "objectId": "0x55536ca8123ffb606398da9f7d2472888ca5bfd1",
                "version": 1621,
                "digest": "GNSaPghN+tRBkxKiVhQCn9jVBkjYV4RU4oF+c4CUGJM="
            }
        ],
        "nextCursor": null
    },
    "id": 1
}
```

其中 `name` 为 `“child”` 。同时，对于对象 ID `0x55536ca8123ffb606398da9f7d2472888ca5bfd1`，我们仍然能从链上追踪对应信息。

```bash
curl -H 'Content-Type: application/json' https://fullnode.devnet.sui.io:443 -d '{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "sui_getObject",
  "params":[
      "0x55536ca8123ffb606398da9f7d2472888ca5bfd1"
  ]
}'
```

### 集合数据类型

接下来，我们介绍几种基于 dynamic field 的集合数据类型。

前面介绍过，带有 dynamic field 的对象可以被删除，但是这对于链上集合类型来说这是不希望发生的，因为链上集合类型可能将无限多的键值对作为 dynamic field 保存。因此，在 Sui 提供了两种集合类型： `Table` 和 `Bag`，两者都基于 dynamic field 构建的映射类型的数据结构，但是额外支持计算它们包含的条目数，并防止在非空时意外删除。

`Table` 和 `Bag` 的区别在于，Table 是同质（*homogeneous）*映射，所以的键必须是同一个类型，所以的值也必须是同一个类型，而 Bag 是异质（*heterogeneous*）映射，可以存储任意类型的键值对。

同时，Sui 标准库中还包含对象版本的 `Table` 和 `Bag`： `ObjectTable` 和 `ObjectBag`，区别在于前者可以将任何 `store` 能力的值保存，但从外部存储查看时，作为值存储的对象将被隐藏，后者只能将对象作为值存储，但可以从外部存储中通过 ID 访问这些对象。

与之前介绍过的 `vec_map` 相比，`table` 更适合用来处理包含大量映射的情况。

### Table

下面我们通过示例来展示对 table 的基本操作：

- 添加元素： `add`
- 读取和修改元素： `borrow`，`borrow_mut`
- 删除元素： `delete`
- 元素长度： `length`
- 判断存在性：`contains`

Object table 的操作与 table 类似。

```rust
module ds::tables {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};

    const EChildAlreadyExists: u64 = 0;
    const EChildNotExists: u64 = 1;

    struct Parent has key {
        id: UID,
        children: Table<u64, Child>,
    }

    struct Child has key, store {
        id: UID,
        age: u64
    }
    // 创建 Parent 对象
    public entry fun initialize(ctx: &mut TxContext) {
        transfer::transfer(
            Parent { id: object::new(ctx), children: table::new(ctx) },
            tx_context::sender(ctx)
        );
    }

    public fun child_age(child: &Child): u64 {
        child.age
    }
    // 查看
    public fun child_age_via_parent(parent: &Parent, index: u64): u64 {
        assert!(!table::contains(&parent.children, index), EChildNotExists);
        table::borrow(&parent.children, index).age
    }
    // 获取长度
    public fun child_size_via_parent(parent: &Parent): u64 {
        table::length(&parent.children)
    }
    // 添加
    public entry fun add_child(parent: &mut Parent, index: u64, ctx: &mut TxContext) {
        assert!(table::contains(&parent.children, index), EChildAlreadyExists);
        table::add(&mut parent.children, index, Child { id: object::new(ctx), value: 0 });
    }
    // 修改
    public fun mutate_child(child: &mut Child) {
        child.age = child.age + 1;
    }

    public entry fun mutate_child_via_parent(parent: &mut Parent, index: u64) {
        mutate_child(table::borrow_mut(&mut parent.children, index));
    }
    // 删除
    public entry fun delete_child(parent: &mut Parent, index: u64) {
        assert!(!table::contains(&parent.children, index), EChildNotExists);
        let Child { id, age: _ } = table::remove(
            &mut parent.children,
            index
        );
        object::delete(id);
    }
}
```

### Bag

Bag 的操作与 table 的操作接口类似：

- 添加元素： `add`
- 读取和修改元素： `borrow`，`borrow_mut`
- 删除元素： `delete`
- 元素长度： `length`
- 判断存在性：`contains`

这里我们仅展示添加不同类型的键值对。

`Object_bag` 的操作与 `bag` 类似。

```rust
module ds::bags {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::bag::{Self, Bag};

    const EChildAlreadyExists: u64 = 0;
    const EChildNotExists: u64 = 1;

    struct Parent has key {
        id: UID,
        children: Bag,
    }

    struct Child1 has key, store {
        id: UID,
        value: u64
    }

    struct Child2 has key, store {
        id: UID,
        value: u64
    }

    public entry fun initialize(ctx: &mut TxContext) {
        transfer::transfer(
            Parent { id: object::new(ctx), children: bag::new(ctx) },
            tx_context::sender(ctx)
        );
    }
    // 添加第一种类型
    public entry fun add_child1(parent: &mut Parent, index: u64, ctx: &mut TxContext) {
        assert!(bag::contains(&parent.children, index), EChildAlreadyExists);
        bag::add(&mut parent.children, index, Child1 { id: object::new(ctx), value: 0 });
    }
    // 添加第二种类型
    public entry fun add_child2(parent: &mut Parent, index: u64, ctx: &mut TxContext) {
        assert!(bag::contains(&parent.children, index), EChildAlreadyExists);
        bag::add(&mut parent.children, index, Child2 { id: object::new(ctx), value: 0 });
    }
}
```

### LinkedTable

`linked_table` 是另一种使用 dynamic field 实现的数据结构，它与 `table` 类似，除此之外，它还支持值的有序插入和删除。因此，除了 table  类似的基础操作方法，还包含 `front`，`back`，`push_front`，`push_back`，`pop_front`，`pop_back`等操作，对于每一个键，也可以通过 `prev` 和 `next` 获取前一个和后一个插入的键。

```rust
module ds::linked_tables {
    use sui::linked_table::{
        Self,
        push_front,
        push_back,
        borrow,
        borrow_mut,
        remove,
        pop_front,
        pop_back,
        contains,
        is_empty,
        destroy_empty
    };
    use sui::tx_context::TxContext;

    public entry fun simple_all_functions(ctx: &mut TxContext) {
        let table = linked_table::new(ctx);
        // 添加字段
        push_back(&mut table, b"hello", 0);
        push_back(&mut table, b"goodbye", 1);
        // [b"hello", b"goodbye"]
        // 检查是否存在
        assert!(contains(&table, b"hello"), 0);
        assert!(contains(&table, b"goodbye"), 0);
        assert!(!is_empty(&table), 0);
        // 修改
        *borrow_mut(&mut table, b"hello") = *borrow(&table, b"hello") * 2;
        *borrow_mut(&mut table, b"goodbye") = *borrow(&table, b"goodbye") * 2;
        // 检查修改之后的值
        assert!(*borrow(&table, b"hello") == 0, 0);
        assert!(*borrow(&table, b"goodbye") == 2, 0);
        // 插入头部
        push_front(&mut table, b"!!!", 2);
        // b"!!!", b"hello", b"goodbye"]
        // 在末尾添加
        push_back(&mut table, b"?", 3);
        // [b"!!!", b"hello", b"goodbye", b"?"]
        // 从头部弹出
        let (front_k, front_v) = pop_front(&mut table);
        assert!(front_k == b"!!!", 0);
        assert!(front_v == 2, 0);
        // 从中间删除
        assert!(remove(&mut table, b"goodbye") == 2, 0);
        // [b"hello", b"?"]
        // 从末尾删除
        let (back_k, back_v) = pop_back(&mut table);
        assert!(back_k == b"?", 0);
        assert!(back_v == 3, 0);
        // 移出值并检查
        assert!(remove(&mut table, b"hello") == 0, 0);
        // 检查不存在
        assert!(is_empty(&table), 0);
        destroy_empty(table);
    }
}
```

### TableVec

最后，我们介绍一种基于 `table` 的数据结构 `table_vec`。从名字就可以看出，`table_vec` 是使用 `table` 实现的可扩展 `vector`，它使用元素在 `vector` 的索引作为 `table` 中的键进行存储。`table_vec` 提供了与 `vector` 类似的操作方法。

```rust
module ds::table_vecs {
    use sui::table_vec;
    use sui::tx_context::TxContext;

    public entry fun example(ctx: &mut TxContext) {
        let vec = table_vec::singleton<u64>(1, ctx);

        table_vec::push_back(&mut vec, 2);
        assert!(table_vec::length(&vec) == 2, 0);

        let v = table_vec::borrow_mut(&mut vec, 1);
        *v = 3;

        assert!(table_vec::pop_back(&mut vec) == 3, 1);
        assert!(table_vec::pop_back(&mut vec) == 1, 1);

        assert!(table_vec::is_empty(&vec), 2);
        table_vec::destroy_empty(vec);
    }
}
```

编译并运行示例：

```bash
sui client call \
  --function example \
  --module table_vecs \
  --package ${package_id} \
  --gas-budget 30000
```

至此，我们介绍完了 Sui Move 中主要的数据类型及其使用方法，希望大家学习和理解 Sui Move 有一定的帮助。
