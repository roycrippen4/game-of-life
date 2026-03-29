//! The game of life "engine".
const std = @import("std");

const SIZE = @import("UI.zig").GRID_SIZE;
const util = @import("util.zig");
const RingBuffer = util.RingBuffer;

const Point = struct { x: usize, y: usize };

/// Simulation related state
const Sim = struct {
    const Self = @This();

    frame_speed: u16 = 8,
    frame_counter: u16 = 0,
    running: bool = false,
};

const GameState = [SIZE][SIZE]bool;

/// Game of life cell-state
const Game = struct {
    const Self = @This();
    const default: GameState = @splat(@splat(false));

    current: GameState = default,
    temp: GameState = default,
    history: RingBuffer(GameState, 100) = .{},

    fn is_alive(self: Self, x: isize, y: isize) bool {
        if (x < 0 or y < 0 or x >= SIZE or y >= SIZE) return false;
        return self.current[@intCast(y)][@intCast(x)];
    }

    fn get_live_nbor_count(self: Self, point: Point) usize {
        const x: isize = @intCast(point.x);
        const y: isize = @intCast(point.y);

        const nbors: [8]bool = .{
            self.is_alive(x - 1, y - 1),
            self.is_alive(x, y - 1),
            self.is_alive(x + 1, y - 1),
            self.is_alive(x - 1, y),
            self.is_alive(x + 1, y),
            self.is_alive(x - 1, y + 1),
            self.is_alive(x, y + 1),
            self.is_alive(x + 1, y + 1),
        };

        var count: usize = 0;
        for (nbors) |nbor| if (nbor) {
            count += 1;
        };
        return count;
    }

    pub fn set(self: *Self, point: Point) void {
        self.current[point.y][point.x] = !self.current[point.y][point.x];
    }

    pub fn set_group(self: *Self, points: []const Point) void {
        for (points) |point| self.set(point);
    }

    pub fn clear(self: *Self) void {
        self.current = .default;
    }

    pub fn next(self: *Self) void {
        self.history.push(self.current);
        self.temp = default;

        for (1..SIZE - 1) |x| for (1..SIZE - 1) |y| {
            const nbor_count = self.get_live_nbor_count(.{ .x = x, .y = y });
            const cell: bool = self.current[y][x];

            self.temp[y][x] =
                (cell and (nbor_count == 2 or nbor_count == 3)) or
                (!cell and nbor_count == 3);
        };

        self.current = self.temp;
    }

    pub fn prev(self: *Self) void {
        if (self.history.pop()) |previous| {
            self.current = previous;
        }
    }

    pub fn next_n(self: *Self, n: usize) void {
        for (0..n) |_| self.next();
    }

    pub fn show(self: Self) void {
        for (self.current) |row| {
            for (row) |cell| {
                const char: u8 = if (cell) '#' else '.';
                std.debug.print("{c}", .{char});
            }
            std.debug.print("\n", .{});
        }
    }
};

game: Game = .{},
sim: Sim = .{},
