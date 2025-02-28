const std = @import("std");
const c = @cImport({
    @cInclude("metal_wrapper.h");
});
const Buffer = @This();

const MetalError = @import("error.zig").MetalError;

/// Storage modes for Metal buffers
pub const ResourceStorageMode = enum(c_uint) {
    /// CPU and GPU shared memory
    Shared = c.ResourceStorageModeShared,
    /// Separate copies with automatic migration
    Managed = c.ResourceStorageModeManaged,
    /// GPU-only memory
    Private = c.ResourceStorageModePrivate,
    /// Transient render targets
    Memoryless = c.ResourceStorageModeMemoryless,
};

/// Handle to the underlying Metal buffer
handle: ?*c.MetalBuffer,

/// Release the Metal buffer
pub fn deinit(self: Buffer) void {
    c.metal_buffer_release(self.handle);
}

/// Get the length of the buffer in bytes
pub fn getLength(self: Buffer) usize {
    return c.metal_buffer_get_length(self.handle);
}

/// Get a pointer to the buffer contents for CPU access
/// Only valid for buffers with Shared or Managed storage mode
pub fn getContents(self: Buffer) ?[*]u8 {
    const ptr = c.metal_buffer_get_contents(self.handle);
    if (ptr == null) return null;
    return @ptrCast(ptr);
}

/// Get a slice of the buffer contents for the entire buffer
/// Only valid for buffers with Shared or Managed storage mode
pub fn getContentsSlice(self: Buffer) ?[]u8 {
    const ptr = self.getContents();
    if (ptr == null) return null;

    const len = self.getLength();
    return ptr.?[0..len];
}

/// Indicate that a region of the buffer has been modified
/// Only needed for buffers with Managed storage mode
pub fn didModifyRange(self: Buffer, start: usize, length: usize) void {
    c.metal_buffer_did_modify_range(self.handle, start, length);
}

/// Copy data from a slice to the buffer
/// Only valid for buffers with Shared or Managed storage mode
pub fn copyFromSlice(self: Buffer, data: []const u8) MetalError!void {
    const contents = self.getContents() orelse return MetalError.BufferAccessFailed;
    const length = self.getLength();

    if (data.len > length) {
        return MetalError.BufferTooSmall;
    }

    @memcpy(contents[0..data.len], data);

    // For managed buffers, we need to inform Metal of the change
    // This is a no-op for shared buffers, so it's safe to always call
    self.didModifyRange(0, data.len);

    return;
}

test "Buffer functionality" {
    const metal = @import("../metal.zig");
    const Device = @import("Device.zig");

    try metal.init();
    defer metal.deinit();

    var device = try Device.createDefault();
    defer device.deinit();

    // Test buffer creation
    const buffer_size: usize = 1024;
    var buffer = try device.createBuffer(buffer_size, .Shared);
    defer buffer.deinit();

    // Test length
    try std.testing.expectEqual(buffer_size, buffer.getLength());

    // Test copy data
    const test_data = [_]u8{ 1, 2, 3, 4, 5 };
    try buffer.copyFromSlice(&test_data);

    // Verify data
    const contents = buffer.getContentsSlice() orelse {
        try std.testing.expect(false); // Should not fail
        unreachable;
    };

    try std.testing.expectEqualSlices(u8, &test_data, contents[0..test_data.len]);
}
