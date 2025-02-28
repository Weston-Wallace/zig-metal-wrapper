const std = @import("std");
const c = @cImport({
    @cInclude("metal_wrapper.h");
});
const ComputeCommandEncoder = @This();

const MetalError = @import("error.zig").MetalError;
const ComputePipelineState = @import("ComputePipelineState.zig");
const Buffer = @import("Buffer.zig");

handle: *c.MetalComputeCommandEncoder,

/// Set the compute pipeline state to use for this encoder
pub fn setComputePipelineState(self: ComputeCommandEncoder, pipeline_state: ComputePipelineState) void {
    c.metal_compute_command_encoder_set_compute_pipeline_state(self.handle, pipeline_state.handle);
}

/// Set a buffer as an argument for the compute function
pub fn setBuffer(self: ComputeCommandEncoder, buffer: Buffer, offset: usize, index: u32) void {
    c.metal_compute_command_encoder_set_buffer(self.handle, buffer.handle, offset, index);
}

/// Dispatch threads for the compute operation
pub fn dispatchThreads(self: ComputeCommandEncoder, thread_count_x: u32, thread_count_y: u32, thread_count_z: u32) void {
    c.metal_compute_command_encoder_dispatch_threads(
        self.handle,
        thread_count_x,
        thread_count_y,
        thread_count_z
    );
}

/// End the compute command encoding
pub fn endEncoding(self: ComputeCommandEncoder) void {
    c.metal_compute_command_encoder_end_encoding(self.handle);
}

/// Release the compute command encoder
pub fn deinit(self: *ComputeCommandEncoder) void {
    c.metal_compute_command_encoder_release(self.handle);
}

test "computeCommandEncoder.dispatch" {
    // This would need a valid encoder to test with
}