const std = @import("std");
const config = @import("build_options");
const raylib = @import("raylib");

const hot_reload = config.hot_reload;
const hr = if (hot_reload) @import("hot_reload.zig") else undefined;
const core = if (hot_reload) undefined else @import("core");

var game_update: *const fn (*anyopaque) callconv(.c) void =
    if (hot_reload) hr.game_update_stub else @ptrCast(&core.game_update);

const WindowFn = *const fn () callconv(.c) void;

pub fn main() !void {
    if (hot_reload) {
        try hr.init(&game_update);
    }

    const window_init: WindowFn = if (hot_reload) hr.lookup(WindowFn, "game_window_init") else @ptrCast(&core.game_window_init);
    const window_deinit: WindowFn = if (hot_reload) hr.lookup(WindowFn, "game_window_deinit") else @ptrCast(&core.game_window_deinit);
    const state: *anyopaque = if (hot_reload) hr.game_init() else core.game_init();

    window_init();
    defer window_deinit();

    while (!raylib.windowShouldClose()) {
        if (hot_reload) hr.try_reload(&game_update);
        game_update(state);
    }
}

test "main foo" {
    const c = @import("core");
    var st: c.State = .{};

    std.debug.print("Generation 0\n", .{});
    const mid: usize = @divFloor(c.GRID_SIZE, 2);
    st.game.set_group(&.{
        .{ .x = mid - 4, .y = mid },
        .{ .x = mid - 3, .y = mid },
        .{ .x = mid - 3, .y = mid + 1 },
        .{ .x = mid + 1, .y = mid + 1 },
        .{ .x = mid + 2, .y = mid + 1 },
        .{ .x = mid + 3, .y = mid + 1 },
        .{ .x = mid + 2, .y = mid - 1 },
    });
    st.game.show();
    std.debug.print("\n", .{});

    st.game.next_n(107);
    st.game.show();
}

test {
    if (!hot_reload) {
        _ = @import("core");
        std.testing.refAllDeclsRecursive(@This());
    }
}
