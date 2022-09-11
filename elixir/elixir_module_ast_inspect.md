# Elixir 模块 AST（抽象语法树）分析

一天，我拿到一个需求，要从 Elixir 模块中抽取公开的函数信息。一开始我根本不知道该怎么做。后来发现这次经历还是蛮有意思的。

## 通过文档

任何学习 Elixir 这门语言的人应该都对 Hex Docs 非常熟悉。因此，我的第一反应是看看它是怎么实现的，因为文档正是通过获取函数签名和源文件上的标注来生成的。查阅 Elixir 的 API 文档发现，`Code.fetch_docs` 这个函数就直接可以帮我获取到源文件里面标注的注释了。

```elixir
{:docs_v1, _, _, _, %{"en" => module_doc}, _meta, doc_elements} = Code.fetch_docs(module_or_path)
```

_备注: 如果提供的是文件名，它必须是已经从源文件中编译而来，而不是直接在 Livebook 中实时编译的。原因在[这里](https://elixirforum.com/t/what-is-the-module-name-compiled-in-livebook/49968/2?u=thinkingincrowd)。_

`doc_elements` 变量包含了大部分我需要获取的信息了：函数的签名，和文档内容。但是，因为我的一个公开的函数 `get_best_block_height/2` 拥有多个实现，而文档只能标注一份。所以，使用 `Code.fetch_docs` 并不能完全满足我的需求。那要怎么办呢？

```elixir
[
  {{:function, :get_best_block_height, 1}, 35, ["get_best_block_height(endpoint)"],
   %{
     "en" => "Get best **block height** of Ethereum-type network from given endpoint\n"
   }, %{}},
  {{:function, :get_best_block_height, 2}, 14, ["get_best_block_height(network, endpoint)"],
   %{
     "en" =>
       "Get best **block height** from given endpoint of either:\n* Ethereum\n* Arweave\n\nNot implemented for BTC yet\n"
   }, %{}},
  {{:function, :get_module_doc, 0}, 9, ["get_module_doc()"], %{"en" => "Get module doc\n"}, %{}}
]
```

## 通过 AST（Abstract Syntax Tree）

我相信，任何一个有些许编程经验的老码农，或者正规的计算机科班学生，应该都听说过 AST（Abstract Syntax Tree）。抽象语法树，是广泛用于编译器中，表达程序代码的一种数据结构。

Elixir 作为一种拥有强大的元编程（Meta-programming）能力的语言，它的肯定能利用 AST 来实现我的需求。上面的 `Code.fetch_docs` 应该也是基于此的。我一开始没探寻这个方向，其实是因为在面对这一个和语言编译这种听起来就高深复杂的东西上，内心还是有一点畏惧的。

但是，我后来发现，它其实并没有想象中那么复杂，至少在完成我需要完成的任务上。根据 Elixir 的[官方文档](https://hexdocs.pm/elixir/syntax-reference.html#the-elixir-ast)：

> The building block of Elixir's AST is a call, such as:
> 
> ```elixir
> sum(1, 2, 3)
> ```
> 
> which is represented as a tuple with three elements:
> 
> ```elixir
> {:sum, meta, [1, 2, 3]}
> ```
> 
> the first element is an atom (or another tuple), the second element is a list of two-element tuples with metadata (such as line numbers) and the third is a list of arguments.
> 
> We can retrieve the AST for any Elixir expression by calling quote:
> 
> ```elixir
> quote do
>   sum()
> end
> #=> {:sum, [], []}
> ```

可以看出，对简单的语句调用，如何生成，和理解它对应的 AST 其实并不难，甚至可以说很简单。那如何获取一个 Elixir 模块的完成的 AST 呢？这到是花了我一点时间。因为简单地用 `quote` 的方式是不行的。我们需要加载源文件，使用这种方式：

```elixir
source_path |> File.read!() |> Code.string_to_quoted()
```

### 模块的 AST 结构

通过比较 Elixir 源代码和生成的 AST 数据结构，整个模块的 AST 其实也是符合上面文档展示出来的基本结构的。一个模块的定义其实也是 `:defmodule` 宏的调用。它的参数列表包含了一个别名和 `do` 代码块：

```elixir
{:defmodule, [line: 1],
 [
   {:__aliases__, [line: 1], [:BestBlockHeightGetter]},
   [
     do: {:__block__, [], []}
   ]
 ]}
```

### 代码块的 AST 结构

代码块的 AST 清晰地展示出，它的参数列表包含了每一个属性（以 `:@` 开头），和函数（以 `:def` 开头）。

### 函数的 AST 结构

函数的 AST 结构是我需要关注的重点。可以看到，对于一个没有 `guard` 的简单函数：

* 如果没有任何参数，比如 `get_module_doc` 函数（`[line: 12]`），它的参数列表就是 `nil`。
* 如果有参数，比如 `get_best_block_height` 函数（`[line: 26]`，`[line: 31]` 和 `[line: 39]`），它的参数要么就是一个常量，或者一个单独的 AST 了。

当然，如果这个函数有 `guard` 的时候，它的结构看起来会比较复杂，但是其实仔细分辨的话，还是能认出它的 AST 是怎样的。

```elixir
# get_module_doc
{:def, [line: 12],
 [
   {:get_module_doc, [line: 12], nil},
   [do: {:@, [line: 12], [{:moduledoc, [line: 12], nil}]}]
 ]}

# get_best_block_height
{:def, [line: 26],
 [
   {:get_best_block_height, [line: 26],
    ["ethereum", {:\\, [line: 26], [{:endpoint, [line: 26], nil}, "eth"]}]},
   [
     do: {:__block__, [], []}
   ]
 ]}

{:def, [line: 26],
 [
   {:get_best_block_height, [line: 31], ["arweave", {:endpoint, [line: 26], nil}]},
   [
     do: {:__block__, [], []}
   ]
 ]}

{:def, [line: 39],
 [
   {:get_best_block_height, [line: 39], [{:endpoint, [line: 39], nil}]},
   [
     do: {:__block__, [], []}
   ]
 ]}

# With Guards
{:def, [line: 22],
 [
   {:when, [line: 22],
    [
      {:get_best_block_height, [line: 22],
       [{:network, [line: 22], nil}, {:_endpoint, [line: 22], nil}]},
      {:==, [line: 22], [{:network, [line: 22], nil}, "btc"]}
    ]},
   [do: {:-, [line: 23], [1]}]
 ]}
```

所以，其实基于生成的 AST，我其实能通过以下代码片段获取所有公开的函数签名（我知道在处理 `when` 的方式上是有点丑陋 :P）。

```elixir
{:ok, {:defmodule, _meta, [_, [do: {:__block__, _, block_statements}]]}} =
  source_file_path |> File.read!() |> Code.string_to_quoted()

quote_arg = fn arg ->
  if is_binary(arg), do: "\"#{arg}\"", else: arg
end

parse_arg = fn arg ->
  case arg do
    {:\\, _, [{arg_name, _, _}, actual]} ->
      "#{arg_name} \\\\ #{quote_arg.(actual)}"

    {arg_name, _, _} ->
      arg_name

    _ ->
      quote_arg.(arg)
  end
end

block_statements
|> Enum.filter(fn statement ->
  case statement do
    {:def, _meta, _args} ->
      true

    _ ->
      false
  end
end)
|> Enum.map(fn {:def, _meta, [signature, _block]} ->
  signature
end)
|> Enum.map(fn fun_ast ->
  case fun_ast do
    {:when, _meta, [{fun_name, _, args}, {operator, _, [arg1, arg2]}]} ->
      "#{fun_name}(#{Enum.map(args, &parse_arg.(&1)) |> Enum.join(", ")}) when #{parse_arg.(arg1)} #{operator} #{parse_arg.(arg2)}"

    {fun_name, _meta, nil} ->
      "#{fun_name}()"

    {fun_name, _meta, args} ->
      "#{fun_name}(#{Enum.map(args, &parse_arg.(&1)) |> Enum.join(", ")})"
  end
end)
|> Enum.each(&IO.puts/1)
```

以上代码片段的输出：

```elixir
get_module_doc()
get_best_block_height(network, _endpoint) when network == "btc"
get_best_block_height("ethereum", endpoint \\ "eth")
get_best_block_height("arweave", endpoint)
get_best_block_height(endpoint)
```
