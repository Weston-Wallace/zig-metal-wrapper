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

void metal_cleanup(void) {
    // Any cleanup if needed
}