const std = @import("std");
const raylib = @import("raylib");

pub fn contains_mouse(r: raylib.Rectangle) bool {
    const mouse_position = raylib.getMousePosition();
    return raylib.checkCollisionPointRec(mouse_position, r);
}

pub fn as_horizontal_line(r: raylib.Rectangle, color: raylib.Color) void {
    const from: raylib.Vector2 = .{
        .x = r.x,
        .y = r.y,
    };
    const to: raylib.Vector2 = .{
        .x = r.x + r.width,
        .y = r.y,
    };
    raylib.drawLineV(from, to, color);
}

pub fn as_vertical_line(r: raylib.Rectangle, color: raylib.Color) void {
    const from: raylib.Vector2 = .{
        .x = r.x,
        .y = r.y,
    };
    const to: raylib.Vector2 = .{
        .x = r.x,
        .y = r.y + r.height,
    };
    raylib.drawLineV(from, to, color);
}

pub fn get_font_size(text: [:0]const u8, r: raylib.Rectangle) f32 {
    const font: raylib.Font = raylib.getFontDefault() catch unreachable;
    const base_font_size: f32 = 20;
    const spacing: f32 = 1;
    const text_size: raylib.Vector2 = raylib.measureTextEx(font, text, base_font_size, spacing);
    const scale_x: f32 = r.width / text_size.x;
    const scale_y: f32 = r.height / text_size.y;
    const scale: f32 = @min(scale_x, scale_y);
    return (base_font_size * scale) * 0.93;
}

pub fn draw_text(text: [:0]const u8, r: raylib.Rectangle, color: raylib.Color) void {
    const font: raylib.Font = raylib.getFontDefault() catch unreachable;
    const font_size: f32 = get_font_size(text, r);
    const spacing: f32 = 1;
    const text_size: raylib.Vector2 = raylib.measureTextEx(font, text, font_size, spacing);
    const text_position: raylib.Vector2 = .{
        .x = r.x + (r.width - text_size.x) / 2,
        .y = r.y + (r.height - text_size.y) / 2,
    };

    raylib.drawTextEx(font, text, text_position, font_size, spacing, color);
}

/// computes the center of the rectangle
pub fn get_center(r: raylib.Rectangle) raylib.Vector2 {
    return .{
        .x = r.x + (r.width / 2),
        .y = r.y + (r.height / 2),
    };
}
test "rect get_center" {
    const r: raylib.Rectangle = .{
        .x = 15,
        .y = 20,
        .width = 10,
        .height = 5,
    };

    const expected: raylib.Vector2 = .{ .x = 20, .y = 22.5 };
    const result = get_center(r);
    try std.testing.expectEqual(expected.x, result.x);
    try std.testing.expectEqual(expected.y, result.y);
}

pub fn get_origin_vector(r: raylib.Rectangle) raylib.Vector2 {
    return .{
        .x = r.x,
        .y = r.y,
    };
}
