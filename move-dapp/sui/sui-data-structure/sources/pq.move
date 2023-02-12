module ds::pq {
    use sui::priority_queue::{PriorityQueue, pop_max, create_entries, new, insert};

    fun check_pop_max(h: &mut PriorityQueue<u64>, expected_priority: u64, expected_value: u64) {
        let (priority, value) = pop_max(h);
        assert!(priority == expected_priority, 0);
        assert!(value == expected_value, 0);
    }

    public entry fun example() {
        let h = new(create_entries(vector[3, 1, 4, 2, 5, 2], vector[10, 20, 30, 40, 50, 60]));
        check_pop_max(&mut h, 5, 50);
        check_pop_max(&mut h, 4, 30);
        check_pop_max(&mut h, 3, 10);
        insert(&mut h, 7, 70);
        check_pop_max(&mut h, 7, 70);
        check_pop_max(&mut h, 2, 40);
        insert(&mut h, 0, 80);
        check_pop_max(&mut h, 2, 60);
        check_pop_max(&mut h, 1, 20);
        check_pop_max(&mut h, 0, 80);
    }
}