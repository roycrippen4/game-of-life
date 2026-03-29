const raylib = @import("raylib");
const Vector2 = raylib.Vector2;
const Color = raylib.Color;
const Rectangle = raylib.Rectangle;

const State = @import("State.zig");
const UI = @import("UI.zig");

pub fn draw(rect: Rectangle, cell_is_alive: bool, cell_is_hovered: bool) void {
    const color: Color = if (cell_is_hovered) UI.COLORS.accent else UI.COLORS.fg;
    if (cell_is_alive) {
        raylib.drawRectangleRec(rect, color);
    } else if (cell_is_hovered) {
        raylib.drawRectangleLinesEx(rect, 2, color);
    }

    const x: f32 = rect.x;
    const y: f32 = rect.y;

    raylib.drawLineV(
        .{
            .x = x + rect.width,
            .y = y,
        },
        .{
            .x = x + rect.width,
            .y = y + rect.height,
        },
        UI.COLORS.fg,
    );
    raylib.drawLineV(
        .{
            .x = x,
            .y = y + rect.height,
        },
        .{
            .x = x + rect.width,
            .y = y + rect.height,
        },
        UI.COLORS.fg,
    );
}

pub fn handle_toggle(state: *State, row: usize, col: usize, cell_is_hovered: bool) void {
    const click_occurred = raylib.isMouseButtonPressed(.left);
    if (click_occurred and cell_is_hovered) {
        state.game.current[row][col] = !state.game.current[row][col];
    }
}
