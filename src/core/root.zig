const std = @import("std");

pub const patterns = @import("patterns/root.zig");
pub const State = @import("State.zig");
pub const ui = @import("ui.zig");

pub fn init(io: std.Io, arena: std.mem.Allocator, env: *std.process.Environ.Map) State {
    patterns.init(io, arena, env);
    ui.init();
    return .init();
}

test {
    _ = ui;
    _ = State;
    _ = patterns;
}
