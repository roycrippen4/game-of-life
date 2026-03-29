const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const hot_reload_option = b.option(bool, "hot", "Enable hot reloading via dynamic library") orelse false;
    const is_release = optimize != .Debug;
    const hot_reload = hot_reload_option and !is_release;

    const build_options = b.addOptions();
    build_options.addOption(bool, "hot_reload", hot_reload);

    const raylib_linkage: std.builtin.LinkMode = if (is_release) .static else .dynamic;

    const exe = b.addExecutable(.{
        .name = "game-of-life",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    exe.root_module.addOptions("build_options", build_options);

    const core = b.createModule(.{
        .root_source_file = b.path("src/core/root.zig"),
        .optimize = optimize,
        .target = target,
    });
    // raylib
    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
        .linkage = raylib_linkage,
    });
    const raylib = raylib_dep.module("raylib");
    const raygui = raylib_dep.module("raygui");
    const raylib_artifact = raylib_dep.artifact("raylib");

    core.addImport("raylib", raylib);
    core.addImport("raygui", raygui);

    if (hot_reload) {
        // Both exe and shared lib link the dynamic raylib so they share
        // raylib's global state (window, GL context) across reloads.
        exe.linkLibrary(raylib_artifact);
        exe.root_module.addImport("raylib", raylib);
        exe.root_module.addImport("raygui", raygui);

        const core_lib = b.addLibrary(.{
            .name = "core",
            .root_module = core,
            .linkage = .dynamic,
        });
        core_lib.linkLibrary(raylib_artifact);
        b.installArtifact(core_lib);
    } else {
        core.linkLibrary(raylib_artifact);
        exe.root_module.addImport("core", core);
        exe.root_module.addImport("raylib", raylib);
        exe.root_module.addImport("raygui", raygui);
    }

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
            .name = "game-of-life",
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
