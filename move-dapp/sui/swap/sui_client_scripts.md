
# Simple sui swap

## Code Structure

    .
    ├── AMM-swap
    ├    └── liquidity
    ├            ├── generate_pool
    ├            ├── deposit_totally
    ├            ├── deposit_partly
    ├            ├── remove_liquidity_totally
    ├            ├── withdraw_out
    ├            ├── swap_x_to_y
    ├            └── swap_y_to_x 
    └── testcoin
           ├── cnya
           ├     └── mint_coin
           └── cnyw
                 └── mint_coin

## Command for testing

```bash
# coin Package, CNYA and CNYW and TreasuryCaps
$ COINPKG="0xd9eb033b75357d0cf9357345d549068a785c1dd2"
CNYA="0xd9eb033b75357d0cf9357345d549068a785c1dd2::cnya::CNYA"
CNYW="0xd9eb033b75357d0cf9357345d549068a785c1dd2::cnyw::CNYW"
CNYACAP="0x844f0d202fde33a7ffcdaef4630d9940e544871d"
CNYWCAP="0x89e86789a63c28a84f5c03fecc0003386cc66f82"

# mint CNYA
# sui 0.20.0 defect, need pass value as string to u64 in format of \"1\"
# waiting to MystenLab to resolve
$ sui client call --package $COINPKG \
                --module cnya \
                --function mint_coin \
                --gas-budget 10000 \
                --args $CNYACAP \"10000\"
# mint CNYW
$ sui client call --package $COINPKG \
                --module cnyw \
                --function mint_coin \
                --gas-budget 10000 \
                --args $CNYWCAP \"10000\"

# bank package
$ BANKPKG="0xc0867a5bd54ca0b9fbbb8d262c163f55ef6dcd4d"

# Create Pocket to store liquidity providers
$ sui client call --package $BANKPKG \
                  --module liquidity \
                  --function create_pocket \
                  --gas-budget 10000
                  
$ POCKETID="0xda24e769d0ff25abe354c63e2c3de91ca13a61e0"
                  
# Generate the pool to keep balance
$ sui client call --package $BANKPKG \
                --module liquidity \
                --function generate_pool \
                --gas-budget 10000 \
                --type-args $CNYA $CNYW
                
$ POOLID="0xf34afa449172a51d2933a5642c648ac690e169f1"

# Deposit all balance of CNYA and CNYB into Pool and get the LP
$ sui client call --package $BANKPKG\
                --module liquidity \
                --function deposit_totally \
                --gas-budget 10000 \
                --type-args $CNYA $CNYW \
                --args $POOLID \
                       0x35d0ba21a1283ac74d792fe8e366c2aa04790f10 \
                       0x13e617da1f19a74060ae675b193daa3ab2fb3e83 \
                       $POCKETID

# Deposit part of balance of CNYA and CNYW into Pool and get the LP
$ sui client call --package $BANKPKG \
                --module liquidity \
                --function deposit_partly \
                --gas-budget 10000 \
                --type-args $CNYA $CNYW \
                --args $POOLID \
                       '["0x745a51f5ef3ac9e9145bda044175d1ec1101df5c","0xbf267e927fde098e948bdbd38f5cda51059e90f1"]' \
                       '["0x51ce85d6da1e582bbec29a9ad510c9d8777da4be","0x87f08438c6b92f2cb48a5e4f43f364d7dc7cd58d"]' \
                       \"15000\" \"14000\" $POCKETID

# Withdraw all the balance from LP
$ sui client call --package $BANKPKG \
                --module liquidity \
                --function remove_liquidity_totally \
                --gas-budget 10000 \
                --type-args $CNYA $CNYW \
                --args $POOLID \
                       0x5d09ba5a1cc3bea11c2e2e8eff89c42409fcc670 \
                       $POCKETID

# Withdraw part of balance from LP
$ sui client call --package $BANKPKG \
                --module liquidity \
                --function withdraw_out \
                --gas-budget 10000 \
                --type-args $CNYA $CNYW \
                --args $POOLID \
                       '["0x8a130a1f9f1137a7bae329bf9861e7dcd9835bb3","0x9521753a2781194ab2e5bd4154904d4d75905eee"]' \
                       \"17000\" \"18000\" $POCKETID

# Swap Coin X to Coin Y
$ sui client call --package $BANKPKG \
                --module liquidity \
                --function swap_x_to_y \
                --gas-budget 10000 \
                --type-args $CNYA $CNYW \
                --args $POOLID \
                       '["0xfcaed55cbb6a2f85815867c711d8c6bd2037f1cc","0x60dabbe408386294c54fcb0fa235735db1289227"]' \
                       \"1000\"

# Swap Coin Y to Coin X
$ sui client call --package $BANKPKG \
                --module liquidity \
                --function swap_y_to_x \
                --gas-budget 10000 \
                --type-args $CNYA $CNYW \
                --args $POOLID \
                       '["0xfe70976e60273a495ac998e3bce3a02d35310fcb"]' \
                       \"500\"
```