const raylib = @import("raylib");
const Vector2 = raylib.Vector2;
const Color = raylib.Color;
const Rectangle = raylib.Rectangle;
const colors = @import("colors.zig");

const State = @import("State.zig");

pub fn draw(rect: Rectangle, cell_is_alive: bool, cell_is_hovered: bool) void {
    const color: Color = if (cell_is_hovered) colors.main.accent else colors.main.fg;
    if (cell_is_alive) {
        raylib.drawRectangleRec(rect, color);
    } else if (cell_is_hovered) {
        raylib.drawRectangleLinesEx(rect, 2, color);
    }

    const x: f32 = rect.x;
    const y: f32 = rect.y;

    {
        const from: Vector2 = .{
            .x = x + rect.width,
            .y = y,
        };
        const to: Vector2 = .{
            .x = x + rect.width,
            .y = y + rect.height,
        };

        raylib.drawLineV(from, to, colors.main.fg);
    }

    {
        const from: Vector2 = .{
            .x = x,
            .y = y + rect.height,
        };
        const to: Vector2 = .{
            .x = x + rect.width,
            .y = y + rect.height,
        };
        raylib.drawLineV(from, to, colors.main.fg);
    }
}

pub fn handle_toggle(state: *State, row: usize, col: usize, cell_is_hovered: bool) void {
    const click_occurred = raylib.isMouseButtonPressed(.left);
    if (click_occurred and cell_is_hovered) {
        state.game.current[row][col] = !state.game.current[row][col];
    }
}
