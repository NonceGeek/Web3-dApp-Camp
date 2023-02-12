module ds::strings {
    use sui::object::{Self, UID};
    use sui::tx_context::{sender, TxContext};
    use sui::transfer;

    // Use this dependency to get a type wrapper for UTF-8 strings
    use std::string::{Self, String};

    /// A dummy Object that holds a String type
    struct Name has key, store {
        id: UID,

        /// Here it is - the String type
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

    /// Create a name Object by passing raw bytes
    public entry fun issue_name_nft(
        name_bytes: vector<u8>, ctx: &mut TxContext
    ) {
        transfer::transfer(
            create_name(name_bytes, ctx),
            sender(ctx)
        );
    }
}
