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

    // Create a compute pipeline state object
    try stdout.print("\nCreating compute pipeline state...\n", .{});
    var pipeline_state = try function.createComputePipelineState();
    defer pipeline_state.deinit();
    try stdout.print("Compute pipeline state created\n", .{});

    // Create a command queue
    try stdout.print("Creating command queue...\n", .{});
    var command_queue = try device.createCommandQueue();
    defer command_queue.deinit();

    // Create a command buffer
    try stdout.print("Creating command buffer...\n", .{});
    var command_buffer = try command_queue.createCommandBuffer();
    defer command_buffer.deinit();

    // Create a compute command encoder
    try stdout.print("Creating compute command encoder...\n", .{});
    var encoder = try command_buffer.createComputeCommandEncoder();
    defer encoder.deinit();

    // Set the compute pipeline state
    encoder.setComputePipelineState(pipeline_state);

    // Set the buffer
    encoder.setBuffer(buffer, 0, 0);

    // Dispatch threads - we have 4 elements
    try stdout.print("Dispatching compute work...\n", .{});
    encoder.dispatchThreads(4, 1, 1);

    // End encoding
    encoder.endEncoding();

    // Commit the command buffer
    try stdout.print("Committing command buffer...\n", .{});
    command_buffer.commit();

    // Wait for completion
    try stdout.print("Waiting for completion...\n", .{});
    command_buffer.waitUntilCompleted();

    // Read back the results
    try stdout.print("Reading back results...\n", .{});
    try stdout.print("Final values: ", .{});
    for (float_data) |value| {
        try stdout.print("{d:.1} ", .{value});
    }
    try stdout.print("\n", .{});

    // Verify the results - each value should be doubled
    try stdout.print("Verifying results...\n", .{});
    if (float_data[0] == 2.0 and
        float_data[1] == 4.0 and
        float_data[2] == 6.0 and
        float_data[3] == 8.0)
    {
        try stdout.print("✅ Compute shader executed successfully!\n", .{});
    } else {
        try stdout.print("❌ Compute shader results don't match expected values.\n", .{});
    }
}
