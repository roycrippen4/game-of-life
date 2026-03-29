## Commands

- `zig build` — standard build
- `zig build -Dhot-reload` — build with hot reloading via dynamic library
- `zig build --release=fast` — release build, no hot reload

## Architecture

- Small Zig app using raylib bindings
- Game/app logic should live in a dynamic library when hot-reload is enabled
- Hot reload: logic compiled as shared lib, main exe relinks at runtime on change
- No hot reload: logic statically included, same binary behavior
- Release fast: always static, no reload machinery at all
