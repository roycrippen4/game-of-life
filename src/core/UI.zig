const std = @import("std");

const raygui = @import("raygui");
const raylib = @import("raylib");
const Vector2 = raylib.Vector2;
const Rectangle = raylib.Rectangle;
const Color = raylib.Color;

const Cell = @import("Cell.zig");
const core = @import("root.zig");
const GRID_SIZE: usize = core.GRID_SIZE;
const State = @import("State.zig");

// height is actually 10px,
// 10px of padding above and below the slider control
const SLIDER_HEIGHT: usize = 30;

const GRID_WIDTH: usize = 600;
const GRID_HEIGHT: usize = 600;

const WINDOW_WIDTH: usize = GRID_WIDTH;
const WINDOW_HEIGHT: usize = SLIDER_HEIGHT + GRID_HEIGHT;

pub const CELL_WIDTH: i32 = @divFloor(GRID_WIDTH, GRID_SIZE);
pub const CELL_HEIGHT: i32 = @divFloor(GRID_HEIGHT, GRID_SIZE);

pub fn init() void {
    raylib.initWindow(
        GRID_WIDTH,
        WINDOW_HEIGHT,
        "Conway's Game of Life",
    );

    // sets the slider's background color
    raygui.setStyle(
        .slider,
        .{ .control = .base_color_normal },
        Color.gray.toInt(),
    );

    raygui.setStyle(
        .slider,
        .{ .control = .text_color_focused },
        Color.red.toInt(),
    );
}

fn render_grid(state: *State) void {
    const mouse = raylib.getMousePosition();
    for (0..GRID_SIZE) |row| for (0..GRID_SIZE) |col| {
        const pos: Vector2 = .{
            .x = @floatFromInt(col * CELL_WIDTH),
            .y = @floatFromInt(row * CELL_WIDTH),
        };
        const cell_is_alive = state.game.current[row][col];
        const cell_is_hovered = Cell.contains(pos, mouse);
        Cell.draw(pos, cell_is_alive, cell_is_hovered);
        Cell.handle_toggle(state, row, col, cell_is_hovered);
    };
}

pub fn render(state: *State) void {
    raylib.clearBackground(.black);
    raylib.beginDrawing();
    defer raylib.endDrawing();

    render_grid(state);
}

pub fn should_exit() bool {
    return raylib.windowShouldClose();
}
pub fn exit() void {
    raylib.closeWindow();
}
