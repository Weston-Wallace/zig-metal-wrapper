const std = @import("std");

pub const Device = @import("metal/Device.zig");
pub const CommandQueue = @import("metal/CommandQueue.zig");
pub const Buffer = @import("metal/Buffer.zig");
pub const Library = @import("metal/Library.zig");
pub const Function = @import("metal/Function.zig");
pub const ComputePipelineState = @import("metal/ComputePipelineState.zig");
pub const CommandBuffer = @import("metal/CommandBuffer.zig");
pub const ComputeCommandEncoder = @import("metal/ComputeCommandEncoder.zig");
pub const MetalError = @import("metal/error.zig").MetalError;
pub const freeCString = @import("metal/utils.zig").freeCString;

// Re-export tests
test {
    // Run all tests from imported modules
    std.testing.refAllDeclsRecursive(@This());
}
