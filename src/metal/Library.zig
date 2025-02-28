const std = @import("std");
const c = @cImport({
    @cInclude("metal_wrapper.h");
});

const MetalError = @import("error.zig").MetalError;
const Function = @import("Function.zig");
const Device = @import("Device.zig");
const utils = @import("utils.zig");

/// Handle to the underlying Metal library
handle: ?*c.MetalLibrary,
/// Handle to the device that created this library (needed when creating functions)
device_handle: ?*c.MetalDevice,

/// Create a Metal shader library from source code
pub fn createFromSource(device: Device, source: []const u8, allocator: std.mem.Allocator) MetalError!struct {
    library: Library,
    error_msg: ?[]const u8,
} {
    // Create a null-terminated copy of the source
    const c_source = try allocator.dupeZ(u8, source);
    defer allocator.free(c_source);

    var error_ptr: ?[*c]u8 = null;
    const library_ptr = c.metal_device_create_library_from_source(device.handle, c_source.ptr, @ptrCast(&error_ptr));

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
                    .device_handle = device.handle,
                },
                .error_msg = error_str,
            };
        }
        return MetalError.LibraryCreationFailed;
    }

    return .{
        .library = Library{
            .handle = library_ptr,
            .device_handle = device.handle,
        },
        .error_msg = null,
    };
}

/// Get a function from the library by name
pub fn getFunction(self: Library, name: []const u8, allocator: std.mem.Allocator) MetalError!Function {
    // Create a null-terminated copy of the name
    const c_name = try allocator.dupeZ(u8, name);
    defer allocator.free(c_name);

    const function_ptr = c.metal_library_get_function(self.handle, c_name.ptr);
    if (function_ptr == null) {
        return MetalError.FunctionNotFound;
    }

    return Function{
        .handle = function_ptr,
        .device_handle = self.device_handle,
    };
}

/// Release the Metal library
pub fn deinit(self: Library) void {
    c.metal_library_release(self.handle);
}

const Library = @This();

test "Library from source" {
    const allocator = std.testing.allocator;

    var device = try Device.createDefault();
    defer device.deinit();

    // Simple compute shader
    const shader_source =
        \\#include <metal_stdlib>
        \\using namespace metal;
        \\
        \\kernel void add_arrays(device const float* inA,
        \\                       device const float* inB,
        \\                       device float* result,
        \\                       uint index [[thread_position_in_grid]])
        \\{
        \\    result[index] = inA[index] + inB[index];
        \\}
    ;

    // Create library
    const result = try Library.createFromSource(device, shader_source, allocator);
    if (result.error_msg) |err_msg| {
        defer allocator.free(err_msg);
        std.debug.print("Shader compilation error: {s}\n", .{err_msg});
        try std.testing.expect(false); // Should not fail
    }

    var library = result.library;
    defer library.deinit();

    // Get function
    var function = try library.getFunction("add_arrays", allocator);
    defer function.deinit();

    // Check function name
    const func_name = try function.getName(allocator);
    defer allocator.free(func_name);

    try std.testing.expectEqualStrings("add_arrays", func_name);
}
