module ds::bags {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::bag::{Self, Bag};

    const EChildAlreadyExists: u64 = 0;
    const EChildNotExists: u64 = 1;

    struct Parent has key {
        id: UID,
        children: Bag,
    }

    struct Child1 has key, store {
        id: UID,
        value: u64
    }

    struct Child2 has key, store {
        id: UID,
        value: u64
    }

    public entry fun initialize(ctx: &mut TxContext) {
        transfer::transfer(
            Parent { id: object::new(ctx), children: bag::new(ctx) },
            tx_context::sender(ctx)
        );
    }

    public entry fun add_child1(parent: &mut Parent, index: u64, ctx: &mut TxContext) {
        assert!(bag::contains(&parent.children, index), EChildAlreadyExists);
        bag::add(&mut parent.children, index, Child1 { id: object::new(ctx), value: 0 });
    }

    public entry fun add_child2(parent: &mut Parent, index: u64, ctx: &mut TxContext) {
        assert!(bag::contains(&parent.children, index), EChildAlreadyExists);
        bag::add(&mut parent.children, index, Child2 { id: object::new(ctx), value: 0 });
    }
}