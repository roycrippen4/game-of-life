const std = @import("std");
const core = @import("core");
const UI = core.UI;

pub fn main() !void {
    UI.init();
    var state: core.State = .{};
    const mid: usize = @divFloor(core.GRID_SIZE, 2);

    state.game.set_group(&.{
        .{ .x = mid - 4, .y = mid },
        .{ .x = mid - 3, .y = mid },
        .{ .x = mid - 3, .y = mid + 1 },
        .{ .x = mid + 1, .y = mid + 1 },
        .{ .x = mid + 2, .y = mid + 1 },
        .{ .x = mid + 3, .y = mid + 1 },
        .{ .x = mid + 2, .y = mid - 1 },
    });

    while (!UI.should_exit()) {
        UI.render(&state);
    }

    UI.exit();
}

test "main foo" {
    var state: core.LifeState = .{};

    std.debug.print("Generation 0\n", .{});
    const mid: usize = @divFloor(core.GRID_SIZE, 2);
    state.set_group(&.{
        .{ .x = mid - 4, .y = mid },
        .{ .x = mid - 3, .y = mid },
        .{ .x = mid - 3, .y = mid + 1 },
        .{ .x = mid + 1, .y = mid + 1 },
        .{ .x = mid + 2, .y = mid + 1 },
        .{ .x = mid + 3, .y = mid + 1 },
        .{ .x = mid + 2, .y = mid - 1 },
    });
    state.show();
    std.debug.print("\n", .{});

    state.next_n(107);
    state.show();
}

test {
    _ = core;
    std.testing.refAllDeclsRecursive(@This());
}
