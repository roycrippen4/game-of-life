const std = @import("std");

pub const Point = struct { x: usize, y: usize };
pub const GRID_SIZE: u32 = 30;
pub const State = @import("State.zig");
pub const UI = @import("UI.zig");

test {
    _ = UI;
    _ = State;
}
