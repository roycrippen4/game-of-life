const std = @import("std");

const raygui = @import("raygui");
const raylib = @import("raylib");
const Vector2 = raylib.Vector2;
const Rectangle = raylib.Rectangle;
const Color = raylib.Color;

const Cell = @import("Cell.zig");
const core = @import("root.zig");
const State = @import("State.zig");

/// Grid is 30x30 cells
pub const GRID_SIZE: u32 = 30;

pub const COLORS = .{
    .fg = Color.gray,
    .bg = Color.black,
    .accent = Color.yellow,
};

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

pub fn init() void {
    const pad = @divExact(sections.window_pad, 2);

    raylib.initWindow(
        sections.width,
        sections.toolbar.y + sections.toolbar.height + pad,
        "Conway's Game of Life",
    );

    raylib.setTargetFPS(60);
}

pub fn rect_contains(rect: Rectangle, other: Vector2) bool {
    return other.x >= rect.x and
        other.y >= rect.y and
        other.x < rect.x + rect.width and
        other.y < rect.y + rect.height;
}

fn render_grid(state: *State, rect: Rectangle) void {
    raylib.drawLineV(
        .{
            .x = rect.x,
            .y = rect.y,
        },
        .{
            .x = rect.x + rect.width,
            .y = rect.y,
        },
        COLORS.fg,
    );
    raylib.drawLineV(
        .{
            .x = rect.x,
            .y = rect.y,
        },
        .{
            .x = rect.x,
            .y = rect.y + rect.height,
        },
        COLORS.fg,
    );
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
            const cell_is_hovered = rect_contains(cell_rect, mouse);
            Cell.draw(cell_rect, cell_is_alive, cell_is_hovered);
            Cell.handle_toggle(state, row, col, cell_is_hovered);
        }
    }
}

pub fn render_toolbar(state: *State) void {
    _ = state;
}

pub fn render(state: *State) void {
    raylib.beginDrawing();
    defer raylib.endDrawing();

    raylib.clearBackground(.black);

    render_grid(state, sections.grid);
}

pub fn should_exit() bool {
    return raylib.windowShouldClose();
}
pub fn exit() void {
    raylib.closeWindow();
}
