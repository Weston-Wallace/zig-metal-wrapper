# Zig Metal Wrapper

A Zig wrapper for Apple's Metal API, focusing on compute shaders.

## Prerequisites

To use this library, you must:

1. Generate the single header Metal.hpp file and place it in the metal directory.
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

## Implementation Plan

### Phase 1: Setup and Basic Initialization ✅

-   [x] Project structure
-   [x] Metal device creation
-   [x] Command queue creation
-   [x] Basic tests

### Phase 2: Buffer Management

-   [x] Create wrapper for MTLBuffer
-   [x] Create buffers (device memory)
-   [x] Map/unmap buffers for CPU access
-   [x] Copy data between CPU and GPU
-   [x] Handle different storage modes

### Phase 3: Shader Management

-   [x] Add support for loading Metal shaders
-   [x] Load shader source from string
-   [x] Compile shaders at runtime
-   [x] Error reporting for shader compilation
-   [x] Extract compute functions

### Phase 4: Compute Pipeline Creation ✅

-   [x] Create compute pipeline state objects
-   [x] Pipeline configuration
-   [x] Thread group size management
-   [x] Pipeline state caching

### Phase 5: Command Encoding ✅

-   [x] Command buffer creation
-   [x] Compute command encoder
-   [x] Setting compute pipeline
-   [x] Setting buffer arguments
-   [x] Dispatching compute work

### Phase 6: Execution and Synchronization ✅

-   [x] Command buffer submission
-   [x] Synchronous execution
-   [x] Asynchronous execution with completion handlers
-   [x] Handling computation results

### Phase 7: Error Handling and Examples ✅

-   [x] Comprehensive error handling
-   [x] Create example compute shaders
-   [x] Simple array operations
-   [x] More complex compute examples

### Phase 8: Advanced Features (Optional)

-   [ ] Heaps and memory management
-   [ ] Events and shared events
-   [ ] Indirect command buffers
-   [ ] Performance optimization

## Development Approach

Each phase should be implemented and tested before moving to the next:

1. Extend the C++ wrapper (`metal_wrapper.cpp` and `metal_wrapper.h`)
2. Create corresponding Zig modules and bindings
3. Add tests to verify functionality
4. Create small example programs demonstrating the new features

## Usage Example (Current)

```zig
const std = @import("std");
const metal = @import("metal");

pub fn main() !void {
    try metal.init();
    defer metal.deinit();

    var device = try metal.Device.createDefault();
    defer device.deinit();

    const name = try device.getName(allocator);
    defer allocator.free(name);

    std.debug.print("Metal device: {s}\n", .{name});
}
```

## Usage Example (Future - Compute Shader)

```zig
// This will be possible after implementation is complete
const std = @import("std");
const metal = @import("metal");

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

pub fn main() !void {
    // Initialize
    try metal.init();
    defer metal.deinit();

    // Setup device
    var device = try metal.Device.createDefault();
    defer device.deinit();

    // Create buffers
    const array_size = 1024;
    var buffer_a = try device.createBuffer(array_size * @sizeOf(f32), .StorageModeShared);
    defer buffer_a.deinit();

    // More code here...
}
```
