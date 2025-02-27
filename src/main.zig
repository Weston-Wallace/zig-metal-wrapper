const std = @import("std");
const c = @cImport({
    @cInclude("metal_wrapper.h");
});

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    // Initialize Metal
    if (c.metal_init() != 1) {
        try stdout.print("Failed to initialize Metal\n", .{});
        return;
    }
    defer c.metal_cleanup();

    // Create a Metal device
    const device = c.metal_create_default_device();
    if (device == null) {
        try stdout.print("Failed to create Metal device\n", .{});
        return;
    }
    defer c.metal_device_release(device);

    // Get device name
    const name = c.metal_device_get_name(device);
    if (name != null) {
        try stdout.print("Metal device name: {s}\n", .{name});
        // Free the string we got from C
        std.c.free(@constCast(@ptrCast(name)));
    }
}
