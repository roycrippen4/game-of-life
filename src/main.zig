const std = @import("std");

const core = @import("core");
const kf = @import("known-folders");
const nfd = @import("nfd");
const raylib = @import("raylib");

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    core.patterns.init(init.io, arena, init.environ_map);

    core.ui.init();
    defer core.ui.exit();

    var state: core.State = .{};
    state.game.set_group(core.patterns.default.data);

    while (!raylib.windowShouldClose()) {
        try core.ui.render(init.io, arena, &state);
    }
}

test {
    _ = @import("core");
    std.testing.refAllDecls(@This());
}
