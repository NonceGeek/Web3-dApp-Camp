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
