#include <metal_stdlib>
using namespace metal;

kernel void double_values(device float* data [[buffer(0)]],
                         uint id [[thread_position_in_grid]])
{
    data[id] = data[id] * 2.0;
}