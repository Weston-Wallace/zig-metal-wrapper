# Zig Metal Wrapper

A Zig wrapper for Apple's Metal API, focusing on compute shaders.

## Prerequisites

To use this library, you must:

2. Have a macOS environment with Metal support.

## Current Status

The wrapper provides a complete solution for Metal compute operations:

-   Metal initialization and cleanup
-   Device creation and name querying
-   Command queue creation
-   Buffer creation and memory management
-   Shader loading and compilation
-   Compute pipeline state creation
-   Command encoding and execution
-   Synchronous and asynchronous execution
-   Comprehensive error handling
-   Multiple example applications from simple to advanced

## Usage Example (Current)

```zig
const std = @import("std");
const metal = @import("metal");

pub fn main() !void {
    var device = try metal.Device.createDefault();
    defer device.deinit();

    const name = try device.getName(allocator);
    defer allocator.free(name);

    std.debug.print("Metal device: {s}\n", .{name});
}
```

See the examples directory for more detailed examples.
