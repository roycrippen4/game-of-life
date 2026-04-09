const std = @import("std");

const GameUpdateFn = *const fn (*anyopaque) callconv(.c) void;
const GameInitFn = *const fn () callconv(.c) *anyopaque;

const LIB_SRC = "zig-out/lib/libcore.so";
const LIB_DEST_DIR = "zig-out/libs/";
const LIB_DEST = LIB_DEST_DIR ++ "libcore.so";

var lib: std.DynLib = undefined;
var old_mtime: std.Io.Timestamp = .{ .nanoseconds = 0 };

pub fn game_update_stub(_: *anyopaque) callconv(.c) void {}

pub fn init(io: std.Io, updateFn: *GameUpdateFn) !void {
    std.Io.Dir.cwd().createDir(io, LIB_DEST_DIR, .default_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
    try reload(io, false, updateFn);
}

pub fn lookup(comptime T: type, name: [:0]const u8) T {
    return lib.lookup(T, name) orelse @panic("symbol not found");
}

pub fn game_init() *anyopaque {
    return lookup(GameInitFn, "game_init")();
}

pub fn try_reload(io: std.Io, updateFn: *GameUpdateFn) void {
    const stat = std.Io.Dir.cwd().statFile(io, LIB_SRC, .{}) catch return;
    if (stat.mtime.nanoseconds > old_mtime.nanoseconds) {
        reload(io, true, updateFn) catch unreachable;
        old_mtime = stat.mtime;
    }
}

fn reload(io: std.Io, close: bool, updateFn: *GameUpdateFn) !void {
    if (close) lib.close();
    const cwd = std.Io.Dir.cwd();

    cwd.copyFile(LIB_SRC, cwd, LIB_DEST, io, .{}) catch |err| {
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
