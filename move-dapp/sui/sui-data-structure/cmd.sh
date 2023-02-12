
# deploy
sui client publish . --gas-budget 300000
# get package id and set it as env
export package_id=0xee2961ee26916285ebef57c68caaa5f67a3d8dbd

# example 类的调用，例如
sui client call \
  --function example \
  --module vectors \
  --package ${package_id} \
  --gas-budget 30000

# String
sui client call \
  --function issue_name_nft \
  --module strings \
  --package ${package_id} \
  --args "my_nft" --gas-budget 30000

# Object

sui client call \
  --function create_shareable \
  --module objects \
  --package ${package_id} \
  --args 1 2 3 --gas-budget 30000

sui client call \
  --function create_immutable \
  --module objects \
  --package ${package_id} \
  --args 1 2 3 --gas-budget 30000

sui client call \
  --function create \
  --module objects \
  --package ${package_id} \
  --args 1 2 3 --gas-budget 30000

sui client call \
  --function update \
  --module objects \
  --package ${package_id} \
  --args 0x3b25eba3bf836088b56bdfd36e39ec440db8bf59 4 5 6 --gas-budget 30000

# Dynamic object field

sui client call \
  --function initialize \
  --module fields \
  --package ${package_id} \
  --gas-budget 30000

sui client call \
  --function add_child \
  --module fields \
  --package ${package_id} \
  --args 0xb402093a6872eaec60823be5b1ad504529896246 0xf6f2220afc88897416d669023e4c821bb06896f7 --gas-budget 30000
