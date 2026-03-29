const std = @import("std");
const testing = std.testing;

const raylib = @import("raylib");

pub fn RingBuffer(comptime T: type, comptime N: usize) type {
    return struct {
        const Self = @This();

        buffer: [N]T = undefined,
        write_index: usize = 0,
        count: usize = 0,

        pub fn push(self: *Self, item: T) void {
            self.buffer[self.write_index] = item;
            self.write_index = @mod(self.write_index + 1, N);
            self.count = @min(self.count + 1, N);
        }

        pub fn pop(self: *Self) ?T {
            if (self.count == 0) return null;

            self.write_index = if (self.write_index == 0) N - 1 else self.write_index - 1;
            self.count -= 1;
            return self.buffer[self.write_index];
        }

        fn oldest_index(self: Self) usize {
            return if (self.count == N) self.write_index else 0;
        }

        fn physical_index(self: Self, logical_index: usize) usize {
            return @mod(self.oldest_index() + logical_index, N);
        }

        pub const Iterator = struct {
            ring_buffer: *const Self,
            current: ?usize = null,

            const IterSelf = @This();

            pub fn next(self: *IterSelf) ?T {
                if (self.ring_buffer.count == 0) return null;

                const next_index = if (self.current) |idx|
                    idx + 1
                else
                    0;

                if (next_index >= self.ring_buffer.count) return null;

                self.current = next_index;
                return self.ring_buffer.buffer[self.ring_buffer.physical_index(next_index)];
            }

            pub fn prev(self: *IterSelf) ?T {
                if (self.ring_buffer.count == 0) return null;

                const curr = self.current orelse return null;
                if (curr == 0) {
                    self.current = null;
                    return null;
                }

                const prev_index = curr - 1;
                self.current = prev_index;
                return self.ring_buffer.buffer[self.ring_buffer.physical_index(prev_index)];
            }
        };

        pub fn iterator(self: *const Self) Iterator {
            return .{
                .ring_buffer = self,
                .current = null,
            };
        }
    };
}

pub const rect = struct {
    pub fn contains(r: raylib.Rectangle, other: raylib.Vector2) bool {
        return other.x >= r.x and
            other.y >= r.y and
            other.x < r.x + r.width and
            other.y < r.y + r.height;
    }

    pub fn as_horizontal_line(r: raylib.Rectangle, color: raylib.Color) void {
        const from: raylib.Vector2 = .{
            .x = r.x,
            .y = r.y,
        };
        const to: raylib.Vector2 = .{
            .x = r.x + r.width,
            .y = r.y,
        };
        raylib.drawLineV(from, to, color);
    }

    pub fn as_vertical_line(r: raylib.Rectangle, color: raylib.Color) void {
        const from: raylib.Vector2 = .{
            .x = r.x,
            .y = r.y,
        };
        const to: raylib.Vector2 = .{
            .x = r.x,
            .y = r.y + r.height,
        };
        raylib.drawLineV(from, to, color);
    }

    /// computes the center of the rectangle
    pub fn get_center(r: raylib.Rectangle) raylib.Vector2 {
        return .{
            .x = r.x + (r.width / 2),
            .y = r.y + (r.height / 2),
        };
    }
    test "util.rect get_center" {
        const r: raylib.Rectangle = .{
            .x = 15,
            .y = 20,
            .width = 10,
            .height = 5,
        };

        const expected: raylib.Vector2 = .{ .x = 20, .y = 22.5 };
        const result = get_center(r);
        try testing.expectEqual(expected.x, result.x);
        try testing.expectEqual(expected.y, result.y);
    }

    pub fn get_origin_vector(r: raylib.Rectangle) raylib.Vector2 {
        return .{
            .x = r.x,
            .y = r.y,
        };
    }
};

test "ring_buffer push" {
    var ring_buffer = RingBuffer(u32, 3){};

    try testing.expectEqual(0, ring_buffer.write_index);
    try testing.expectEqual(0, ring_buffer.count);

    ring_buffer.push(10);
    try testing.expectEqual(1, ring_buffer.write_index);
    try testing.expectEqual(1, ring_buffer.count);
    try testing.expectEqual(10, ring_buffer.buffer[0]);

    ring_buffer.push(20);
    try testing.expectEqual(2, ring_buffer.write_index);
    try testing.expectEqual(2, ring_buffer.count);
    try testing.expectEqual(20, ring_buffer.buffer[1]);

    ring_buffer.push(30);
    try testing.expectEqual(0, ring_buffer.write_index);
    try testing.expectEqual(3, ring_buffer.count);
    try testing.expectEqual(30, ring_buffer.buffer[2]);

    ring_buffer.push(40);
    try testing.expectEqual(1, ring_buffer.write_index);
    try testing.expectEqual(3, ring_buffer.count);
    try testing.expectEqual(40, ring_buffer.buffer[0]);
}

test "ring_buffer pop" {
    var ring_buffer = RingBuffer(u32, 3){};

    try testing.expectEqual(null, ring_buffer.pop());

    ring_buffer.push(10);
    ring_buffer.push(20);
    ring_buffer.push(30);

    try testing.expectEqual(@as(?u32, 30), ring_buffer.pop());
    try testing.expectEqual(2, ring_buffer.write_index);
    try testing.expectEqual(2, ring_buffer.count);

    try testing.expectEqual(@as(?u32, 20), ring_buffer.pop());
    try testing.expectEqual(1, ring_buffer.write_index);
    try testing.expectEqual(1, ring_buffer.count);

    try testing.expectEqual(@as(?u32, 10), ring_buffer.pop());
    try testing.expectEqual(0, ring_buffer.write_index);
    try testing.expectEqual(0, ring_buffer.count);

    try testing.expectEqual(null, ring_buffer.pop());
}

test "ring_buffer oldestIndex" {
    var ring_buffer = RingBuffer(u32, 3){};

    try testing.expectEqual(0, ring_buffer.oldest_index());

    ring_buffer.push(10);
    try testing.expectEqual(0, ring_buffer.oldest_index());

    ring_buffer.push(20);
    try testing.expectEqual(0, ring_buffer.oldest_index());

    ring_buffer.push(30);
    try testing.expectEqual(0, ring_buffer.oldest_index());

    ring_buffer.push(40);
    try testing.expectEqual(1, ring_buffer.oldest_index());

    ring_buffer.push(50);
    try testing.expectEqual(2, ring_buffer.oldest_index());

    ring_buffer.push(60);
    try testing.expectEqual(0, ring_buffer.oldest_index());
}

test "ring_buffer physical_index" {
    var ring_buffer = RingBuffer(u32, 3){};

    ring_buffer.push(10);
    ring_buffer.push(20);

    try testing.expectEqual(0, ring_buffer.physical_index(0));
    try testing.expectEqual(1, ring_buffer.physical_index(1));

    ring_buffer.push(30);
    ring_buffer.push(40);

    try testing.expectEqual(1, ring_buffer.physical_index(0));
    try testing.expectEqual(2, ring_buffer.physical_index(1));
    try testing.expectEqual(0, ring_buffer.physical_index(2));
}

test "ring_buffer iterator" {
    var ring_buffer = RingBuffer(u32, 3){};
    const it = ring_buffer.iterator();

    try testing.expectEqual(&ring_buffer, it.ring_buffer);
    try testing.expectEqual(null, it.current);
}

test "ring_buffer iterator.next" {
    var ring_buffer = RingBuffer(u32, 3){};
    var it = ring_buffer.iterator();

    try testing.expectEqual(null, it.next());

    ring_buffer.push(10);
    ring_buffer.push(20);
    ring_buffer.push(30);

    try testing.expectEqual(@as(?u32, 10), it.next());
    try testing.expectEqual(@as(?usize, 0), it.current);

    try testing.expectEqual(@as(?u32, 20), it.next());
    try testing.expectEqual(@as(?usize, 1), it.current);

    try testing.expectEqual(@as(?u32, 30), it.next());
    try testing.expectEqual(@as(?usize, 2), it.current);

    try testing.expectEqual(null, it.next());
    try testing.expectEqual(@as(?usize, 2), it.current);
}

test "ring_buffer iterator.next wrapped" {
    var ring_buffer = RingBuffer(u32, 3){};
    ring_buffer.push(10);
    ring_buffer.push(20);
    ring_buffer.push(30);
    ring_buffer.push(40);

    var it = ring_buffer.iterator();

    try testing.expectEqual(@as(?u32, 20), it.next());
    try testing.expectEqual(@as(?u32, 30), it.next());
    try testing.expectEqual(@as(?u32, 40), it.next());
    try testing.expectEqual(null, it.next());
}

test "ring_buffer iterator.prev" {
    var ring_buffer = RingBuffer(u32, 3){};
    ring_buffer.push(10);
    ring_buffer.push(20);
    ring_buffer.push(30);

    var it = ring_buffer.iterator();

    try testing.expectEqual(null, it.prev());

    try testing.expectEqual(@as(?u32, 10), it.next());
    try testing.expectEqual(@as(?u32, 20), it.next());

    try testing.expectEqual(@as(?u32, 10), it.prev());
    try testing.expectEqual(@as(?usize, 0), it.current);

    try testing.expectEqual(null, it.prev());
    try testing.expectEqual(null, it.current);
}

test "ring_buffer iterator.prev wrapped" {
    var ring_buffer = RingBuffer(u32, 3){};
    ring_buffer.push(10);
    ring_buffer.push(20);
    ring_buffer.push(30);
    ring_buffer.push(40);

    var it = ring_buffer.iterator();

    try testing.expectEqual(@as(?u32, 20), it.next());
    try testing.expectEqual(@as(?u32, 30), it.next());
    try testing.expectEqual(@as(?u32, 20), it.prev());
    try testing.expectEqual(null, it.prev());
}

test "ring_buffer iterator.next after prev reset" {
    var ring_buffer = RingBuffer(u32, 3){};
    ring_buffer.push(10);
    ring_buffer.push(20);
    ring_buffer.push(30);

    var it = ring_buffer.iterator();

    try testing.expectEqual(@as(?u32, 10), it.next());
    try testing.expectEqual(@as(?u32, 20), it.next());
    try testing.expectEqual(@as(?u32, 10), it.prev());
    try testing.expectEqual(null, it.prev());

    try testing.expectEqual(@as(?u32, 10), it.next());
    try testing.expectEqual(@as(?u32, 20), it.next());
    try testing.expectEqual(@as(?u32, 30), it.next());
}
