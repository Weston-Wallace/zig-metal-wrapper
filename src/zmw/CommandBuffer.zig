const std = @import("std");
const c = @cImport({
    @cInclude("metal_wrapper.h");
});
const CommandBuffer = @This();

const MetalError = @import("error.zig").MetalError;
const ComputeCommandEncoder = @import("ComputeCommandEncoder.zig");

/// CommandBuffer status
pub const Status = enum(c_int) {
    NotCommitted = 0,
    Committed = 1,
    Scheduled = 2,
    Completed = 3,
    Error = 4,
    _,
};

/// Callback function type for command buffer completion
pub const CompletionCallback = struct {
    /// The function to call when the command buffer completes
    callback: *const fn (context: ?*anyopaque) void,
    /// Optional context pointer to pass to the callback
    context: ?*anyopaque = null,
};

handle: *c.MetalCommandBuffer,

/// Create a compute command encoder for this command buffer
pub fn createComputeCommandEncoder(self: CommandBuffer) MetalError!ComputeCommandEncoder {
    const encoder_handle = c.metal_command_buffer_create_compute_command_encoder(self.handle);
    if (encoder_handle == null) {
        return MetalError.CommandEncoderCreationFailed;
    }

    return ComputeCommandEncoder{
        .handle = encoder_handle.?,
    };
}

/// Commit the command buffer for execution
pub fn commit(self: CommandBuffer) void {
    c.metal_command_buffer_commit(self.handle);
}

/// C callback wrapper function - called by Metal when command buffer completes
fn callbackWrapper(context: ?*anyopaque) callconv(.C) void {
    if (context) |ctx| {
        const callback_struct = @as(*CompletionCallback, @ptrCast(@alignCast(ctx)));
        callback_struct.callback(callback_struct.context);
    }
}

/// Commit the command buffer with completion callback
pub fn commitWithCallback(self: CommandBuffer, completion: *CompletionCallback) void {
    c.metal_command_buffer_commit_with_callback(
        self.handle,
        callbackWrapper,
        completion,
    );
}

/// Wait until the command buffer has completed execution
pub fn waitUntilCompleted(self: CommandBuffer) void {
    c.metal_command_buffer_wait_until_completed(self.handle);
}

/// Get the current status of the command buffer
pub fn getStatus(self: CommandBuffer) Status {
    const status = c.metal_command_buffer_get_status(self.handle);
    return @enumFromInt(status);
}

/// Release the command buffer
pub fn deinit(self: *CommandBuffer) void {
    c.metal_command_buffer_release(self.handle);
}
