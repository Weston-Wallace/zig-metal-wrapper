const std = @import("std");
const zmw = @import("zmw");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a Metal device
    var device = try zmw.Device.createDefault();
    defer device.deinit();

    // Get device name
    const name = try device.getName(allocator);
    defer allocator.free(name);

    try stdout.print("Metal device name: {s}\n", .{name});
}
