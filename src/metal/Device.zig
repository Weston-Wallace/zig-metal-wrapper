const std = @import("std");
const c = @cImport({
    @cInclude("metal_wrapper.h");
});

const CommandQueue = @import("CommandQueue.zig");
const Buffer = @import("Buffer.zig");
const MetalError = @import("error.zig").MetalError;
const utils = @import("utils.zig");

handle: ?*c.MetalDevice,

/// Create a default Metal device
pub fn createDefault() MetalError!Device {
    const device_ptr = c.metal_create_default_device();
    if (device_ptr == null) {
        return MetalError.DeviceCreationFailed;
    }

    return Device{ .handle = device_ptr };
}

/// Returns a C string that is guaranteed to be valid if the function succeeds (doesn't return an error).
/// Caller owns the returned memory and must free it with std.c.free() or metal.freeCString().
pub fn getCName(self: Device) MetalError![*c]const u8 {
    const name_ptr = c.metal_device_get_name(self.handle);
    if (name_ptr == null) {
        return MetalError.NameFetchFailed;
    }
    return name_ptr;
}

/// Get the name of the Metal device
/// Caller owns the returned memory and must free it with allocator.free()
pub fn getName(self: Device, allocator: std.mem.Allocator) MetalError![]const u8 {
    const name_ptr = c.metal_device_get_name(self.handle);
    if (name_ptr == null) {
        return MetalError.NameFetchFailed;
    }

    // Get the C string as a slice
    const c_str = std.mem.span(name_ptr);

    // Allocate memory for our own copy
    const result = allocator.dupe(u8, c_str) catch {
        // Free the C string before returning the error
        utils.freeCString(name_ptr);
        return MetalError.OutOfMemory;
    };

    // Free the C string
    utils.freeCString(name_ptr);

    return result;
}

/// Create a command queue for submitting commands to the device
pub fn createCommandQueue(self: Device) MetalError!CommandQueue {
    const queue_ptr = c.metal_device_create_command_queue(self.handle);
    if (queue_ptr == null) {
        return MetalError.CommandQueueCreationFailed;
    }

    return CommandQueue{ .handle = queue_ptr };
}

/// Create a buffer with the specified length and storage mode
pub fn createBuffer(self: Device, length: usize, mode: Buffer.ResourceStorageMode) MetalError!Buffer {
    const buffer_ptr = c.metal_device_create_buffer(self.handle, length, @intFromEnum(mode));
    if (buffer_ptr == null) {
        return MetalError.BufferCreationFailed;
    }

    return Buffer{ .handle = buffer_ptr };
}

/// Release the Metal device
pub fn deinit(self: Device) void {
    c.metal_device_release(self.handle);
}

const Device = @This();

test "Device basic functionality" {
    const metal = @import("../metal.zig");
    try metal.init();
    defer metal.deinit();

    var device = try Device.createDefault();
    defer device.deinit();

    // Just ensure this doesn't crash or error
    const allocator = std.testing.allocator;
    const name = try device.getName(allocator);
    defer allocator.free(name);

    // Verify name is not empty
    try std.testing.expect(name.len > 0);
}

test "Buffer creation" {
    var device = try Device.createDefault();
    defer device.deinit();

    // Create a buffer
    var buffer = try device.createBuffer(1024, .Shared);
    defer buffer.deinit();

    // Verify buffer length
    try std.testing.expectEqual(@as(usize, 1024), buffer.getLength());
}
