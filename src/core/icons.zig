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
const util = @import("util.zig");

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

const ButtonState = enum {
    default,
    hover,
    down,
    disabled,

    /// Never returns `disabled` variant.
    /// `disabled` is trivial to check and should be verified before calling this function
    pub fn get(bb: Rectangle) @This() {
        const mouse = raylib.getMousePosition();
        if (util.rect.contains(bb, mouse)) {
            if (raylib.isMouseButtonDown(.left)) {
                return .down;
            } else {
                return .hover;
            }
        }

        return .default;
    }
};

pub const ButtonOpts = struct {
    border: bool = false,
    disable: bool = false,
    rounded: bool = true,
    drop_shadow: bool = true,
};

/// Renders an icon to the screen.
/// Returns the computed bounding box for the icon
pub fn draw(icon: Icon, bb: Rectangle, pixel_scale: f32, state: ButtonState, opts: ButtonOpts) void {
    const fg, const bg = switch (state) {
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

    if (opts.drop_shadow) {
        const x_scale: f32 = if (state == .down) 0.005 else 0.007;
        const y_scale: f32 = if (state == .down) 0.001 else 0.003;

        if (opts.rounded) {
            raylib.drawRectangleRounded(
                .{
                    .x = bb.x + (bb.x * x_scale),
                    .y = bb.y + (bb.y * y_scale),
                    .width = bb.width,
                    .height = bb.height,
                },
                0.2,
                5,
                .black,
            );
        } else {
            raylib.drawRectangleRec(
                .{
                    .x = bb.x + (bb.x * x_scale),
                    .y = bb.y + (bb.y * y_scale),
                    .width = bb.width,
                    .height = bb.height,
                },
                .black,
            );
        }
    }

    if (opts.rounded) {
        raylib.drawRectangleRounded(bb, 0.2, 5, bg);
    } else {
        raylib.drawRectangleRec(bb, bg);
    }

    // draw each pixel of the icon
    for (0..DATA_ELEMENTS) |i| {
        for (0..32) |k_usize| {
            const k: u5 = @intCast(k_usize);
            if (icon[i] & shl(u32, 1, k) != 0) {
                const x: f32 = @floatFromInt(k_usize % SIZE);
                const y: f32 = @floatFromInt(i * 2 + k_usize / SIZE);
                const pixel: Rectangle = .{
                    .x = bb.x + x * pixel_scale,
                    .y = bb.y + y * pixel_scale,
                    .width = pixel_scale,
                    .height = pixel_scale,
                };
                raylib.drawRectangleRec(pixel, fg);
            }
        }
    }

    if (opts.border) {
        if (opts.rounded) {
            raylib.drawRectangleRoundedLinesEx(bb, 0.2, 10, 1, colors.button.border);
        } else {
            raylib.drawRectangleLinesEx(bb, 1, colors.button.border);
        }
    }
}

/// Renders an icon as a button. Returns true if clicked.
pub fn button(icon: Icon, pos: raylib.Vector2, pixel_scale: f32, opts: ButtonOpts) bool {
    const bb: Rectangle = .{
        .x = pos.x,
        .y = pos.y,
        .width = SIZE * pixel_scale,
        .height = SIZE * pixel_scale,
    };

    const hovered = util.rect.contains_mouse(bb);

    const state: ButtonState = if (opts.disable)
        .disabled
    else if (hovered)
        if (raylib.isMouseButtonDown(.left))
            .down
        else
            .hover
    else
        .default;

    draw(icon, bb, pixel_scale, state, opts);

    return hovered and !opts.disable and raylib.isMouseButtonPressed(.left);
}
