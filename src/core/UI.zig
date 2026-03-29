const std = @import("std");

const raygui = @import("raygui");
const raylib = @import("raylib");
const Vector2 = raylib.Vector2;
const Rectangle = raylib.Rectangle;
const Color = raylib.Color;

const Cell = @import("Cell.zig");
const colors = @import("colors.zig");
const core = @import("root.zig");
const State = @import("State.zig");
const util = @import("util.zig");
const icons = @import("icons.zig");

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
    const toolbar_height: usize = 100;

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
    util.rect.as_horizontal_line(rect, colors.fg);
    util.rect.as_vertical_line(rect, colors.fg);
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
            Cell.draw(cell_rect, cell_is_alive, cell_is_hovered);
            Cell.handle_toggle(state, row, col, cell_is_hovered);
        }
    }
}

pub fn render_toolbar(state: *State, rect: Rectangle) void {
    raylib.drawRectangleRec(rect, .dark_gray);

    const scale: i32 = 5;
    const offset: f32 = (icons.SIZE * scale) / 2;
    const offset_vec: Vector2 = .{ .x = -offset, .y = -offset };
    const icon_pos: Vector2 = util.rect.get_center(rect).add(offset_vec);
    if (icons.button(
        icons.next_frame,
        icon_pos,
        .{ .scale = scale, .rounded = true },
    )) {
        state.game.next();
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
