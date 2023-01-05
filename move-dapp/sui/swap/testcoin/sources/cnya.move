module testcoin::cnya {
    use sui::coin::{Self, TreasuryCap, mint_and_transfer};
    use sui::transfer;
    use sui::tx_context::{TxContext, sender};

    use std:: option;

    //Alipay DIGICCY, named CNYA
    struct CNYA has drop {}

    //Decimal of Coin
    const DECIMALS: u8 = 9;

    fun init(witness: CNYA, ctx: &mut TxContext) {
        let (treasury, metadata) = coin::create_currency(
            witness,
            DECIMALS,
            b"CNYA",
            b"Alipay DIGICCY",
            b"Alipay Digital Currency CNYA",
            option::none(),
            ctx
        );
        transfer::freeze_object(metadata);
        transfer::share_object(treasury);
    }

    public entry fun mint_coin(cap: &mut TreasuryCap<CNYA>, amount: u64, ctx: &mut TxContext) {
        mint_and_transfer(cap, amount, sender(ctx), ctx);
    }
}
