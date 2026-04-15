const raylib = @import("raylib");
const Vector2 = raylib.Vector2;
const Color = raylib.Color;
const Rectangle = raylib.Rectangle;

const colors = @import("colors.zig");

pub fn draw(rect: Rectangle, cell_is_alive: bool, cell_is_hovered: bool, sim_running: bool) void {
    const color: Color = if (cell_is_hovered and sim_running)
        .red
    else if (cell_is_hovered)
        colors.main.accent
    else
        colors.main.fg;

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
