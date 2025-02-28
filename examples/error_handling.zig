const std = @import("std");
const metal = @import("metal");

/// Intentionally buggy compute shader to demonstrate error handling
const invalid_shader_source =
    \\#include <metal_stdlib>
    \\using namespace metal;
    \\
    \\kernel void buggy_function(device float* data [[buffer(0)]],
    \\                         uint id [[thread_position_in_grid]])
    \\{
    \\    // Missing semicolon syntax error
    \\    data[id] = data[id] * 2.0
    \\    
    \\    // Using non-existent variable - semantic error
    \\    data[id] += nonexistent_variable;
    \\}
;

/// Demonstrates how to handle Metal errors in a robust way
pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize Metal
    try stdout.print("=== Metal Error Handling Example ===\n\n", .{});

    // Create a Metal device
    try stdout.print("Step 1: Creating Metal device...\n", .{});
    var device = try metal.Device.createDefault();
    defer device.deinit();

    // Get device name
    const name = try device.getName(allocator);
    defer allocator.free(name);
    try stdout.print("✅ Metal device created: {s}\n\n", .{name});

    // Demonstrate Buffer Error Handling
    try stdout.print("Step 2: Demonstrating Buffer Error Handling...\n", .{});

    try stdout.print("  Attempt to create 0-sized buffer (should fail):\n", .{});
    const buffer_result = device.createBuffer(0, .Shared);

    try handleResult(buffer_result, "Buffer creation", stdout);

    try stdout.print("  Creating valid buffer:\n", .{});
    var buffer = try device.createBuffer(1024, .Shared);
    defer buffer.deinit();
    try stdout.print("✅ Valid buffer created successfully\n\n", .{});

    // Demonstrate Shader Compilation Error Handling
    try stdout.print("Step 3: Demonstrating Shader Compilation Error Handling...\n", .{});

    try stdout.print("  Attempt to compile invalid shader:\n", .{});

    // Try to compile an invalid shader and catch the error
    if (metal.Library.createFromSource(device, invalid_shader_source, allocator)) |shader_result| {
        if (shader_result.error_msg) |err_msg| {
            defer allocator.free(err_msg);
            try stdout.print("❌ Shader compilation failed (expected) with error:\n", .{});
            try stdout.print("  {s}\n", .{err_msg});
        } else {
            // This should not happen since we intentionally used invalid syntax
            defer shader_result.library.deinit();
            try stdout.print("⚠️ Invalid shader compiled successfully (unexpected)\n", .{});
        }
    } else |err| {
        try stdout.print("Shader compilation expected failure with error: {}\n", .{err});
    }

    // Demonstrate function not found error
    try stdout.print("\n  Attempt to get non-existent function from a valid library:\n", .{});

    // First create a valid library
    const valid_shader =
        \\#include <metal_stdlib>
        \\using namespace metal;
        \\
        \\kernel void valid_function(device float* data [[buffer(0)]],
        \\                         uint id [[thread_position_in_grid]])
        \\{
        \\    data[id] = data[id] * 2.0;
        \\}
    ;

    const valid_result = try metal.Library.createFromSource(device, valid_shader, allocator);
    if (valid_result.error_msg) |err_msg| {
        defer allocator.free(err_msg);
        try stdout.print("❌ Valid shader compilation failed unexpectedly: {s}\n", .{err_msg});
        return metal.MetalError.ShaderCompilationFailed;
    }

    var library = valid_result.library;
    defer library.deinit();

    // Try to get a non-existent function
    const function_result = library.getFunction("non_existent_function", allocator);

    try handleResult(function_result, "Function lookup", stdout);

    // Try to get a valid function
    try stdout.print("  Getting valid function from library:\n", .{});
    var function = try library.getFunction("valid_function", allocator);
    defer function.deinit();
    try stdout.print("✅ Valid function retrieved successfully\n\n", .{});

    try stdout.print("\n=== Error Handling Example Complete ===\n", .{});
}

/// Helper function to handle and print Metal errors
fn handleResult(result: anytype, operation: []const u8, writer: anytype) !void {
    if (result) |_| {
        try writer.print("✅ {s} succeeded\n", .{operation});
    } else |err| {
        try writer.print("❌ {s} failed: {s} - {}\n", .{
            operation,
            @errorName(err),
            err,
        });
    }
}
