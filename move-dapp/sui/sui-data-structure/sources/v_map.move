module ds::v_map {
    use sui::vec_map;
    use std::vector;

    public entry fun example() {
        let m = vec_map::empty();
        let i = 0;
        while (i < 10) {
            let k = i + 2;
            let v = i + 5;
            vec_map::insert(&mut m, k, v);
            i = i + 1;
        };
        assert!(!vec_map::is_empty(&m), 0);
        assert!(vec_map::size(&m) == 10, 1);
        let i = 0;
        // make sure the elements are as expected in all of the getter APIs we expose
        while (i < 10) {
            let k = i + 2;
            assert!(vec_map::contains(&m, &k), 2);
            let v = *vec_map::get(&m, &k);
            assert!(v == i + 5, 3);
            assert!(vec_map::get_idx(&m, &k) == i, 4);
            let (other_k, other_v) = vec_map::get_entry_by_idx(&m, i);
            assert!(*other_k == k, 5);
            assert!(*other_v == v, 6);
            i = i + 1;
        };
        // remove all the elements
        let (keys, values) = vec_map::into_keys_values(copy m);
        let i = 0;
        while (i < 10) {
            let k = i + 2;
            let (other_k, v) = vec_map::remove(&mut m, &k);
            assert!(k == other_k, 7);
            assert!(v == i + 5, 8);
            assert!(*vector::borrow(&keys, i) == k, 9);
            assert!(*vector::borrow(&values, i) == v, 10);

            i = i + 1;
        }
    }
}
