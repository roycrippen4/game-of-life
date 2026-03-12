const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "game-of-life",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{},
        }),
    });

    b.installArtifact(exe);

    // run command
    {
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);
    }

    // Unit tests
    {
        const test_filters = b.option(
            []const []const u8,
            "test-filter",
            "Skip tests that do not match any filter",
        ) orelse &.{};

        const exe_unit_tests = b.addTest(.{
            .root_module = exe.root_module,
            .filters = test_filters,
        });
        const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_exe_unit_tests.step);
    }

    // Lsp stuff
    {
        const exe_check = b.addExecutable(.{
            .name = "game-of-life",
            .root_module = exe.root_module,
        });
        const check = b.step("check", "Check if it compiles");
        check.dependOn(&exe_check.step);
    }
}
