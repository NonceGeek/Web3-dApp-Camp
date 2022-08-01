# deploy
dev deploy [path to blob] -s [addr] -b
dev deploy /Users/cjf/Documents/bc/Web3-dApp-Camp/move-dapp/my-library/release/my_library.v0.0.3.blob -s 0x07ffe973c72356c25e623e2470172a69 -b
# call function init library
account execute-function --function 0x07Ffe973C72356C25e623E2470172A69::MyLibrary::init_library -s 0x07Ffe973C72356C25e623E2470172A69 -b
# get library
state get resource 0x07Ffe973C72356C25e623E2470172A69 0x07Ffe973C72356C25e623E2470172A69::MyLibrary::Library
# add book
account execute-function --function 0x07Ffe973C72356C25e623E2470172A69::MyLibrary::s_add_book --arg b"web3" --arg b"github.com" -s 0x07Ffe973C72356C25e623E2470172A69 -b
# update book at index
account execute-function --function 0x07Ffe973C72356C25e623E2470172A69::MyLibrary::s_update_book_at_id --arg 0 --arg b"atest" --arg b"noncegeck.com" -s 0x07Ffe973C72356C25e623E2470172A69 -b
# delete book at index
account execute-function --function 0x07Ffe973C72356C25e623E2470172A69::MyLibrary::s_add_book --arg b"web3" --arg b"github.com" -s 0x07Ffe973C72356C25e623E2470172A69 -b
