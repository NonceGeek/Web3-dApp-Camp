module ds::table_vecs {
    use sui::table_vec;
    use sui::tx_context::TxContext;

    public entry fun example(ctx: &mut TxContext) {
        let vec = table_vec::singleton<u64>(1, ctx);

        table_vec::push_back(&mut vec, 2);
        assert!(table_vec::length(&vec) == 2, 0);

        let v = table_vec::borrow_mut(&mut vec, 1);
        *v = 3;

        assert!(table_vec::pop_back(&mut vec) == 3, 1);
        assert!(table_vec::pop_back(&mut vec) == 1, 1);

        assert!(table_vec::is_empty(&vec), 2);
        table_vec::destroy_empty(vec);
    }
}