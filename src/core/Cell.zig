const raylib = @import("raylib");
const Vector2 = raylib.Vector2;
const Color = raylib.Color;
const Rectangle = raylib.Rectangle;

const UI = @import("UI.zig");
const CELL_WIDTH = UI.CELL_WIDTH;
const CELL_HEIGHT = UI.CELL_HEIGHT;

const State = @import("State.zig");

pub fn draw(cell_position: Vector2, cell_is_alive: bool, cell_is_hovered: bool) void {
    const color: Color = if (cell_is_hovered) .green else .gray;
    const rec: Rectangle = .{
        .x = cell_position.x,
        .y = cell_position.y,
        .width = CELL_WIDTH,
        .height = CELL_HEIGHT,
    };

    if (cell_is_alive) {
        raylib.drawRectangleRec(rec, color);
    } else {
        const line_thickness: f32 = if (cell_is_hovered) 2 else 1;
        raylib.drawRectangleLinesEx(rec, line_thickness, color);
    }
}

pub inline fn contains(cell_position: Vector2, other: Vector2) bool {
    return other.x >= cell_position.x and
        other.y >= cell_position.y and
        other.x < cell_position.x + CELL_WIDTH and
        other.y < cell_position.y + CELL_HEIGHT;
}

pub fn handle_toggle(state: *State, row: usize, col: usize, cell_is_hovered: bool) void {
    const click_occurred = raylib.isMouseButtonPressed(.left);
    if (click_occurred and cell_is_hovered) {
        state.game.current[row][col] = !state.game.current[row][col];
    }
}
