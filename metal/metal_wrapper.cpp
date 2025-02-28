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

// Shader management functions
MetalLibrary* metal_device_create_library_from_source(MetalDevice* device, const char* source, char** error_msg) {
    if (!device || !source) return nullptr;
    
    MTL::Device* mtlDevice = reinterpret_cast<MTL::Device*>(device);
    NS::Error* error = nullptr;
    
    // Create a NSString from the C string
    NS::String* sourceStr = NS::String::string(source, NS::StringEncoding::UTF8StringEncoding);
    if (!sourceStr) return nullptr;
    
    // Create a Metal library from the source string
    MTL::Library* library = mtlDevice->newLibrary(sourceStr, nullptr, &error);
    
    // Handle error if compilation failed
    if (error && error_msg) {
        const char* errorStr = error->localizedDescription()->utf8String();
        *error_msg = strdup(errorStr);
        if (error) error->release();
        return nullptr;
    }
    
    if (error) {
        if (error) error->release();
    }
    
    return reinterpret_cast<MetalLibrary*>(library);
}

MetalFunction* metal_library_get_function(MetalLibrary* library, const char* name) {
    if (!library || !name) return nullptr;
    
    MTL::Library* mtlLibrary = reinterpret_cast<MTL::Library*>(library);
    NS::String* nameStr = NS::String::string(name, NS::StringEncoding::UTF8StringEncoding);
    if (!nameStr) return nullptr;
    
    MTL::Function* function = mtlLibrary->newFunction(nameStr);
    
    return reinterpret_cast<MetalFunction*>(function);
}

void metal_library_release(MetalLibrary* library) {
    if (library) {
        MTL::Library* mtlLibrary = reinterpret_cast<MTL::Library*>(library);
        mtlLibrary->release();
    }
}

void metal_function_release(MetalFunction* function) {
    if (function) {
        MTL::Function* mtlFunction = reinterpret_cast<MTL::Function*>(function);
        mtlFunction->release();
    }
}

const char* metal_function_get_name(MetalFunction* function) {
    if (!function) return nullptr;
    
    MTL::Function* mtlFunction = reinterpret_cast<MTL::Function*>(function);
    const char* originalName = mtlFunction->name()->utf8String();
    
    // We need to create a copy that the caller can free
    char* nameCopy = strdup(originalName);
    return nameCopy;
}

void metal_cleanup(void) {
    // Any cleanup if needed
}