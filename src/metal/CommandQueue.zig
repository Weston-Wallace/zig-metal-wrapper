const std = @import("std");
const c = @cImport({
    @cInclude("metal_wrapper.h");
});

const MetalError = @import("error.zig").MetalError;
const CommandBuffer = @import("CommandBuffer.zig");

handle: ?*c.MetalCommandQueue,

/// Create a command buffer for the command queue
pub fn createCommandBuffer(self: CommandQueue) MetalError!CommandBuffer {
    const buffer_handle = c.metal_command_queue_create_command_buffer(self.handle);
    if (buffer_handle == null) {
        return MetalError.CommandBufferCreationFailed;
    }
    
    return CommandBuffer{
        .handle = buffer_handle.?,
    };
}

/// Release the command queue
pub fn deinit(self: CommandQueue) void {
    c.metal_command_queue_release(self.handle);
}

const CommandQueue = @This();

test "CommandQueue functionality" {
    const metal = @import("../metal.zig");
    const Device = @import("Device.zig");

    try metal.init();
    defer metal.deinit();

    var device = try Device.createDefault();
    defer device.deinit();

    var queue = try device.createCommandQueue();
    defer queue.deinit();
}
