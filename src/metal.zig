const std = @import("std");

// Re-export everything
pub const Device = @import("metal/Device.zig");
pub const CommandQueue = @import("metal/CommandQueue.zig");
pub const Buffer = @import("metal/Buffer.zig");
pub const Library = @import("metal/Library.zig");
pub const Function = @import("metal/Function.zig");
pub const MetalError = @import("metal/error.zig").MetalError;
pub const freeCString = @import("metal/utils.zig").freeCString;

// Export the main init/deinit functions
const c = @cImport({
    @cInclude("metal_wrapper.h");
});

pub fn init() MetalError!void {
    if (c.metal_init() != 1) {
        return MetalError.InitFailed;
    }
}

pub fn deinit() void {
    c.metal_cleanup();
}

// Re-export tests
test {
    // Run all tests from imported modules
    std.testing.refAllDeclsRecursive(@This());
}
