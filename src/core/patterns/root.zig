const std = @import("std");
const Io = std.Io;
const Dir = Io.Dir;
const Allocator = std.mem.Allocator;
const Environ = std.process.Environ;

pub const default: Pattern = @import("default.zon");
pub const glider: Pattern = @import("glider.zon");

const filedialog = @import("filedialog");
const kf = @import("known-folders");
const raylib = @import("raylib");

pub const Pattern = struct {
    name: []const u8,
    data: []const raylib.Vector2,
};

pub const all = &[_]Pattern{
    default,
    glider,
};

/// global path to my data directory
var datapath: ?[]const u8 = null;
/// null-terminated variant of the same path
var datapathZ: ?[:0]const u8 = null;

/// Sets the global `gol_dir_path`
///
/// # WARNING!
/// This function should *only be called once*!
/// This function will panic if a valid path cannot be obtained
fn set_datapath(io: Io, arena: Allocator, env: *Environ.Map) void {
    std.debug.assert(datapath == null);

    const user_path = kf.getPath(io, arena, env.*, .data) catch
        @panic("User data directory does not exist\n") orelse
        @panic("Failed to find a valid user data directory\n");
    defer arena.free(user_path);

    const user_dir = Dir.openDirAbsolute(io, user_path, .{}) catch
        @panic("User data directory is inaccessible\n");

    user_dir.close(io);

    const path = Dir.path.join(arena, &.{ user_path, "game-of-life" }) catch unreachable;
    datapath = path;
    datapathZ = arena.dupeSentinel(u8, path, 0) catch @panic("OOM");
}

/// Writes all the included pattern files so they can then be imported into the app
fn write_included(io: Io) void {
    const dir = get_datadir(io);

    for (all) |sample| {
        std.zon.stringify.serialize(sample, .{}, &writer) catch {
            std.log.err("Failed to deserialize sample\nSample raw:\n{any}", .{sample});
            continue;
        };

        const data = writer.buffered();
        const filename = sample.name;

        dir.access(io, sample.name, .{}) catch {
            dir.writeFile(io, .{ .data = data, .sub_path = filename }) catch continue;
            _ = writer.consumeAll();
        };
    }
}

fn get_datadir(io: Io) Dir {
    return Dir.createDirPathOpen(.cwd(), io, datapath.?, .{}) catch
        @panic("Failed to obtain game of life data directory handle\n");
}

pub fn init(io: Io, arena: Allocator, environ_map: *Environ.Map) void {
    filedialog.init() catch unreachable;
    std.debug.assert(datapath == null);
    set_datapath(io, arena, environ_map);
    write_included(io);
}

const dialog_filters: []const filedialog.FilterItem = &.{.{
    .name = "Patterns",
    .spec = "zon",
}};

var serde_buffer: [1024]u8 = undefined;
var writer: std.Io.Writer = .fixed(&serde_buffer);

var pattern_buffer: [1024]raylib.Vector2 = undefined;
pub fn load_from_disk(io: Io, arena: Allocator) ?Pattern {
    const Options = filedialog.OpenDialogOptions;
    const Path = filedialog.Path;

    const open_opts: Options = .{
        .default_path = datapathZ,
        .filter_list = dialog_filters,
    };
    const path: Path = (filedialog.open(open_opts) catch null) orelse return null;
    defer path.deinit();

    const filepath: [:0]const u8 = path.slice();
    const contents: [:0]const u8 = Dir.readFileAllocOptions(.cwd(), io, filepath, arena, .unlimited, .@"8", 0) catch return null;
    return std.zon.parse.fromSliceAlloc(Pattern, arena, contents, null, .{}) catch null;
}

pub fn save_to_disk(io: Io, cells: []const raylib.Vector2) !void {
    const Options = filedialog.SaveDialogOptions;
    const Path = filedialog.Path;

    const opts: Options = .{
        .default_path = datapathZ,
        .default_name = "new-pattern.zon",
        .filter_list = dialog_filters,
    };
    const path: Path = try filedialog.save(opts) orelse return;
    defer path.deinit();

    const filepath: [:0]const u8 = path.slice();
    const filename = Dir.path.basename(filepath);
    const pattern: Pattern = .{ .name = filename, .data = cells };

    try std.zon.stringify.serialize(pattern, .{}, &writer);

    try get_datadir(io).writeFile(io, .{
        .data = writer.buffered(),
        .sub_path = filename,
    });
}
