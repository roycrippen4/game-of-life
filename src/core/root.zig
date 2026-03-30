const std = @import("std");

pub const State = @import("State.zig");
pub const ui = @import("ui.zig");
const raylib = @import("raylib");

pub const Points = []const raylib.Vector2;

pub const samples = struct {
    pub const default: Points = @import("samples/default.zon");
};

pub export fn game_window_init() void {
    ui.init();
}

pub export fn game_window_deinit() void {
    ui.exit();
}

pub export fn game_init() *anyopaque {
    const state = std.heap.page_allocator.create(State) catch @panic("OOM");
    state.* = .{};
    state.game.set_group(samples.default);
    return @ptrCast(state);
}

pub export fn game_update(state_opaque: *anyopaque) void {
    const state: *State = @ptrCast(@alignCast(state_opaque));
    ui.render(state);
}

test {
    _ = ui;
    _ = State;
}
