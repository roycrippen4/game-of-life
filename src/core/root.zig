const std = @import("std");

pub const patterns = @import("patterns/root.zig");
pub const State = @import("State.zig");
pub const ui = @import("ui.zig");

test {
    _ = ui;
    _ = State;
    _ = patterns;
}
