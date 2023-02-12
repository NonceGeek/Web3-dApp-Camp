module ds::linked_tables {
    use sui::linked_table::{
        Self,
        push_front,
        push_back,
        borrow,
        borrow_mut,
        remove,
        pop_front,
        pop_back,
        contains,
        is_empty,
        destroy_empty
    };
    use sui::tx_context::TxContext;

    public entry fun example(ctx: &mut TxContext) {
        let table = linked_table::new(ctx);
        // add fields
        push_back(&mut table, b"hello", 0);
        push_back(&mut table, b"goodbye", 1);
        // [b"hello", b"goodbye"]
        // check they exist
        assert!(contains(&table, b"hello"), 0);
        assert!(contains(&table, b"goodbye"), 0);
        assert!(!is_empty(&table), 0);
        // mutate them
        *borrow_mut(&mut table, b"hello") = *borrow(&table, b"hello") * 2;
        *borrow_mut(&mut table, b"goodbye") = *borrow(&table, b"goodbye") * 2;
        // check the new value
        assert!(*borrow(&table, b"hello") == 0, 0);
        assert!(*borrow(&table, b"goodbye") == 2, 0);
        // add to the front
        push_front(&mut table, b"!!!", 2);
        // b"!!!", b"hello", b"goodbye"]
        // add to the back
        push_back(&mut table, b"?", 3);
        // [b"!!!", b"hello", b"goodbye", b"?"]
        // pop front
        let (front_k, front_v) = pop_front(&mut table);
        assert!(front_k == b"!!!", 0);
        assert!(front_v == 2, 0);
        // remove middle
        assert!(remove(&mut table, b"goodbye") == 2, 0);
        // [b"hello", b"?"]
        // pop back
        let (back_k, back_v) = pop_back(&mut table);
        assert!(back_k == b"?", 0);
        assert!(back_v == 3, 0);
        // remove the value and check it
        assert!(remove(&mut table, b"hello") == 0, 0);
        // verify that they are not there
        assert!(is_empty(&table), 0);
        destroy_empty(table);
    }
}