module ds::fields {
    use sui::object::{Self, UID};
    use sui::dynamic_object_field as dof;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct Parent has key {
        id: UID
    }

    struct Child has key, store {
        id: UID,
        count: u64,
    }

    public entry fun initialize(ctx: &mut TxContext) {
        transfer::transfer(Parent { id: object::new(ctx) }, tx_context::sender(ctx));
        transfer::transfer(Child { id: object::new(ctx), count: 0 }, tx_context::sender(ctx));
    }

    public entry fun add_child(parent: &mut Parent, child: Child) {
        dof::add(&mut parent.id, b"child", child);
    }

    public entry fun mutate_child(child: &mut Child) {
        child.count = child.count + 1;
    }

    public entry fun mutate_child_via_parent(parent: &mut Parent) {
        mutate_child(dof::borrow_mut<vector<u8>, Child>(
            &mut parent.id,
            b"child",
        ));
    }

    public entry fun delete_child(parent: &mut Parent) {
        let Child { id, count: _ } = dof::remove<vector<u8>, Child>(
            &mut parent.id,
            b"child",
        );

        object::delete(id);
    }

    public entry fun reclaim_child(parent: &mut Parent, ctx: &mut TxContext) {
        let child = dof::remove<vector<u8>, Child>(
            &mut parent.id,
            b"child",
        );

        transfer::transfer(child, tx_context::sender(ctx));
    }
}
