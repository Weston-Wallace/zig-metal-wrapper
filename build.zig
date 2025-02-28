const std = @import("std");

const examples = [_][]const u8{
    "buffer",
    "device_name",
    "shader",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create and configure the Metal library
    const metal_lib = createMetalLibrary(b, target, optimize);

    // Create the Metal module
    const metal_module = createMetalModule(b, metal_lib);

    // Create examples
    inline for (examples) |example| {
        const name = std.fmt.comptimePrint("{s}-example", .{example});
        const source_path = std.fmt.comptimePrint("examples/{s}.zig", .{example});
        const run_step_name = std.fmt.comptimePrint("run-{s}-example", .{example});
        const run_step_description = std.fmt.comptimePrint("Run the {s} example", .{example});
        createExample(
            b,
            name,
            source_path,
            metal_module,
            run_step_name,
            run_step_description,
            target,
            optimize,
        );
    }

    // Add unit tests
    createTests(b, metal_lib, target, optimize);
}

fn createMetalLibrary(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const metal_lib = b.addStaticLibrary(.{
        .name = "zigmetal",
        .root_source_file = b.path("src/metal.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add include path for our wrapper header
    metal_lib.addIncludePath(b.path("metal"));

    metal_lib.addCSourceFile(.{
        .file = b.path("metal/metal_wrapper.cpp"),
        .flags = &[_][]const u8{
            "-std=c++17",
            "-fno-rtti",
        },
    });

    // Link frameworks
    linkMetalFrameworks(metal_lib);

    metal_lib.linkLibC();
    metal_lib.linkLibCpp();

    // Install the library
    b.installArtifact(metal_lib);

    return metal_lib;
}

fn createMetalModule(b: *std.Build, metal_lib: *std.Build.Step.Compile) *std.Build.Module {
    const metal_module = b.addModule("metal", .{
        .root_source_file = b.path("src/metal.zig"),
    });

    // Add include path for the C header
    metal_module.addIncludePath(b.path("metal"));

    // Link the library with the executable
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
    const exe = b.addExecutable(.{
        .name = name,
        .root_source_file = b.path(source_path),
        .target = target,
        .optimize = optimize,
    });

    // Add the Metal module to the executable
    exe.root_module.addImport("metal", metal_module);

    // Install the executable
    b.installArtifact(exe);

    // Add run step
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step(run_step_name, run_step_description);
    run_step.dependOn(&run_cmd.step);
}

fn createTests(b: *std.Build, metal_lib: *std.Build.Step.Compile, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    const lib_tests = b.addTest(.{
        .root_source_file = b.path("src/metal.zig"),
        .target = target,
        .optimize = optimize,
    });

    lib_tests.addIncludePath(b.path("metal"));
    lib_tests.linkLibrary(metal_lib);

    // Link necessary frameworks and libraries
    linkMetalFrameworks(lib_tests);
    lib_tests.linkLibC();
    lib_tests.linkLibCpp();

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&b.addRunArtifact(lib_tests).step);
}

fn linkMetalFrameworks(step: *std.Build.Step.Compile) void {
    step.linkFramework("Foundation");
    step.linkFramework("Metal");
    step.linkFramework("QuartzCore");
}
