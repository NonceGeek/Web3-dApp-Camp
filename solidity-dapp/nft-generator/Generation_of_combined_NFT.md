# 不同特征互相组合生成NFT
**该教程可帮助你使用不同特征的图层组合得到不同的图片NFT**
## 0x00 依赖
- Python
- Git（用于克隆仓库）
- Pip（Python的包管理程序）

## 0x01 准备工作
1. 将仓库`https://github.com/Solseum/solseum-nft-generator`克隆至本地，然后安装Python库
```bash
$ git clone https://github.com/Solseum/solseum-nft-generator
$ cd solseum-nft-generator
$ python3 -m pip install -r requeriments.txt
```
2. 删除`input/assets`文件夹中的原有内容
3. 将自己的特征图片按下层到上层的顺序新建文件夹
文件结构如下所示（其中需按照顺序以`序号-特征大类名字`的命名方式从`0-`开始到`8-`结束）：
```bash
├─input
│  ├─assets
│  │  ├─0-bg
│  │  ├─1-sc
│  │  ├─2-bd
│  │  ├─3-fc
│  │  ├─4-hs
│  │  ├─5-so
│  │  ├─6-of
│  │  ├─7-as
│  │  └─8-other
```
4. 将每一层的图片放入对应的文件夹中
文件结构如下所示（其中每一层图片需要保证宽度和高度一致且格式为PNG）：
每一层中图片的命名方式为`改特征小类所占该特征大类中的百分比-特征小类名`，其中总和需等于100
```bash
├─assets
│  ├─0-bg
│  │  ├─5-bg1.png
│  │  ├─15-bg2.png
│  │  ├─30-bg3.png
│  │  ├─50-bg3.png
│  ├─1-sc
│  ├─2-bd
│  ├─3-fc
│  ├─4-hs
│  ├─5-so
│  ├─6-of
│  ├─7-as
│  └─8-other
```
5. 修改配置文件`input/template.json`
```json
{
    "name": "Cute Squares", // NFT Collection的名字
    "symbol": "CS", // Symbol 简称
    "description": "Cutest squares on Solana Network!!", // 描述
    "seller_fee_basis_points": 500, // 500 表示5% 的版税, 1000 表示10%
    "image": "image.png",
    "external_url": "https://github.com/itherunder", // NFT 外部链接
    "attributes":
    [
    ],
    "collection":
    {
        "name": "Solana Cute Squares", // Collection名字
        "family": "Solseum NFT Generator" // NFT家族
    },
    "properties":
    {
        "files":
        [
            {
                "uri": "image.png", // 模板的uri，随便填就行
                "type": "image/png"
            }
        ],
        "category": "image",
        "creators":
        [
            {
                "address": "0x",
                "share": 100
            }
        ]
    }
}
```

## 0x02 创建NFT！
| 特性               | 命令行       | 描述                                                                                                                             | 栗子                                             |
| ------------------ | :----------- | -------------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------------- |
| 创建 公开的 NFTs   | **-p <*N*>** | 生成 *N* 个唯一的png+json ***[default=0]***                                                                                      | **`python3 main.py -p 800`**                     |
| 创建 白名单的 NFTs | **-w <*N*>** | 生成 *N* 个唯一的png+json ***[default=0]***                                                                                      | **`python3 main.py -w 300`**                     |
| 创建 赠品 NFTs     | **-g <*N*>** | 生成 *N* 个唯一的png+json ***[default=0]***                                                                                      | **`python3 main.py -g 100`**                     |
| 测试稀有性         | **-t 1**     | 生成一组样例 **-p <*N*>** + **-w <*N*>** + **-g <*N*>**，存储json以及稀有性的分布图，不会创建NFT，用于测试 ***[default=False]*** | **`python3 main.py -w 3333 -g 100 -t 1`**        |
| 随机 NFTs 输出     | **-r 1**     | 对整个NFT系列的输出进行随机排序，以允许不按特定顺序进行mint ***[default=False]***                                                | **`python3 main.py -p 2200 -w 578 -g 100 -r 1`** |

>可随意组合 **-p <*N*>**, **-w <*N*>** and **-g <*N*>**
>通过 **`python3 main.py -h`** 查看帮助信息
>最终生成的NFT个数最好不要超过每个图层中特征小类数量乘积的20%，即最大能够生成NFT个数的20%

## 0x03 结果&其他
结果图如下：
![image](https://user-images.githubusercontent.com/61953384/164873537-0ba21e32-3553-43ba-97d1-90daa87fa5a4.png)

>另外，如果想修改具体每张图片最终生成时的`json`描述，可在`includes/nft_creator.py`中`CreateNfts`函数进行修改
>如：将每个NFT的uri修改为其对应的uri
```python
nftMetadata['proproperties']['files'][0]['uri'] = 'https://.../' + str(self.nftsCreatedCounter+1) + '.png'`
```