const std = @import("std");

const raygui = @import("raygui");
const raylib = @import("raylib");
const Vector2 = raylib.Vector2;
const Rectangle = raylib.Rectangle;
const Color = raylib.Color;

const cell = @import("cell.zig");
const colors = @import("colors.zig");
const core = @import("root.zig");
const icons = @import("icons.zig");
const State = @import("State.zig");
const util = @import("util.zig");

/// Grid is 30x30 cells
pub const GRID_SIZE: u32 = 30;

const Sections = struct {
    const Self = @This();

    title: Rectangle = undefined,
    grid: Rectangle = undefined,
    toolbar: Rectangle = undefined,

    /// Padding around all sections
    window_pad: usize = 20,
    /// Vertical gap between each section
    section_gap: usize = 10,
    /// Width of the window
    width: usize = 600,
};

/// Sections of the UI broken up into a column of rectangles
const sections: Sections = blk: {
    var s: Sections = .{};

    const title_height: usize = 36;
    const grid_height: usize = 600;
    const toolbar_height: usize = 90;

    const pad = @divExact(s.window_pad, 2);
    const width: usize = s.width - s.window_pad;

    s.title = .{
        .x = pad,
        .y = pad,
        .width = width,
        .height = title_height,
    };

    s.grid = .{
        .x = pad,
        .y = s.title.y + s.title.height + s.section_gap,
        .width = width,
        .height = grid_height,
    };

    s.toolbar = .{
        .x = pad,
        .y = s.grid.y + s.grid.height + s.section_gap,
        .width = width,
        .height = toolbar_height,
    };

    break :blk s;
};

const TITLE_TEXT: [:0]const u8 = "Conway's Game of Life";

pub fn init() void {
    const pad = @divExact(sections.window_pad, 2);
    const width = sections.width;
    const height = sections.toolbar.y + sections.toolbar.height + pad;

    raylib.setTargetFPS(120);
    raylib.initWindow(width, height, TITLE_TEXT);
}

fn render_title(rect: Rectangle) void {
    const font_size: f32 = 36;
    const text_width_i32 = raylib.measureText(TITLE_TEXT, font_size);
    const text_width: f32 = @floatFromInt(text_width_i32);
    const rect_center = util.rect.get_center(rect);
    const text_x = rect_center.x - (text_width / 2);
    const text_y = rect_center.y - (font_size / 2);

    raylib.drawText(
        TITLE_TEXT,
        @intFromFloat(text_x),
        @intFromFloat(text_y),
        font_size,
        .white,
    );
}

fn render_grid(state: *State, rect: Rectangle) void {
    util.rect.as_horizontal_line(rect, colors.main.fg);
    util.rect.as_vertical_line(rect, colors.main.fg);
    const mouse = raylib.getMousePosition();

    const cell_width = rect.width / GRID_SIZE;
    const cell_height = rect.height / GRID_SIZE;

    for (0..GRID_SIZE) |row| {
        const row_f: f32 = @floatFromInt(row);
        for (0..GRID_SIZE) |col| {
            const col_f: f32 = @floatFromInt(col);
            const cell_x: f32 = col_f * cell_width;
            const cell_y: f32 = row_f * cell_height;

            const cell_rect: Rectangle = .{
                .x = cell_x + rect.x,
                .y = cell_y + rect.y,
                .width = cell_width,
                .height = cell_height,
            };
            const cell_is_alive = state.game.current[row][col];
            const cell_is_hovered = util.rect.contains(cell_rect, mouse);
            cell.draw(cell_rect, cell_is_alive, cell_is_hovered);
            cell.handle_toggle(state, row, col, cell_is_hovered);
        }
    }
}

pub fn render_toolbar(state: *State, rect: Rectangle) void {
    raylib.drawRectangleRec(rect, .dark_gray);

    // The icons are pixel art rendered using a bunch of rectangles.
    // This value scales the size of a "pixel" in the icon,
    // which is really just the size of the rect
    const pixel_scale = 5;

    // gap between each button
    const button_gap: f32 = 5;
    const button_width: f32 = icons.SIZE * pixel_scale;
    const button_y: f32 = rect.y + (rect.height / 2) - (button_width) / 2;

    var buttons_rendered: f32 = 0;
    const next_button_x = struct {
        inline fn next_button_x(rect_x: f32, gap: f32, render_count: *f32) f32 {
            render_count.* += 1;
            const gap_width: f32 = render_count.* * gap;
            const button_width_sum: f32 = ((render_count.* - 1) * button_width);
            return rect_x + gap_width + button_width_sum;
        }
    }.next_button_x;

    // Next state
    {
        const button_x: f32 = next_button_x(rect.x, button_gap, &buttons_rendered);
        const button_pos: Vector2 = .{ .x = button_x, .y = button_y };
        const click_occurred = icons.button(icons.prev_frame, button_pos, pixel_scale, .{});
        if (click_occurred) state.game.prev();
    }

    // Previous state
    {
        const button_x: f32 = next_button_x(rect.x, button_gap, &buttons_rendered);
        const pos: Vector2 = .{ .x = button_x, .y = button_y };
        const click_occurred = icons.button(icons.next_frame, pos, pixel_scale, .{});
        if (click_occurred) state.game.next();
    }
}

pub fn render(state: *State) void {
    raylib.beginDrawing();
    defer raylib.endDrawing();
    raylib.clearBackground(.black);

    render_title(sections.title);
    render_grid(state, sections.grid);
    render_toolbar(state, sections.toolbar);
}

pub fn should_exit() bool {
    return raylib.windowShouldClose();
}
pub fn exit() void {
    raylib.closeWindow();
}
