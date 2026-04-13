// raygui icon data for custom icons 240-245
// Exported from icons.rgi via rguiicons
//
// Each icon is 16x16 pixels stored as 8 x u32 (one bit per pixel).

const std = @import("std");
const shl = std.math.shl;

const raylib = @import("raylib");
const Rectangle = raylib.Rectangle;
const Vector2 = raylib.Vector2;
const Color = raylib.Color;

const colors = @import("colors.zig");
const rect = @import("rect.zig");

pub const SIZE = 16;
pub const DATA_ELEMENTS = SIZE * SIZE / 32; // 8

pub const Icon = [DATA_ELEMENTS]u32;

pub const next_frame: Icon = .{ 0x00000000, 0x00a00000, 0x03a001a0, 0x0fa007a0, 0x0fa01fa0, 0x03a007a0, 0x00a001a0, 0x00000000 };
pub const prev_frame: Icon = .{ 0x00000000, 0x05000000, 0x05c00580, 0x05f005e0, 0x05f005f8, 0x05c005e0, 0x01000580, 0x00000000 };
pub const play: Icon = .{ 0x00000000, 0x00400000, 0x01c000c0, 0x07c003c0, 0x07c00fc0, 0x01c003c0, 0x004000c0, 0x00000000 };
pub const pause: Icon = .{ 0x00000000, 0x06600000, 0x06600660, 0x06600660, 0x06600660, 0x06600660, 0x00000660, 0x00000000 };
pub const minus: Icon = .{ 0x00000000, 0x00000000, 0x00000000, 0x1ff80000, 0x00001ff8, 0x00000000, 0x00000000, 0x00000000 };
pub const plus: Icon = .{ 0x00000000, 0x01800000, 0x01800180, 0x1ff80180, 0x01801ff8, 0x01800180, 0x00000180, 0x00000000 };
pub const file_save: Icon = .{ 0x3ffe0000, 0x44226422, 0x400247e2, 0x5ffa4002, 0x57ea500a, 0x500a500a, 0x40025ffa, 0x00007ffe };
pub const file_open: Icon = .{ 0x3ff00000, 0x201c2010, 0x20042004, 0x21042004, 0x24442284, 0x21042104, 0x20042104, 0x00003ffc };
pub const trash: Icon = .{ 0x00000000, 0x08080ff8, 0x08081ffc, 0x0aa80aa8, 0x0aa80aa8, 0x0aa80aa8, 0x08080aa8, 0x00000ff8 };

const ButtonState = enum {
    default,
    hover,
    down,
    disabled,

    /// computes the appropriate colors that reflect the state of the button
    /// Returns .{ fg, bg }
    pub fn get_colors(self: @This()) struct { Color, Color } {
        return switch (self) {
            .hover => .{
                raylib.colorBrightness(colors.button.fg, 0.1),
                raylib.colorBrightness(colors.button.bg, 0.1),
            },
            .down => .{
                raylib.colorBrightness(colors.button.fg, -0.1),
                raylib.colorBrightness(colors.button.bg, -0.1),
            },
            .disabled => .{
                raylib.colorBrightness(colors.button.fg, -0.3),
                raylib.colorBrightness(colors.button.bg, -0.3),
            },
            else => .{ colors.button.fg, colors.button.bg },
        };
    }
};

pub const ButtonOpts = struct {
    border: bool = false,
    disable: bool = false,
    rounded: bool = true,
    drop_shadow: bool = true,
    tooltip: ?[:0]const u8 = null,
};

var hover_state: struct {
    timestamp: ?std.Io.Timestamp,
    bb: ?Rectangle,
    pub const default: @This() = .{ .timestamp = null, .bb = null };
} = .default;

/// renders the drop shadow for the icon button
fn draw_dropshadow(bb: Rectangle, state: ButtonState, opts: ButtonOpts) void {
    if (!opts.drop_shadow) return;
    const x_scale: f32 = if (state == .down) 0.005 else 0.007;
    const y_scale: f32 = if (state == .down) 0.001 else 0.003;

    const bounds: Rectangle = .{
        .x = bb.x + (bb.x * x_scale),
        .y = bb.y + (bb.y * y_scale),
        .width = bb.width,
        .height = bb.height,
    };

    if (opts.rounded) {
        raylib.drawRectangleRounded(bounds, 0.2, 5, .black);
    } else {
        raylib.drawRectangleRec(bounds, .black);
    }
}

/// renders the icon itself
fn draw_icon(icon: Icon, bb: Rectangle, scale: f32, fg: Color) void {
    for (0..DATA_ELEMENTS) |i| for (0..32) |k_usize| {
        const k: u5 = @intCast(k_usize);
        if (icon[i] & shl(u32, 1, k) == 0) continue;
        const x: f32 = @floatFromInt(k_usize % SIZE);
        const y: f32 = @floatFromInt(i * 2 + k_usize / SIZE);
        const pixel: Rectangle = .{
            .x = bb.x + x * scale,
            .y = bb.y + y * scale,
            .width = scale,
            .height = scale,
        };
        raylib.drawRectangleRec(pixel, fg);
    };
}

fn draw_border(bb: Rectangle, opts: ButtonOpts) void {
    if (!opts.border) return;
    if (opts.rounded) {
        raylib.drawRectangleRoundedLinesEx(bb, 0.2, 10, 1, colors.button.border);
    } else {
        raylib.drawRectangleLinesEx(bb, 1, colors.button.border);
    }
}

fn draw_background(bb: Rectangle, rounded: bool, bg: Color) void {
    if (rounded) {
        raylib.drawRectangleRounded(bb, 0.2, 5, bg);
    } else {
        raylib.drawRectangleRec(bb, bg);
    }
}

/// renders the icon button's tooltip
fn draw_tooltip(io: std.Io, tooltip: ?[:0]const u8, bb: Rectangle, state: ButtonState) void {
    const text = tooltip orelse return;
    const is_owner = if (hover_state.bb) |hbb| hbb.x == bb.x and hbb.y == bb.y else false;

    if (state != .hover) {
        hover_state = if (is_owner) .default else hover_state;
        return;
    }

    if (!is_owner) {
        hover_state = .{ .bb = bb, .timestamp = .now(io, .real) };
        return;
    }

    const timestamp = hover_state.timestamp orelse return;
    const duration = timestamp.durationTo(.now(io, .real)).toMilliseconds();
    if (duration < 500) return;

    const window_width: f32 = @floatFromInt(raylib.getRenderWidth());
    const font_size: i32 = 18;
    const spacing = 1;
    const font = raylib.getFontDefault() catch unreachable;
    const text_size = raylib.measureTextEx(font, text, font_size, spacing);
    const padding: f32 = 10;

    const x = if (bb.x + text_size.x + padding > window_width)
        window_width - text_size.x - padding
    else
        bb.x;

    const bounds: raylib.Rectangle = .{
        .width = text_size.x + padding,
        .height = text_size.y + padding,
        .x = x,
        .y = bb.y - text_size.y - 10,
    };

    const tooltip_x: i32 = @intFromFloat(bounds.x + (bounds.width - text_size.x) / 2);
    const tooltip_y: i32 = @intFromFloat(bounds.y + (bounds.height - text_size.y) / 2);

    raylib.drawRectangleRec(bounds, .black);
    raylib.drawText(text, tooltip_x, tooltip_y, font_size, .red);
    raylib.drawRectangleLinesEx(bounds, 1, .red);
}

/// Renders an icon to the screen.
/// Returns the computed bounding box for the icon
pub fn draw(
    io: std.Io,
    icon: Icon,
    bb: Rectangle,
    pixel_scale: f32,
    state: ButtonState,
    opts: ButtonOpts,
) void {
    const fg, const bg = state.get_colors();
    draw_dropshadow(bb, state, opts);
    draw_background(bb, opts.rounded, bg);
    draw_icon(icon, bb, pixel_scale, fg);
    draw_border(bb, opts);
    draw_tooltip(io, opts.tooltip, bb, state);
}

/// Renders an icon as a button. Returns true if clicked.
pub fn button(
    io: std.Io,
    icon: Icon,
    pos: raylib.Vector2,
    pixel_scale: f32,
    opts: ButtonOpts,
) bool {
    const bb: Rectangle = .{
        .x = pos.x,
        .y = pos.y,
        .width = SIZE * pixel_scale,
        .height = SIZE * pixel_scale,
    };

    const hovered = rect.contains_mouse(bb);
    const state: ButtonState = blk: {
        if (opts.disable) break :blk .disabled;
        if (hovered) break :blk if (raylib.isMouseButtonDown(.left)) .down else .hover;
        break :blk .default;
    };

    draw(io, icon, bb, pixel_scale, state, opts);

    return !opts.disable and hovered and raylib.isMouseButtonPressed(.left);
}
