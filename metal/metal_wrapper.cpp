#define NS_PRIVATE_IMPLEMENTATION
#define CA_PRIVATE_IMPLEMENTATION
#define MTL_PRIVATE_IMPLEMENTATION
#include "Metal.hpp"
#include "metal_wrapper.h"
#include <cstring>

int metal_init(void) {
    // Any initialization if needed
    return 1; // Success
}

MetalDevice* metal_create_default_device(void) {
    return reinterpret_cast<MetalDevice*>(MTL::CreateSystemDefaultDevice());
}

const char* metal_device_get_name(MetalDevice* device) {
    if (!device) return nullptr;
    
    MTL::Device* mtlDevice = reinterpret_cast<MTL::Device*>(device);
    const char* originalName = mtlDevice->name()->utf8String();
    
    // We need to create a copy that the caller can free
    char* nameCopy = strdup(originalName);
    return nameCopy;
}

MetalCommandQueue* metal_device_create_command_queue(MetalDevice* device) {
    if (!device) return nullptr;
    
    MTL::Device* mtlDevice = reinterpret_cast<MTL::Device*>(device);
    MTL::CommandQueue* queue = mtlDevice->newCommandQueue();
    
    return reinterpret_cast<MetalCommandQueue*>(queue);
}

void metal_command_queue_release(MetalCommandQueue* queue) {
    if (queue) {
        MTL::CommandQueue* mtlQueue = reinterpret_cast<MTL::CommandQueue*>(queue);
        mtlQueue->release();
    }
}

void metal_device_release(MetalDevice* device) {
    if (device) {
        MTL::Device* mtlDevice = reinterpret_cast<MTL::Device*>(device);
        mtlDevice->release();
    }
}

MetalBuffer* metal_device_create_buffer(MetalDevice* device, unsigned long length, ResourceStorageMode mode) {
    if (!device) return nullptr;
    
    MTL::Device* mtlDevice = reinterpret_cast<MTL::Device*>(device);
    
    MTL::ResourceOptions options;
    switch (mode) {
        case ResourceStorageModeShared:
            options = MTL::ResourceStorageModeShared;
            break;
        case ResourceStorageModeManaged:
            options = MTL::ResourceStorageModeManaged;
            break;
        case ResourceStorageModePrivate:
            options = MTL::ResourceStorageModePrivate;
            break;
        case ResourceStorageModeMemoryless:
            options = MTL::ResourceStorageModeMemoryless;
            break;
        default:
            options = MTL::ResourceStorageModeShared;
    }
    
    MTL::Buffer* buffer = mtlDevice->newBuffer(length, options);
    return reinterpret_cast<MetalBuffer*>(buffer);
}

void* metal_buffer_get_contents(MetalBuffer* buffer) {
    if (!buffer) return nullptr;
    
    MTL::Buffer* mtlBuffer = reinterpret_cast<MTL::Buffer*>(buffer);
    return mtlBuffer->contents();
}

unsigned long metal_buffer_get_length(MetalBuffer* buffer) {
    if (!buffer) return 0;
    
    MTL::Buffer* mtlBuffer = reinterpret_cast<MTL::Buffer*>(buffer);
    return mtlBuffer->length();
}

void metal_buffer_did_modify_range(MetalBuffer* buffer, unsigned long start, unsigned long length) {
    if (!buffer) return;
    
    MTL::Buffer* mtlBuffer = reinterpret_cast<MTL::Buffer*>(buffer);
    mtlBuffer->didModifyRange(NS::Range(start, length));
}

void metal_buffer_release(MetalBuffer* buffer) {
    if (buffer) {
        MTL::Buffer* mtlBuffer = reinterpret_cast<MTL::Buffer*>(buffer);
        mtlBuffer->release();
    }
}

void metal_cleanup(void) {
    // Any cleanup if needed
}