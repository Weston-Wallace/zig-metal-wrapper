const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create a static library for the Metal wrapper
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
    metal_lib.linkFramework("Foundation");
    metal_lib.linkFramework("Metal");
    metal_lib.linkFramework("QuartzCore");

    metal_lib.linkLibC();
    metal_lib.linkLibCpp();

    // Install the library
    b.installArtifact(metal_lib);

    // Create the Metal module
    const metal_module = b.addModule("metal", .{
        .root_source_file = b.path("src/metal.zig"),
    });

    // Add include path for the C header
    metal_module.addIncludePath(b.path("metal"));

    // Link the library with the executable
    metal_module.linkLibrary(metal_lib);

    // Create example executable
    const exe = b.addExecutable(.{
        .name = "zig-metal-app",
        .root_source_file = b.path("src/main.zig"),
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

    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_cmd.step);

    // Add unit tests
    const lib_tests = b.addTest(.{
        .root_source_file = b.path("src/metal.zig"),
        .target = target,
        .optimize = optimize,
    });

    lib_tests.addIncludePath(b.path("metal"));
    lib_tests.linkLibrary(metal_lib);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&b.addRunArtifact(lib_tests).step);
}
