const std = @import("std");
const metal = @import("metal");

// Simple compute shader that doubles each value in an array
const shader_source =
    \\#include <metal_stdlib>
    \\using namespace metal;
    \\
    \\kernel void double_values(device float* data [[buffer(0)]],
    \\                         uint id [[thread_position_in_grid]])
    \\{
    \\    data[id] = data[id] * 2.0;
    \\}
;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize Metal
    try metal.init();
    defer metal.deinit();

    // Create a Metal device
    var device = try metal.Device.createDefault();
    defer device.deinit();

    // Get device name
    const name = try device.getName(allocator);
    defer allocator.free(name);

    try stdout.print("Metal device: {s}\n", .{name});

    // Create a shader library from the source
    try stdout.print("Compiling shader...\n", .{});
    const result = try metal.Library.createFromSource(device, shader_source, allocator);

    // Handle compilation errors
    if (result.error_msg) |err_msg| {
        defer allocator.free(err_msg);
        try stdout.print("Shader compilation failed: {s}\n", .{err_msg});
        return error.ShaderCompilationFailed;
    }

    var library = result.library;
    defer library.deinit();
    try stdout.print("Shader compiled successfully\n", .{});

    // Get the compute function
    try stdout.print("Getting compute function...\n", .{});
    var function = try library.getFunction("double_values", allocator);
    defer function.deinit();

    // Get and print the function name
    const func_name = try function.getName(allocator);
    defer allocator.free(func_name);
    try stdout.print("Got compute function: {s}\n", .{func_name});

    // Create a buffer with some test data
    const buffer_size = 4 * @sizeOf(f32); // 4 floats
    var buffer = try device.createBuffer(buffer_size, .Shared);
    defer buffer.deinit();

    // Initialize buffer with data
    const data_slice = buffer.getContentsSlice() orelse {
        try stdout.print("Failed to get buffer contents\n", .{});
        return;
    };

    var float_data = std.mem.bytesAsSlice(f32, data_slice);
    float_data[0] = 1.0;
    float_data[1] = 2.0;
    float_data[2] = 3.0;
    float_data[3] = 4.0;

    // Print initial values
    try stdout.print("Initial values: ", .{});
    for (float_data) |value| {
        try stdout.print("{d:.1} ", .{value});
    }
    try stdout.print("\n", .{});

    try stdout.print("\nNext steps (not yet implemented):\n", .{});
    try stdout.print("1. Create a compute pipeline state object with the function\n", .{});
    try stdout.print("2. Create a command buffer and encoder\n", .{});
    try stdout.print("3. Set the compute pipeline state\n", .{});
    try stdout.print("4. Set buffer arguments\n", .{});
    try stdout.print("5. Dispatch the compute work\n", .{});
    try stdout.print("6. Commit the command buffer\n", .{});
    try stdout.print("7. Wait for completion\n", .{});
    try stdout.print("8. Read back the results\n", .{});
}
