const std = @import("std");

const examples = [_][]const u8{
    "async_compute",
    "buffer",
    "constant",
    "device_name",
    "error_handling",
    "matrix_multiply",
    "shader",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const metal_lib = createMetalLibrary(b, target, optimize);

    const metal_module = addMetalModule(b, metal_lib, target, optimize);

    inline for (examples) |example| {
        createExample(
            b,
            example ++ "-example",
            "examples/" ++ example ++ ".zig",
            metal_module,
            "run-" ++ example,
            "Run the " ++ example ++ " example",
            target,
            optimize,
        );
    }

    createTests(b, metal_module);
}

fn createMetalLibrary(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const metal_lib = b.addStaticLibrary(.{
        .name = "zmw",
        .root_source_file = b.path("src/zmw.zig"),
        .target = target,
        .optimize = optimize,
    });

    metal_lib.addIncludePath(b.path("metal"));

    metal_lib.addCSourceFile(.{
        .file = b.path("metal/metal_wrapper.m"),
        .flags = &[_][]const u8{
            "-fno-rtti",
            "-fno-objc-arc",
        },
    });

    linkMetalFrameworks(metal_lib);
    metal_lib.linkLibC();

    b.installArtifact(metal_lib);

    return metal_lib;
}

fn addMetalModule(b: *std.Build, metal_lib: *std.Build.Step.Compile, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Module {
    const metal_module = b.addModule("zmw", .{
        .root_source_file = b.path("src/zmw.zig"),
        .target = target,
        .optimize = optimize,
    });

    metal_module.addIncludePath(b.path("metal"));
    metal_module.linkLibrary(metal_lib);

    return metal_module;
}

fn createExample(
    b: *std.Build,
    name: []const u8,
    source_path: []const u8,
    metal_module: *std.Build.Module,
    run_step_name: []const u8,
    run_step_description: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) void {
    const mod = b.createModule(.{
        .root_source_file = b.path(source_path),
        .target = target,
        .optimize = optimize,
    });
    mod.addImport("zmw", metal_module);

    const exe = b.addExecutable(.{
        .name = name,
        .root_module = mod,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step(run_step_name, run_step_description);
    run_step.dependOn(&run_cmd.step);
}

fn createTests(b: *std.Build, metal_module: *std.Build.Module) void {
    const lib_tests = b.addTest(.{
        .root_module = metal_module,
    });

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&b.addRunArtifact(lib_tests).step);
}

fn linkMetalFrameworks(step: *std.Build.Step.Compile) void {
    step.linkFramework("Foundation");
    step.linkFramework("Metal");
    step.linkFramework("QuartzCore");
}
