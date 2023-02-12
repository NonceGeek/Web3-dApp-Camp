module ds::structs {
    struct Point has copy, drop, store {
        x: u64,
        y: u64,
    }

    struct Circle has copy, drop, store {
        center: Point,
        radius: u64,
    }

    public fun new_point(x: u64, y: u64): Point {
        Point {
            x, y
        }
    }

    public fun point_x(p: &Point): u64 {
        p.x
    }

    public fun point_y(p: &Point): u64 {
        p.y
    }

    fun abs_sub(a: u64, b: u64): u64 {
        if (a < b) {
            b - a
        }
        else {
            a - b
        }
    }

    public fun dist_squared(p1: &Point, p2: &Point): u64 {
        let dx = abs_sub(p1.x, p2.x);
        let dy = abs_sub(p1.y, p2.y);
        dx * dx + dy * dy
    }

    public fun new_circle(center: Point, radius: u64): Circle {
        Circle { center, radius }
    }

    public fun overlaps(c1: &Circle, c2: &Circle): bool {
        let d = dist_squared(&c1.center, &c2.center);
        let r1 = c1.radius;
        let r2 = c2.radius;
        d * d <= r1 * r1 + 2 * r1 * r2 + r2 * r2
    }
}