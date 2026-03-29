const std = @import("std");

pub const RingBuffer = @import("ring_buffer.zig").RingBuffer;
pub const State = @import("State.zig");
pub const UI = @import("UI.zig");

pub const Point = struct { x: usize, y: usize };

pub export fn game_window_init() void {
    UI.init();
}

pub export fn game_window_deinit() void {
    UI.exit();
}

pub export fn game_init() *anyopaque {
    const state = std.heap.page_allocator.create(State) catch @panic("OOM");
    state.* = .{};
    const mid: usize = @divFloor(UI.GRID_SIZE, 2);
    state.game.set_group(&.{
        .{ .x = mid - 4, .y = mid },
        .{ .x = mid - 3, .y = mid },
        .{ .x = mid - 3, .y = mid + 1 },
        .{ .x = mid + 1, .y = mid + 1 },
        .{ .x = mid + 2, .y = mid + 1 },
        .{ .x = mid + 3, .y = mid + 1 },
        .{ .x = mid + 2, .y = mid - 1 },
    });
    return @ptrCast(state);
}

pub export fn game_update(state_opaque: *anyopaque) void {
    const state: *State = @ptrCast(@alignCast(state_opaque));
    UI.render(state);
}

test {
    _ = UI;
    _ = State;
}
