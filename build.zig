const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "gol",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const core = b.createModule(.{
        .root_source_file = b.path("src/core/root.zig"),
        .optimize = optimize,
        .target = target,
    });

    const raylib = b.dependency("raylib_zig", .{ .target = target, .optimize = optimize, .linkage = .static });
    const raylib_mod = raylib.module("raylib");
    const raygui_mod = raylib.module("raygui");
    const raylib_artifact = raylib.artifact("raylib");

    const filedialog = b.dependency("filedialog", .{ .target = target, .optimize = optimize });
    const filedialog_mod = filedialog.module("filedialog");
    const @"known-folders" = b.dependency("known_folders", .{ .target = target, .optimize = optimize });
    const @"known-folders_mod" = @"known-folders".module("known-folders");

    core.addImport("filedialog", filedialog_mod);
    core.addImport("known-folders", @"known-folders_mod");
    core.addImport("raygui", raygui_mod);
    core.addImport("raylib", raylib_mod);
    core.linkLibrary(raylib_artifact);

    exe.root_module.addImport("core", core);
    exe.root_module.addImport("raygui", raygui_mod);
    exe.root_module.addImport("raylib", raylib_mod);

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
        const core_unit_tests = b.addTest(.{
            .root_module = core,
            .filters = test_filters,
        });
        const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
        const run_core_unit_tests = b.addRunArtifact(core_unit_tests);
        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_exe_unit_tests.step);
        test_step.dependOn(&run_core_unit_tests.step);
    }

    // Lsp stuff
    {
        const exe_check = b.addExecutable(.{
            .name = "gol",
            .root_module = exe.root_module,
        });
        const core_check = b.addExecutable(.{
            .name = "core",
            .root_module = core,
        });

        const check = b.step("check", "Check if it compiles");
        check.dependOn(&exe_check.step);
        check.dependOn(&core_check.step);
    }
}
