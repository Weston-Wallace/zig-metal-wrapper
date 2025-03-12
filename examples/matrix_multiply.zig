const std = @import("std");
const metal = @import("metal");

/// Matrix multiplication compute shader
const shader_source =
    \\#include <metal_stdlib>
    \\using namespace metal;
    \\
    \\kernel void matrix_multiply(
    \\    device const float* matrixA [[buffer(0)]],
    \\    device const float* matrixB [[buffer(1)]],
    \\    device float* result [[buffer(2)]],
    \\    constant uint& M [[buffer(3)]],
    \\    constant uint& N [[buffer(4)]],
    \\    constant uint& K [[buffer(5)]],
    \\    uint2 gid [[thread_position_in_grid]])
    \\{
    \\    // Ensure we're within the matrix bounds
    \\    if (gid.x >= N || gid.y >= M) return;
    \\    
    \\    // Compute the result for this position
    \\    float sum = 0.0;
    \\    for (uint k = 0; k < K; k++) {
    \\        sum += matrixA[gid.y * K + k] * matrixB[k * N + gid.x];
    \\    }
    \\    
    \\    // Write the result
    \\    result[gid.y * N + gid.x] = sum;
    \\}
;

/// Initialize a matrix with random values
fn initMatrix(matrix: []f32, seed: u64) void {
    var rng = std.Random.DefaultPrng.init(seed);
    var random = rng.random();
    for (0..matrix.len) |i| {
        matrix[i] = random.float(f32) * 10.0;
    }
}

/// Print a matrix (for small matrices or to sample large ones)
fn printMatrix(writer: anytype, matrix: []const f32, rows: usize, cols: usize, name: []const u8) !void {
    try writer.print("Matrix {s} ({d}x{d}):\n", .{ name, rows, cols });

    // For large matrices, just print a sample
    const max_display_rows = @min(rows, 6);
    const max_display_cols = @min(cols, 6);

    for (0..max_display_rows) |i| {
        for (0..max_display_cols) |j| {
            try writer.print("{d:.2}", .{matrix[i * cols + j]});
            if (j < max_display_cols - 1) {
                try writer.print("\t", .{});
            }
        }
        if (cols > max_display_cols) {
            try writer.print(" ...", .{});
        }
        try writer.print("\n", .{});
    }

    if (rows > max_display_rows) {
        try writer.print("...\n", .{});
    }
}

/// Compute matrix multiplication on CPU for verification
fn cpuMatrixMultiply(a: []const f32, b: []const f32, result: []f32, m: usize, n: usize, k: usize) void {
    for (0..m) |i| {
        for (0..n) |j| {
            var sum: f32 = 0.0;
            for (0..k) |l| {
                sum += a[i * k + l] * b[l * n + j];
            }
            result[i * n + j] = sum;
        }
    }
}

/// Compare matrices with a small relative tolerance for floating point differences
fn compareMatrices(a: []const f32, b: []const f32, tolerance: f32) bool {
    if (a.len != b.len) return false;

    for (0..a.len) |i| {
        const abs_diff = @abs(a[i] - b[i]);
        const rel_diff = abs_diff / @max(0.000001, @abs(a[i]));
        if (rel_diff > tolerance) {
            std.debug.print("Difference at index {d}: {d} vs {d}\n", .{ i, a[i], b[i] });
            return false;
        }
    }

    return true;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a Metal device
    var device = try metal.Device.createDefault();
    defer device.deinit();

    // Get device name
    const name = try device.getName(allocator);
    defer allocator.free(name);
    try stdout.print("Using Metal device: {s}\n", .{name});

    // Set matrix dimensions for the example
    const M: u32 = 640; // Rows in A and rows in result
    const N: u32 = 640; // Columns in B and columns in result
    const K: u32 = 320; // Columns in A and rows in B

    try stdout.print("Computing {d}x{d} * {d}x{d} matrix multiplication\n", .{ M, K, K, N });

    // Allocate matrices in host memory
    const a_size = M * K * @sizeOf(f32);
    const b_size = K * N * @sizeOf(f32);
    const result_size = M * N * @sizeOf(f32);

    const a_data = try allocator.alloc(f32, M * K);
    defer allocator.free(a_data);

    const b_data = try allocator.alloc(f32, K * N);
    defer allocator.free(b_data);

    const result_data = try allocator.alloc(f32, M * N);
    defer allocator.free(result_data);

    const cpu_result = try allocator.alloc(f32, M * N);
    defer allocator.free(cpu_result);

    // Initialize matrices with random data
    try stdout.print("Initializing matrices with random data...\n", .{});
    initMatrix(a_data, 42);
    initMatrix(b_data, 43);

    // Create GPU buffers
    try stdout.print("Creating GPU buffers...\n", .{});
    var buffer_a = try device.createBuffer(a_size, .Shared);
    defer buffer_a.deinit();

    var buffer_b = try device.createBuffer(b_size, .Shared);
    defer buffer_b.deinit();

    var buffer_result = try device.createBuffer(result_size, .Shared);
    defer buffer_result.deinit();

    // Create dimension buffers
    var buffer_m = try device.createBuffer(@sizeOf(u32), .Shared);
    defer buffer_m.deinit();

    var buffer_n = try device.createBuffer(@sizeOf(u32), .Shared);
    defer buffer_n.deinit();

    var buffer_k = try device.createBuffer(@sizeOf(u32), .Shared);
    defer buffer_k.deinit();

    // Copy matrix data to GPU
    try stdout.print("Copying matrices to GPU...\n", .{});
    try buffer_a.copyFromSlice(std.mem.sliceAsBytes(a_data));
    try buffer_b.copyFromSlice(std.mem.sliceAsBytes(b_data));

    // Copy dimension data to GPU
    const m_slice = buffer_m.getContentsSlice() orelse return error.BufferAccessFailed;
    const n_slice = buffer_n.getContentsSlice() orelse return error.BufferAccessFailed;
    const k_slice = buffer_k.getContentsSlice() orelse return error.BufferAccessFailed;

    std.mem.copyForwards(u8, m_slice, std.mem.asBytes(&M));
    std.mem.copyForwards(u8, n_slice, std.mem.asBytes(&N));
    std.mem.copyForwards(u8, k_slice, std.mem.asBytes(&K));

    // Compile the shader
    try stdout.print("Compiling matrix multiplication shader...\n", .{});
    const result_lib = try device.createLibraryFromSource(shader_source, allocator);

    // Check for compilation errors
    if (result_lib.error_msg) |err_msg| {
        defer allocator.free(err_msg);
        try stdout.print("ERROR: Shader compilation failed: {s}\n", .{err_msg});
        return error.ShaderCompilationFailed;
    }

    var library = result_lib.library;
    defer library.deinit();

    // Get compute function
    try stdout.print("Creating compute pipeline...\n", .{});
    var function = try library.getFunction("matrix_multiply", allocator);
    defer function.deinit();

    // Create compute pipeline
    var pipeline_state = try function.createComputePipelineState();
    defer pipeline_state.deinit();

    // Create command objects
    var command_queue = try device.createCommandQueue();
    defer command_queue.deinit();

    var command_buffer = try command_queue.createCommandBuffer();
    defer command_buffer.deinit();

    var encoder = try command_buffer.createComputeCommandEncoder();
    defer encoder.deinit();

    // Set up compute command
    encoder.setComputePipelineState(pipeline_state);
    encoder.setBuffer(buffer_a, 0, 0);
    encoder.setBuffer(buffer_b, 0, 1);
    encoder.setBuffer(buffer_result, 0, 2);
    encoder.setBuffer(buffer_m, 0, 3);
    encoder.setBuffer(buffer_n, 0, 4);
    encoder.setBuffer(buffer_k, 0, 5);

    // Dispatch threads - one thread per output element
    try stdout.print("Dispatching compute work for matrix multiplication...\n", .{});
    encoder.dispatchThreads(N, M, 1);
    encoder.endEncoding();

    // Execute the compute command
    command_buffer.commit();

    // Measure CPU computation time for comparison
    try stdout.print("Computing result on CPU for verification...\n", .{});
    const cpu_start = std.time.nanoTimestamp();
    cpuMatrixMultiply(a_data, b_data, cpu_result, M, N, K);
    const cpu_end = std.time.nanoTimestamp();
    const cpu_time_ms = @as(f64, @floatFromInt(cpu_end - cpu_start)) / std.time.ns_per_ms;

    // Wait for GPU computation to complete and measure time
    const gpu_start = std.time.nanoTimestamp();
    command_buffer.waitUntilCompleted();
    const gpu_end = std.time.nanoTimestamp();
    const gpu_time_ms = @as(f64, @floatFromInt(gpu_end - gpu_start)) / std.time.ns_per_ms;

    try stdout.print("GPU computation waited for: {d:.2} ms\n", .{gpu_time_ms});
    try stdout.print("CPU computation time: {d:.2} ms\n", .{cpu_time_ms});

    // Copy result back from GPU
    const result_slice = buffer_result.getContentsSlice() orelse return error.BufferAccessFailed;
    std.mem.copyForwards(u8, std.mem.sliceAsBytes(result_data), result_slice);

    // Verify the result by comparing with CPU computation
    try stdout.print("Verifying results...\n", .{});
    const is_correct = compareMatrices(result_data, cpu_result, 0.001);

    if (is_correct) {
        try stdout.print("✅ GPU matrix multiplication matches CPU result!\n", .{});
        try stdout.print("Speedup: {d:.2}x\n", .{cpu_time_ms / gpu_time_ms});
    } else {
        try stdout.print("❌ GPU matrix multiplication result doesn't match CPU result!\n", .{});
    }

    // Print a sample of the matrices for verification
    try stdout.print("\nMatrix preview:\n", .{});
    try printMatrix(stdout, a_data, M, K, "A");
    try stdout.print("\n", .{});
    try printMatrix(stdout, b_data, K, N, "B");
    try stdout.print("\n", .{});
    try printMatrix(stdout, result_data, M, N, "Result");
}
