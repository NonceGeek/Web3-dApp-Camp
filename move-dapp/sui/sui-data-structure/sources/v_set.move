module ds::v_set {
    use sui::vec_set;
    use std::vector;

    public entry fun example() {
        let m = vec_set::empty();
        let i = 0;
        while (i < 10) {
            let k = i + 2;
            vec_set::insert(&mut m, k);
            i = i + 1;
        };
        assert!(!vec_set::is_empty(&m), 0);
        assert!(vec_set::size(&m) == 10, 1);
        let i = 0;
        // make sure the elements are as expected in all of the getter APIs we expose
        while (i < 10) {
            let k = i + 2;
            assert!(vec_set::contains(&m, &k), 2);
            i = i + 1;
        };
        // remove all the elements
        let keys = vec_set::into_keys(copy m);
        let i = 0;
        while (i < 10) {
            let k = i + 2;
            vec_set::remove(&mut m, &k);
            assert!(*vector::borrow(&keys, i) == k, 9);
            i = i + 1;
        }
    }
}
