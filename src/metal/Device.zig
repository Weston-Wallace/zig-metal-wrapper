const std = @import("std");
const c = @cImport({
    @cInclude("metal_wrapper.h");
});

const Library = @import("Library.zig");
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

pub const CreateLibraryResult = struct {
    library: Library,
    error_msg: ?[]const u8,
};

/// Create a Metal shader library from source code
/// Caller is responsible for freeing error_msg if not null
pub fn createLibraryFromSource(self: Device, source: []const u8, allocator: std.mem.Allocator) MetalError!CreateLibraryResult {
    // Create a null-terminated copy of the source
    const c_source = try allocator.dupeZ(u8, source);
    defer allocator.free(c_source);

    var error_ptr: ?[*c]u8 = null;
    const library_ptr = c.metal_device_create_library_from_source(self.handle, c_source.ptr, @ptrCast(&error_ptr));

    // Handle possible compilation error
    if (library_ptr == null) {
        if (error_ptr != null) {
            // We have an error message - create a Zig string from it
            const error_c_str = std.mem.span(error_ptr.?);
            const error_str = try allocator.dupe(u8, error_c_str);
            utils.freeCString(error_ptr.?);

            return .{
                .library = Library{
                    .handle = null,
                    .device_handle = self.handle,
                },
                .error_msg = error_str,
            };
        }
        return MetalError.LibraryCreationFailed;
    }

    return .{
        .library = Library{
            .handle = library_ptr,
            .device_handle = self.handle,
        },
        .error_msg = null,
    };
}

/// Load a Metal shader from a file on disk
/// Caller is responsible for freeing error_msg if not null
pub fn createLibraryFromFile(
    device: Device,
    file_path: []const u8,
    allocator: std.mem.Allocator,
) MetalError!CreateLibraryResult {
    // Open the shader file
    const file = std.fs.cwd().openFile(file_path, .{}) catch |err| {
        std.log.err("Failed to open shader file '{s}': {s}", .{ file_path, @errorName(err) });
        return MetalError.InvalidShaderSource;
    };
    defer file.close();

    // Read the file contents
    const source = file.readToEndAlloc(allocator, 1024 * 1024) catch |err| {
        std.log.err("Failed to read shader file '{s}': {s}", .{ file_path, @errorName(err) });
        return MetalError.InvalidShaderSource;
    };
    defer allocator.free(source);

    // Compile the shader
    return device.createLibraryFromSource(source, allocator);
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
