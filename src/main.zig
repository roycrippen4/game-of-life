const std = @import("std");

const core = @import("core");
const ui = core.ui;
const raylib = @import("raylib");

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const io = init.io;
    const env = init.environ_map;

    var state = core.init(io, arena, env);

    while (!raylib.windowShouldClose()) {
        try ui.render(io, arena, &state);
    }

    ui.exit();
}

test {
    _ = @import("core");
    std.testing.refAllDecls(@This());
}
