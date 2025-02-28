const std = @import("std");
const metal = @import("metal");

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

    try stdout.print("Metal device name: {s}\n", .{name});

    // Create a buffer
    const buffer_size = 1024;
    var buffer = try device.createBuffer(buffer_size, .Shared);
    defer buffer.deinit();

    try stdout.print("Created Metal buffer with size: {d} bytes\n", .{buffer.getLength()});

    // Create some test data
    var src_data: [1024]u8 = undefined;
    for (0..1024) |i| {
        src_data[i] = @truncate(i % 256);
    }

    // Copy data to buffer
    try buffer.copyFromSlice(&src_data);
    try stdout.print("Copied data to buffer\n", .{});

    // Get buffer contents
    const buffer_contents = buffer.getContentsSlice() orelse {
        try stdout.print("Failed to get buffer contents\n", .{});
        return;
    };

    // Verify first few bytes
    try stdout.print("Buffer contents (first 10 bytes): ", .{});
    for (buffer_contents[0..10]) |byte| {
        try stdout.print("{d} ", .{byte});
    }
    try stdout.print("\n", .{});

    // Now we'd use this buffer with compute shaders in future steps
    try stdout.print("Buffer is ready for compute operations\n", .{});
}
