const std = @import("std");

/// Free a C string that was allocated by the Metal wrapper
pub fn freeCString(ptr: [*c]const u8) void {
    std.c.free(@constCast(@ptrCast(ptr)));
}
