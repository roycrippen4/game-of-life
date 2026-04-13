//! The game of life "engine".
const std = @import("std");

const SIZE = @import("ui.zig").GRID_SIZE;
const RingBuffer = @import("ring_buffer.zig").RingBuffer;
const raylib = @import("raylib");

/// Simulation related state
pub const Sim = struct {
    const Self = @This();

    pub const min_fps: u16 = 3;
    pub const max_fps: u16 = 16;

    fcount: u16 = 0,
    fps: u16 = 8,
    running: bool = false,
};

const GameState = [SIZE][SIZE]bool;
var alive_buf: [SIZE * SIZE]raylib.Vector2 = undefined;

/// Game of life cell-state
const Game = struct {
    const Self = @This();
    pub const default: GameState = @splat(@splat(false));

    fn init() Self {
        return .{ .current = patterns.default.data };
    }

    current: GameState = default,
    temp: GameState = default,
    history: RingBuffer(GameState, 100) = .{},

    fn is_alive(self: Self, x: i32, y: i32) bool {
        if (x < 0 or y < 0 or x >= SIZE or y >= SIZE) return false;
        return self.current[@intCast(y)][@intCast(x)];
    }

    fn get_live_nbor_count(self: Self, vec: raylib.Vector2) usize {
        const x: i32 = @intFromFloat(vec.x);
        const y: i32 = @intFromFloat(vec.y);

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

    pub fn set(self: *Self, point: raylib.Vector2) void {
        const x: usize = @intFromFloat(point.x);
        const y: usize = @intFromFloat(point.y);
        self.current[y][x] = !self.current[y][x];
    }

    pub fn set_group(self: *Self, points: []const raylib.Vector2) void {
        for (points) |point| self.set(point);
    }

    pub fn load(self: *Self, points: []const raylib.Vector2) void {
        self.current = default;
        self.set_group(points);
    }

    pub fn clear(self: *Self) void {
        self.history.push(self.current);
        self.current = default;
    }

    pub fn next(self: *Self) void {
        self.history.push(self.current);
        self.temp = default;

        for (1..SIZE - 1) |x_usize| for (1..SIZE - 1) |y_usize| {
            const x: f32 = @floatFromInt(x_usize);
            const y: f32 = @floatFromInt(y_usize);
            const nbor_count = self.get_live_nbor_count(.{ .x = x, .y = y });
            const cell: bool = self.current[y_usize][x_usize];

            self.temp[y_usize][x_usize] =
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

    pub fn get_all_living(self: Self) []raylib.Vector2 {
        var index: usize = 0;

        for (0..self.current.len) |y| for (0..self.current[y].len) |x| {
            if (self.current[y][x]) {
                alive_buf[index] = .{
                    .x = @floatFromInt(x),
                    .y = @floatFromInt(y),
                };
                index += 1;
            }
        };

        return alive_buf[0..index];
    }
};

game: Game = .{},
sim: Sim = .{},

const patterns = @import("patterns/root.zig");

pub fn init() @This() {
    var self: @This() = .{};
    self.game.set_group(patterns.default.data);
    return self;
}
