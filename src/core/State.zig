//! The game of life "engine".
const std = @import("std");

const SIZE = @import("ui.zig").GRID_SIZE;
const RingBuffer = @import("ring_buffer.zig").RingBuffer;
const raylib = @import("raylib");

/// Simulation related state
pub const Sim = struct {
    const Self = @This();

    pub const min_fps: u16 = 1;
    pub const max_fps: u16 = 64;

    pub fn speed_up(self: *Self) void {
        self.fps = if (self.fps >= max_fps) max_fps else self.fps + 1;
    }

    pub fn slow_down(self: *Self) void {
        self.fps = if (self.fps <= min_fps) min_fps else self.fps - 1;
    }

    framecount: u16 = 0,
    fps: u16 = 8,
    running: bool = false,
};

const GameState = [SIZE][SIZE]bool;
var alive_buf: [SIZE * SIZE]raylib.Vector2 = undefined;

/// Click-and-drag paint stroke state
pub const Paint = struct {
    /// Sentinel = no cell touched yet this stroke
    pub const no_cell: usize = std.math.maxInt(usize);

    last_row: usize = no_cell,
    last_col: usize = no_cell,
    /// Value to write into every cell touched by the current stroke
    value: bool = false,
    /// True while the left mouse button is held and a stroke is in progress
    active: bool = false,
};

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
    paint: Paint = .{},

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

    pub fn end_stroke(self: *Self) void {
        self.paint.active = false;
        self.paint.last_row = Paint.no_cell;
        self.paint.last_col = Paint.no_cell;
    }

    pub fn handle_paint(self: *Self, row: usize, col: usize) void {
        if (raylib.isMouseButtonPressed(.left)) {
            self.paint.value = !self.current[row][col];
            self.current[row][col] = self.paint.value;
            self.paint.last_row = row;
            self.paint.last_col = col;
            self.paint.active = true;
            return;
        }

        if (!self.paint.active or !raylib.isMouseButtonDown(.left)) return;
        if (row == self.paint.last_row and col == self.paint.last_col) return;

        self.paint_line(self.paint.last_row, self.paint.last_col, row, col);
        self.paint.last_row = row;
        self.paint.last_col = col;
    }

    fn paint_line(self: *Self, r0: usize, c0: usize, r1: usize, c1: usize) void {
        var x0: i32 = @intCast(c0);
        var y0: i32 = @intCast(r0);
        const x1: i32 = @intCast(c1);
        const y1: i32 = @intCast(r1);
        const dx: i32 = @intCast(@abs(x1 - x0));
        const dy: i32 = -@as(i32, @intCast(@abs(y1 - y0)));
        const sx: i32 = if (x0 < x1) 1 else -1;
        const sy: i32 = if (y0 < y1) 1 else -1;
        var err: i32 = dx + dy;
        while (true) {
            self.current[@intCast(y0)][@intCast(x0)] = self.paint.value;
            if (x0 == x1 and y0 == y1) break;
            const e2 = 2 * err;
            if (e2 >= dy) {
                err += dy;
                x0 += sx;
            }
            if (e2 <= dx) {
                err += dx;
                y0 += sy;
            }
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
