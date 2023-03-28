module testcoin::cnyw {
    use sui::coin::{Self, TreasuryCap, mint_and_transfer};
    use sui::transfer;
    use sui::tx_context::{TxContext, sender};

    use std:: option;

    //Wechat DIGICCY, named CNYW
    struct CNYW has drop {}

    //Decimal of Coin
    const DECIMALS: u8 = 9;

    fun init(witness: CNYW, ctx: &mut TxContext) {
        let (treasury, metadata) = coin::create_currency(
            witness,
            DECIMALS,
            b"CNYW",
            b"WeChet DIGICCY",
            b"Wechat Digital Currency CNYW",
            option::none(),
            ctx
        );
        transfer::freeze_object(metadata);
        transfer::share_object(treasury);
    }

    public entry fun mint_coin(cap: &mut TreasuryCap<CNYW>, amount: u64, ctx: &mut TxContext) {
        mint_and_transfer(cap, amount, sender(ctx), ctx);
    }
}
