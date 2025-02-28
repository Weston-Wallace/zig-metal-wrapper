#define NS_PRIVATE_IMPLEMENTATION
#define CA_PRIVATE_IMPLEMENTATION
#define MTL_PRIVATE_IMPLEMENTATION
#include <Foundation/Foundation.hpp>
#include <Metal/Metal.hpp>
#include <QuartzCore/QuartzCore.hpp>
#include "metal_wrapper.h"
#include <cstring>

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

// Compute pipeline functions
MetalComputePipelineState* metal_device_new_compute_pipeline_state(MetalDevice* device, MetalFunction* function, char** error_msg) {
    if (!device || !function) return nullptr;
    
    MTL::Device* mtlDevice = reinterpret_cast<MTL::Device*>(device);
    MTL::Function* mtlFunction = reinterpret_cast<MTL::Function*>(function);
    NS::Error* error = nullptr;
    
    MTL::ComputePipelineState* pipelineState = mtlDevice->newComputePipelineState(mtlFunction, &error);
    
    // Handle error if pipeline creation failed
    if (error && error_msg) {
        const char* errorStr = error->localizedDescription()->utf8String();
        *error_msg = strdup(errorStr);
        error->release();
        return nullptr;
    }
    
    if (error) {
        error->release();
    }
    
    return reinterpret_cast<MetalComputePipelineState*>(pipelineState);
}

void metal_compute_pipeline_state_release(MetalComputePipelineState* state) {
    if (state) {
        MTL::ComputePipelineState* mtlState = reinterpret_cast<MTL::ComputePipelineState*>(state);
        mtlState->release();
    }
}

// Callback structure to hold the user callback and context
struct CallbackContext {
    MetalCommandBufferCallback user_callback;
    void* user_context;
};

// Static callback function for the Metal completion handler
static void metal_completion_handler(void* context) {
    CallbackContext* callback_context = static_cast<CallbackContext*>(context);
    if (callback_context && callback_context->user_callback) {
        callback_context->user_callback(callback_context->user_context);
    }
    delete callback_context;
}

// Command buffer functions
MetalCommandBuffer* metal_command_queue_create_command_buffer(MetalCommandQueue* queue) {
    if (!queue) return nullptr;
    
    MTL::CommandQueue* mtlQueue = reinterpret_cast<MTL::CommandQueue*>(queue);
    MTL::CommandBuffer* cmdBuffer = mtlQueue->commandBuffer();
    
    return reinterpret_cast<MetalCommandBuffer*>(cmdBuffer);
}

void metal_command_buffer_commit(MetalCommandBuffer* buffer) {
    if (!buffer) return;
    
    MTL::CommandBuffer* mtlBuffer = reinterpret_cast<MTL::CommandBuffer*>(buffer);
    mtlBuffer->commit();
}

void metal_command_buffer_commit_with_callback(MetalCommandBuffer* buffer, MetalCommandBufferCallback callback, void* context) {
    if (!buffer || !callback) return;
    
    MTL::CommandBuffer* mtlBuffer = reinterpret_cast<MTL::CommandBuffer*>(buffer);
    
    // Create a context that holds both the user callback and user context
    CallbackContext* callback_context = new CallbackContext{callback, context};
    
    // Set the completion handler using a C++ lambda that calls our static function
    mtlBuffer->addCompletedHandler([callback_context](MTL::CommandBuffer*) {
        metal_completion_handler(callback_context);
    });
    
    mtlBuffer->commit();
}

void metal_command_buffer_wait_until_completed(MetalCommandBuffer* buffer) {
    if (!buffer) return;
    
    MTL::CommandBuffer* mtlBuffer = reinterpret_cast<MTL::CommandBuffer*>(buffer);
    mtlBuffer->waitUntilCompleted();
}

int metal_command_buffer_get_status(MetalCommandBuffer* buffer) {
    if (!buffer) return -1;
    
    MTL::CommandBuffer* mtlBuffer = reinterpret_cast<MTL::CommandBuffer*>(buffer);
    return static_cast<int>(mtlBuffer->status());
}

void metal_command_buffer_release(MetalCommandBuffer* buffer) {
    if (buffer) {
        MTL::CommandBuffer* mtlBuffer = reinterpret_cast<MTL::CommandBuffer*>(buffer);
        mtlBuffer->release();
    }
}

// Compute command encoder functions
MetalComputeCommandEncoder* metal_command_buffer_create_compute_command_encoder(MetalCommandBuffer* buffer) {
    if (!buffer) return nullptr;
    
    MTL::CommandBuffer* mtlBuffer = reinterpret_cast<MTL::CommandBuffer*>(buffer);
    MTL::ComputeCommandEncoder* encoder = mtlBuffer->computeCommandEncoder();
    
    return reinterpret_cast<MetalComputeCommandEncoder*>(encoder);
}

void metal_compute_command_encoder_set_compute_pipeline_state(MetalComputeCommandEncoder* encoder, MetalComputePipelineState* state) {
    if (!encoder || !state) return;
    
    MTL::ComputeCommandEncoder* mtlEncoder = reinterpret_cast<MTL::ComputeCommandEncoder*>(encoder);
    MTL::ComputePipelineState* mtlState = reinterpret_cast<MTL::ComputePipelineState*>(state);
    
    mtlEncoder->setComputePipelineState(mtlState);
}

void metal_compute_command_encoder_set_buffer(MetalComputeCommandEncoder* encoder, MetalBuffer* buffer, unsigned long offset, unsigned int index) {
    if (!encoder || !buffer) return;
    
    MTL::ComputeCommandEncoder* mtlEncoder = reinterpret_cast<MTL::ComputeCommandEncoder*>(encoder);
    MTL::Buffer* mtlBuffer = reinterpret_cast<MTL::Buffer*>(buffer);
    
    mtlEncoder->setBuffer(mtlBuffer, offset, index);
}

void metal_compute_command_encoder_dispatch_threads(MetalComputeCommandEncoder* encoder, unsigned int threadCountX, unsigned int threadCountY, unsigned int threadCountZ) {
    if (!encoder) return;
    
    MTL::ComputeCommandEncoder* mtlEncoder = reinterpret_cast<MTL::ComputeCommandEncoder*>(encoder);
    MTL::Size gridSize = MTL::Size(threadCountX, threadCountY, threadCountZ);
    
    mtlEncoder->dispatchThreads(gridSize, MTL::Size(16, 1, 1)); // Using a default threadgroup size of 16x1x1
}

void metal_compute_command_encoder_end_encoding(MetalComputeCommandEncoder* encoder) {
    if (!encoder) return;
    
    MTL::ComputeCommandEncoder* mtlEncoder = reinterpret_cast<MTL::ComputeCommandEncoder*>(encoder);
    mtlEncoder->endEncoding();
}

void metal_compute_command_encoder_release(MetalComputeCommandEncoder* encoder) {
    if (encoder) {
        MTL::ComputeCommandEncoder* mtlEncoder = reinterpret_cast<MTL::ComputeCommandEncoder*>(encoder);
        mtlEncoder->release();
    }
}