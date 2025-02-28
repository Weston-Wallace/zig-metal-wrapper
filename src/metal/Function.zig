const std = @import("std");
const c = @cImport({
    @cInclude("metal_wrapper.h");
});

const MetalError = @import("error.zig").MetalError;
const utils = @import("utils.zig");
const ComputePipelineState = @import("ComputePipelineState.zig");

/// Handle to the underlying Metal function
handle: ?*c.MetalFunction,
/// Handle to the device that created this function (needed for creating pipeline states)
device_handle: ?*c.MetalDevice,

/// Get the name of the function
/// Caller owns the returned memory and must free it with allocator.free()
pub fn getName(self: Function, allocator: std.mem.Allocator) MetalError![]const u8 {
    const name_ptr = c.metal_function_get_name(self.handle);
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

/// Release the Metal function
pub fn deinit(self: Function) void {
    c.metal_function_release(self.handle);
}

/// Create a compute pipeline state for this function
pub fn createComputePipelineState(self: Function) MetalError!ComputePipelineState {
    return ComputePipelineState.create(self);
}

const Function = @This();

test "Function basic test" {
    const Device = @import("Device.zig");
    const Library = @import("Library.zig");
    const allocator = std.testing.allocator;

    var device = try Device.createDefault();
    defer device.deinit();

    // Simple compute shader
    const shader_source =
        \\#include <metal_stdlib>
        \\using namespace metal;
        \\
        \\kernel void test_function(device int* data [[buffer(0)]],
        \\                         uint id [[thread_position_in_grid]])
        \\{
        \\    data[id] = data[id] * 2;
        \\}
    ;

    // Create library
    const result = try Library.createFromSource(device, shader_source, allocator);
    if (result.error_msg) |err_msg| {
        defer allocator.free(err_msg);
        return error.ShaderCompilationFailed;
    }

    var library = result.library;
    defer library.deinit();

    // Get function
    var function = try library.getFunction("test_function", allocator);
    defer function.deinit();

    // Get function name
    const name = try function.getName(allocator);
    defer allocator.free(name);

    try std.testing.expectEqualStrings("test_function", name);
}
