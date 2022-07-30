# deploy
dev deploy [path to blob] -s [addr] -b
# call function incr
account execute-function --function 0x07Ffe973C72356C25e623E2470172A69::MyCounter::incr_counter -s 0x07Ffe973C72356C25e623E2470172A69 -b
# call function incr by
account execute-function --function 0x07Ffe973C72356C25e623E2470172A69::MyCounter::incr_counter_by --arg 3 -s 0x07Ffe973C72356C25e623E2470172A69 -b
# get resource
state get resource 0x07Ffe973C72356C25e623E2470172A69 0x07Ffe973C72356C25e623E2470172A69::MyCounter::Counter
