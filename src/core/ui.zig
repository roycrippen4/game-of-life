const std = @import("std");

const kf = @import("known-folders");
const nfd = @import("nfd");
const raygui = @import("raygui");
const raylib = @import("raylib");
const Vector2 = raylib.Vector2;
const Rectangle = raylib.Rectangle;
const Color = raylib.Color;

const cell = @import("cell.zig");
const colors = @import("colors.zig");
const core = @import("root.zig");
const icons = @import("icons.zig");
const patterns = @import("patterns/root.zig");
const rect = @import("rect.zig");
const State = @import("State.zig");

/// Grid is 30x30 cells
pub const GRID_SIZE: u32 = 30;

const Sections = struct {
    const Self = @This();

    title: Rectangle = undefined,
    grid: Rectangle = undefined,
    toolbar: Rectangle = undefined,
    textbox: Rectangle = undefined,

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
    const textbox_height: usize = 200;

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

    s.textbox = .{
        .x = pad,
        .y = s.toolbar.y + s.toolbar.height + s.section_gap,
        .width = width,
        .height = textbox_height,
    };

    break :blk s;
};

const TITLE_TEXT: [:0]const u8 = "Conway's Game of Life";

pub fn init() void {
    const pad = @divExact(sections.window_pad, 2);
    const width = sections.width;
    const height = sections.textbox.y + sections.textbox.height + pad;

    raylib.setTargetFPS(120);
    raylib.initWindow(width, height, TITLE_TEXT);
}

fn render_grid(state: *State, rectangle: Rectangle) void {
    rect.as_horizontal_line(rectangle, colors.main.fg);
    rect.as_vertical_line(rectangle, colors.main.fg);

    const cell_width = rectangle.width / GRID_SIZE;
    const cell_height = rectangle.height / GRID_SIZE;

    for (0..GRID_SIZE) |row| {
        const row_f: f32 = @floatFromInt(row);
        for (0..GRID_SIZE) |col| {
            const col_f: f32 = @floatFromInt(col);
            const cell_x: f32 = col_f * cell_width;
            const cell_y: f32 = row_f * cell_height;

            const cell_rect: Rectangle = .{
                .x = cell_x + rectangle.x,
                .y = cell_y + rectangle.y,
                .width = cell_width,
                .height = cell_height,
            };
            const cell_is_alive = state.game.current[row][col];
            const cell_is_hovered = rect.contains_mouse(cell_rect);
            cell.draw(cell_rect, cell_is_alive, cell_is_hovered);
            cell.handle_toggle(state, row, col, cell_is_hovered);
        }
    }
}

pub fn render_toolbar(
    io: std.Io,
    arena: std.mem.Allocator,
    state: *State,
    rectangle: Rectangle,
) !void {
    raylib.drawRectangleRec(rectangle, .dark_gray);

    // The icons are pixel art rendered using a bunch of rectangles.
    // This value scales the size of a "pixel" in the icon,
    // which is really just the size of the rect
    const pixel_scale = 5;

    // gap between each button
    const button_gap: f32 = 5;
    const button_width: f32 = icons.SIZE * pixel_scale;
    const button_y: f32 = rectangle.y + (rectangle.height / 2) - (button_width) / 2;

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
        const button_x: f32 = next_button_x(rectangle.x, button_gap, &buttons_rendered);
        const button_pos: Vector2 = .{ .x = button_x, .y = button_y };
        const click_occurred = icons.button(icons.prev_frame, button_pos, pixel_scale, .{});
        if (click_occurred) state.game.prev();
    }

    // Previous state
    {
        const button_x: f32 = next_button_x(rectangle.x, button_gap, &buttons_rendered);
        const pos: Vector2 = .{ .x = button_x, .y = button_y };
        const click_occurred = icons.button(icons.next_frame, pos, pixel_scale, .{});
        if (click_occurred) state.game.next();
    }

    // Load File
    {
        const button_x: f32 = next_button_x(rectangle.x, button_gap, &buttons_rendered);
        const pos: Vector2 = .{ .x = button_x, .y = button_y };
        const click_occurred = icons.button(icons.file_open, pos, pixel_scale, .{});
        if (click_occurred) if (patterns.load_from_disk(io, arena)) |pattern| {
            state.game.load(pattern.data);
            std.zon.parse.free(arena, pattern);
        };
    }

    // save file
    {
        const button_x: f32 = next_button_x(rectangle.x, button_gap, &buttons_rendered);
        const pos: Vector2 = .{ .x = button_x, .y = button_y };
        const click_occurred = icons.button(icons.file_save, pos, pixel_scale, .{});
        if (click_occurred) {
            const pattern: []const raylib.Vector2 = state.game.get_all_living();
            try patterns.save_to_disk(io, pattern);

            // if (nfd.openFileDialog("zon", "") catch unreachable) |path| {
            //     std.debug.print("path = {s}\n", .{path});
            // } else {
            //     std.debug.print("User pressed cancel", .{});
            // }
        }
    }
}

pub fn render_textbox(_: *State, rectangle: Rectangle) void {
    raylib.drawRectangleRec(rectangle, .dark_gray);
}

pub fn render(io: std.Io, arena: std.mem.Allocator, state: *State) !void {
    raylib.beginDrawing();
    defer raylib.endDrawing();
    raylib.clearBackground(.black);

    rect.draw_text(TITLE_TEXT, sections.title, .white);
    render_grid(state, sections.grid);
    try render_toolbar(io, arena, state, sections.toolbar);
    render_textbox(state, sections.textbox);
}

pub fn should_exit() bool {
    return raylib.windowShouldClose();
}
pub fn exit() void {
    raylib.closeWindow();
}
