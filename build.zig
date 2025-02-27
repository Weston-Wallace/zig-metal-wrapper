const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create a Zig executable
    const exe = b.addExecutable(.{
        .name = "zig-metal-app",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add include path for our wrapper header
    exe.addIncludePath(b.path("metal"));

    exe.addCSourceFile(.{
        .file = b.path("metal/metal_wrapper.cpp"),
        .flags = &[_][]const u8{
            "-std=c++17",
            "-fno-rtti", // Optional: disable RTTI for smaller binary
        },
    });

    // Link frameworks (needed again here)
    exe.linkFramework("Foundation");
    exe.linkFramework("Metal");
    exe.linkFramework("QuartzCore");

    exe.linkLibC();
    exe.linkLibCpp();

    // Install the executable
    b.installArtifact(exe);

    // Add run step
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_cmd.step);
}
