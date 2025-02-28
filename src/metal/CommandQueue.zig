const std = @import("std");
const c = @cImport({
    @cInclude("metal_wrapper.h");
});

const MetalError = @import("error.zig").MetalError;

handle: ?*c.MetalCommandQueue,

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
