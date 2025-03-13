const std = @import("std");
const c = @cImport({
    @cInclude("metal_wrapper.h");
});
const ComputePipelineState = @This();

const MetalError = @import("error.zig").MetalError;
const Function = @import("Function.zig");

handle: *c.MetalComputePipelineState,

/// Create a new compute pipeline state object for the given function
pub fn create(function: Function) MetalError!ComputePipelineState {
    var error_msg: ?[*:0]u8 = null;
    const handle = c.metal_device_new_compute_pipeline_state(
        function.device_handle,
        function.handle,
        @ptrCast(&error_msg),
    );

    if (handle == null) {
        if (error_msg) |msg| {
            std.log.err("Failed to create compute pipeline state: {s}", .{msg});
            @import("utils.zig").freeCString(msg);
        }
        return MetalError.PipelineCreationFailed;
    }

    return ComputePipelineState{
        .handle = handle.?,
    };
}

/// Release the compute pipeline state resources
pub fn deinit(self: *ComputePipelineState) void {
    c.metal_compute_pipeline_state_release(self.handle);
}
