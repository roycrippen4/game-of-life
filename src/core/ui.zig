const std = @import("std");

const raylib = @import("raylib");
const Vector2 = raylib.Vector2;
const Rectangle = raylib.Rectangle;
const Color = raylib.Color;

const cell = @import("cell.zig");
const colors = @import("colors.zig");
const icons = @import("icons.zig");
const patterns = @import("patterns/root.zig");
const rect = @import("rect.zig");
const State = @import("State.zig");

const min_fps: u16 = State.Sim.min_fps;
const max_fps: u16 = State.Sim.max_fps;

/// Grid is 30x30 cells
pub const GRID_SIZE: u32 = 30;

const Sections = struct {
    const Self = @This();

    title: Rectangle = undefined,
    grid: Rectangle = undefined,
    toolbar: Rectangle = undefined,
    sim_controls: Rectangle = undefined,

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
    const simbar_height: usize = 45;

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

    s.sim_controls = .{
        .x = pad,
        .y = s.toolbar.y + s.toolbar.height + s.section_gap,
        .width = width,
        .height = simbar_height,
    };

    break :blk s;
};

const TITLE_TEXT: [:0]const u8 = "Conway's Game of Life";
const TARGET_FPS: u16 = 120;

pub fn init() void {
    const pad = @divExact(sections.window_pad, 2);
    const width = sections.width;
    const height = sections.sim_controls.y + sections.sim_controls.height + pad;

    raylib.setTargetFPS(TARGET_FPS);
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

inline fn next_button_x(rect_x: f32, button_width: f32, gap: f32, render_count: *f32) f32 {
    render_count.* += 1;
    const gap_width: f32 = render_count.* * gap;
    const button_width_sum: f32 = ((render_count.* - 1) * button_width);
    return rect_x + gap_width + button_width_sum;
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
    const pixel_scale = 4;

    // gap between each button
    const b_gap: f32 = 5;
    const b_width: f32 = icons.SIZE * pixel_scale;
    const b_y: f32 = rectangle.y + (rectangle.height / 2) - (b_width) / 2;

    var rendered: f32 = 0;

    // Previous state
    {
        const b_x: f32 = next_button_x(rectangle.x, b_width, b_gap, &rendered);
        const b_pos: Vector2 = .{ .x = b_x, .y = b_y };
        const click = icons.button(io, icons.prev_frame, b_pos, pixel_scale, .{
            .tooltip = "Step Back",
            .disable = state.sim.running,
        });
        if (click) state.game.prev();
    }

    // next state
    {
        const b_x: f32 = next_button_x(rectangle.x, b_width, b_gap, &rendered);
        const pos: Vector2 = .{ .x = b_x, .y = b_y };
        const click = icons.button(io, icons.next_frame, pos, pixel_scale, .{
            .tooltip = "Step Forward",
            .disable = state.sim.running,
        });
        if (click) state.game.next();
    }

    // Load File
    {
        const b_x: f32 = next_button_x(rectangle.x, b_width, b_gap, &rendered);
        const pos: Vector2 = .{ .x = b_x, .y = b_y };
        const click = icons.button(io, icons.file_open, pos, pixel_scale, .{
            .tooltip = "Load Board",
            .disable = state.sim.running,
        });
        if (click) if (patterns.load_from_disk(io, arena)) |pattern| {
            state.game.load(pattern.data);
            std.zon.parse.free(arena, pattern);
        };
    }

    // save file
    {
        const b_x: f32 = next_button_x(rectangle.x, b_width, b_gap, &rendered);
        const pos: Vector2 = .{ .x = b_x, .y = b_y };
        const click = icons.button(io, icons.file_save, pos, pixel_scale, .{
            .tooltip = "Save Board",
            .disable = state.sim.running,
        });
        if (click) try patterns.save_to_disk(io, state.game.get_all_living());
    }

    // clear state
    {
        const b_x: f32 = next_button_x(rectangle.x, b_width, b_gap, &rendered);
        const pos: Vector2 = .{ .x = b_x, .y = b_y };
        const click = icons.button(io, icons.trash, pos, pixel_scale, .{
            .tooltip = "Clear Board",
            .disable = state.sim.running,
        });
        if (click) state.game.clear();
    }

    // start sim
    {
        const b_x: f32 = next_button_x(rectangle.x, b_width, b_gap, &rendered);
        const pos: Vector2 = .{ .x = b_x, .y = b_y };
        const click = icons.button(io, icons.play, pos, pixel_scale, .{
            .tooltip = "Play",
            .disable = state.sim.running,
        });
        if (click) state.sim.running = true;
    }

    // pause sim
    {
        const b_x: f32 = next_button_x(rectangle.x, b_width, b_gap, &rendered);
        const pos: Vector2 = .{ .x = b_x, .y = b_y };
        const click = icons.button(io, icons.pause, pos, pixel_scale, .{
            .tooltip = "Pause",
            .disable = !state.sim.running,
        });
        if (click) {
            state.sim.running = false;
            state.sim.fcount = 0;
        }
    }
}

pub fn render_sim_controls(io: std.Io, state: *State, rectangle: Rectangle) void {
    const scale = 2;

    // gap between each button
    const b_gap: f32 = 5;
    const b_width: f32 = icons.SIZE * scale;
    const b_y: f32 = rectangle.y + (rectangle.height / 2) - (b_width) / 2;

    var rendered: f32 = 0;
    raylib.drawRectangleRec(rectangle, .dark_gray);

    // slow down
    {
        const b_x: f32 = next_button_x(rectangle.x, b_width, b_gap, &rendered);
        const b_pos: Vector2 = .{ .x = b_x, .y = b_y };
        const click = icons.button(io, icons.minus, b_pos, scale, .{ .tooltip = "Slower" });
        if (click) {
            state.sim.fps = if (state.sim.fps < min_fps)
                min_fps
            else
                state.sim.fps - 1;
        }
    }

    // speed up
    {
        const b_x: f32 = next_button_x(rectangle.x, b_width, b_gap, &rendered);
        const b_pos: Vector2 = .{ .x = b_x, .y = b_y };
        const click = icons.button(io, icons.plus, b_pos, scale, .{ .tooltip = "Faster" });
        if (click) {
            state.sim.fps = if (state.sim.fps > max_fps)
                max_fps
            else
                state.sim.fps + 1;
        }
    }

    // raylib.drawText("Frame Speed: ", 165, 210, 10, raylib.Color.dark_gray);
    // raylib.drawText(raylib.textFormat("%02i FPS", .{gs.frame_speed}), 575, 210, 10, raylib.Color.dark_gray);
    //
    // var i: i32 = 0;
    // while (i < MAX_FRAME_SPEED) : (i += 1) {
    //     if (i < gs.frame_speed) {
    //         raylib.drawRectangle(250 + 21 * i, 205, 20, 20, raylib.Color.red);
    //     }
    //     raylib.drawRectangleLines(250 + 21 * i, 205, 20, 20, raylib.Color.maroon);
    // }
}

pub fn render(io: std.Io, arena: std.mem.Allocator, state: *State) !void {
    raylib.beginDrawing();
    defer raylib.endDrawing();
    raylib.clearBackground(.black);

    rect.draw_text(TITLE_TEXT, sections.title, .white);
    render_grid(state, sections.grid);
    try render_toolbar(io, arena, state, sections.toolbar);
    render_sim_controls(io, state, sections.sim_controls);

    if (state.sim.running) {
        state.sim.fcount += 1;
        if (state.sim.fcount >= @divFloor(TARGET_FPS, state.sim.fps)) {
            state.game.next();
            state.sim.fcount = 0;
        }
    }
}

pub fn should_exit() bool {
    return raylib.windowShouldClose();
}
pub fn exit() void {
    raylib.closeWindow();
}
