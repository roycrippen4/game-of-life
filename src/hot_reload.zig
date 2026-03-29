const std = @import("std");

const GameUpdateFn = *const fn (*anyopaque) callconv(.c) void;
const GameInitFn = *const fn () callconv(.c) *anyopaque;

const LIB_SRC = "zig-out/lib/libcore.so";
const LIB_DEST_DIR = "zig-out/libs/";
const LIB_DEST = LIB_DEST_DIR ++ "libcore.so";

var lib: std.DynLib = undefined;
var old_mtime: i128 = 0;

pub fn game_update_stub(_: *anyopaque) callconv(.c) void {}

pub fn init(updateFn: *GameUpdateFn) !void {
    std.fs.cwd().makeDir(LIB_DEST_DIR) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
    try reload(false, updateFn);
}

pub fn lookup(comptime T: type, name: [:0]const u8) T {
    return lib.lookup(T, name) orelse @panic("symbol not found");
}

pub fn game_init() *anyopaque {
    return lookup(GameInitFn, "game_init")();
}

pub fn try_reload(updateFn: *GameUpdateFn) void {
    const stat = std.fs.cwd().statFile(LIB_SRC) catch return;
    if (stat.mtime > old_mtime) {
        reload(true, updateFn) catch unreachable;
        old_mtime = stat.mtime;
    }
}

fn reload(close: bool, updateFn: *GameUpdateFn) !void {
    if (close) lib.close();

    std.fs.cwd().copyFile(LIB_SRC, std.fs.cwd(), LIB_DEST, .{}) catch |err| {
        std.log.err("could not copy {s} to {s}: {}", .{ LIB_SRC, LIB_DEST, err });
        return err;
    };

    lib = std.DynLib.open(LIB_DEST) catch |err| {
        std.log.err("failed to open {s}: {}", .{ LIB_DEST, err });
        return err;
    };

    updateFn.* = lib.lookup(GameUpdateFn, "game_update") orelse @panic("symbol not found: game_update");
    std.log.info("hot-reloaded core", .{});
}
