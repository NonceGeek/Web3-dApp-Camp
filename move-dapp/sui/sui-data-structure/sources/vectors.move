module ds::vectors {
    use std::vector;

    public entry fun example() {
        let v = vector::empty<u64>();
        vector::push_back(&mut v, 5);
        vector::push_back(&mut v, 6);

        assert!(vector::contains(&mut v, &5), 42);

        let (exists, index) = vector::index_of(&mut v, &5);
        assert!(exists, 42);
        assert!(index == 0, 42);

        assert!(*vector::borrow(&v, 0) == 5, 42);
        assert!(*vector::borrow(&v, 1) == 6, 42);

        vector::swap(&mut v, 0, 1);

        assert!(vector::pop_back(&mut v) == 5, 42);
        assert!(vector::pop_back(&mut v) == 6, 42);
    }
}
