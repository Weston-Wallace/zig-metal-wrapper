// Use standard macOS SDK headers instead of Metal-cpp
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#include "metal_wrapper.h"
#include <string.h>

MetalDevice* metal_create_default_device(void) {
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    return (MetalDevice*)device;
}

const char* metal_device_get_name(MetalDevice* device) {
    if (!device) return NULL;
    
    id<MTLDevice> mtlDevice = (id<MTLDevice>)device;
    NSString* name = [mtlDevice name];
    
    // Create a copy that the caller can free
    const char* originalName = [name UTF8String];
    char* nameCopy = strdup(originalName);
    return nameCopy;
}

MetalCommandQueue* metal_device_create_command_queue(MetalDevice* device) {
    if (!device) return NULL;
    
    id<MTLDevice> mtlDevice = (id<MTLDevice>)device;
    id<MTLCommandQueue> queue = [mtlDevice newCommandQueue];
    
    return (MetalCommandQueue*)queue;
}

void metal_command_queue_release(MetalCommandQueue* queue) {
    if (queue) {
        [(id<MTLCommandQueue>)queue release];
    }
}

void metal_device_release(MetalDevice* device) {
    if (device) {
        [(id<MTLDevice>)device release];
    }
}

MetalBuffer* metal_device_create_buffer(MetalDevice* device, unsigned long length, ResourceStorageMode mode) {
    if (!device) return NULL;
    
    id<MTLDevice> mtlDevice = (id<MTLDevice>)device;
    
    MTLResourceOptions options;
    switch (mode) {
        case ResourceStorageModeShared:
            options = MTLResourceStorageModeShared;
            break;
        case ResourceStorageModeManaged:
            options = MTLResourceStorageModeManaged;
            break;
        case ResourceStorageModePrivate:
            options = MTLResourceStorageModePrivate;
            break;
        case ResourceStorageModeMemoryless:
            options = MTLResourceStorageModeMemoryless;
            break;
        default:
            options = MTLResourceStorageModeShared;
    }
    
    id<MTLBuffer> buffer = [mtlDevice newBufferWithLength:length options:options];
    return (MetalBuffer*)buffer;
}

void* metal_buffer_get_contents(MetalBuffer* buffer) {
    if (!buffer) return NULL;
    
    id<MTLBuffer> mtlBuffer = (id<MTLBuffer>)buffer;
    return [mtlBuffer contents];
}

unsigned long metal_buffer_get_length(MetalBuffer* buffer) {
    if (!buffer) return 0;
    
    id<MTLBuffer> mtlBuffer = (id<MTLBuffer>)buffer;
    return [mtlBuffer length];
}

void metal_buffer_did_modify_range(MetalBuffer* buffer, unsigned long start, unsigned long length) {
    if (!buffer) return;
    
    id<MTLBuffer> mtlBuffer = (id<MTLBuffer>)buffer;
    [mtlBuffer didModifyRange:NSMakeRange(start, length)];
}

void metal_buffer_release(MetalBuffer* buffer) {
    if (buffer) {
        [(id<MTLBuffer>)buffer release];
    }
}

// Shader management functions
MetalLibrary* metal_device_create_library_from_source(MetalDevice* device, const char* source, char** error_msg) {
    if (!device || !source) return NULL;
    
    id<MTLDevice> mtlDevice = (id<MTLDevice>)device;
    NSError* error = nil;
    
    // Create a NSString from the C string
    NSString* sourceStr = [NSString stringWithUTF8String:source];
    if (!sourceStr) return NULL;
    
    // Create a Metal library from the source string
    MTLCompileOptions* options = [[MTLCompileOptions alloc] init];
    id<MTLLibrary> library = [mtlDevice newLibraryWithSource:sourceStr
                                                     options:options
                                                       error:&error];
    [options release]; // Manual release
    
    // Handle error if compilation failed
    if (error && error_msg) {
        const char* errorStr = [[error localizedDescription] UTF8String];
        *error_msg = strdup(errorStr);
        return NULL;
    }
    
    return (MetalLibrary*)library;
}

MetalFunction* metal_library_get_function(MetalLibrary* library, const char* name) {
    if (!library || !name) return NULL;
    
    id<MTLLibrary> mtlLibrary = (id<MTLLibrary>)library;
    NSString* nameStr = [NSString stringWithUTF8String:name];
    if (!nameStr) return NULL;
    
    id<MTLFunction> function = [mtlLibrary newFunctionWithName:nameStr];
    
    return (MetalFunction*)function;
}

void metal_library_release(MetalLibrary* library) {
    if (library) {
        [(id<MTLLibrary>)library release];
    }
}

void metal_function_release(MetalFunction* function) {
    if (function) {
        [(id<MTLFunction>)function release];
    }
}

const char* metal_function_get_name(MetalFunction* function) {
    if (!function) return NULL;
    
    id<MTLFunction> mtlFunction = (id<MTLFunction>)function;
    const char* originalName = [[mtlFunction name] UTF8String];
    
    // We need to create a copy that the caller can free
    char* nameCopy = strdup(originalName);
    return nameCopy;
}

// Compute pipeline functions
MetalComputePipelineState* metal_device_new_compute_pipeline_state(MetalDevice* device, MetalFunction* function, char** error_msg) {
    if (!device || !function) return NULL;
    
    id<MTLDevice> mtlDevice = (id<MTLDevice>)device;
    id<MTLFunction> mtlFunction = (id<MTLFunction>)function;
    NSError* error = nil;
    
    id<MTLComputePipelineState> pipelineState = [mtlDevice newComputePipelineStateWithFunction:mtlFunction 
                                                                                         error:&error];
    
    // Handle error if pipeline creation failed
    if (error && error_msg) {
        const char* errorStr = [[error localizedDescription] UTF8String];
        *error_msg = strdup(errorStr);
        return NULL;
    }
    
    return (MetalComputePipelineState*)pipelineState;
}

void metal_compute_pipeline_state_release(MetalComputePipelineState* state) {
    if (state) {
        [(id<MTLComputePipelineState>)state release];
    }
}

// Structure to store the callback context
typedef struct {
    MetalCommandBufferCallback user_callback;
    void* user_context;
} CallbackContext;

// Command buffer functions
MetalCommandBuffer* metal_command_queue_create_command_buffer(MetalCommandQueue* queue) {
    if (!queue) return NULL;
    
    id<MTLCommandQueue> mtlQueue = (id<MTLCommandQueue>)queue;
    id<MTLCommandBuffer> cmdBuffer = [mtlQueue commandBuffer];
    
    return (MetalCommandBuffer*)cmdBuffer;
}

void metal_command_buffer_commit(MetalCommandBuffer* buffer) {
    if (!buffer) return;
    
    id<MTLCommandBuffer> mtlBuffer = (id<MTLCommandBuffer>)buffer;
    [mtlBuffer commit];
}

void metal_command_buffer_commit_with_callback(MetalCommandBuffer* buffer, MetalCommandBufferCallback callback, void* context) {
    if (!buffer || !callback) return;
    
    id<MTLCommandBuffer> mtlBuffer = (id<MTLCommandBuffer>)buffer;
    
    // Create a context that holds both the user callback and user context
    CallbackContext* callback_context = (CallbackContext*)malloc(sizeof(CallbackContext));
    callback_context->user_callback = callback;
    callback_context->user_context = context;
    
    // Add completion handler
    [mtlBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull) {
        // Call the user callback
        if (callback_context->user_callback) {
            callback_context->user_callback(callback_context->user_context);
        }
        
        // Free the callback context
        free(callback_context);
    }];
    
    [mtlBuffer commit];
}

void metal_command_buffer_wait_until_completed(MetalCommandBuffer* buffer) {
    if (!buffer) return;
    
    id<MTLCommandBuffer> mtlBuffer = (id<MTLCommandBuffer>)buffer;
    [mtlBuffer waitUntilCompleted];
}

int metal_command_buffer_get_status(MetalCommandBuffer* buffer) {
    if (!buffer) return -1;
    
    id<MTLCommandBuffer> mtlBuffer = (id<MTLCommandBuffer>)buffer;
    return (int)[mtlBuffer status];
}

void metal_command_buffer_release(MetalCommandBuffer* buffer) {
    if (buffer) {
        [(id<MTLCommandBuffer>)buffer release];
    }
}

// Compute command encoder functions
MetalComputeCommandEncoder* metal_command_buffer_create_compute_command_encoder(MetalCommandBuffer* buffer) {
    if (!buffer) return NULL;
    
    id<MTLCommandBuffer> mtlBuffer = (id<MTLCommandBuffer>)buffer;
    id<MTLComputeCommandEncoder> encoder = [mtlBuffer computeCommandEncoder];
    
    return (MetalComputeCommandEncoder*)encoder;
}

void metal_compute_command_encoder_set_compute_pipeline_state(MetalComputeCommandEncoder* encoder, MetalComputePipelineState* state) {
    if (!encoder || !state) return;
    
    id<MTLComputeCommandEncoder> mtlEncoder = (id<MTLComputeCommandEncoder>)encoder;
    id<MTLComputePipelineState> mtlState = (id<MTLComputePipelineState>)state;
    
    [mtlEncoder setComputePipelineState:mtlState];
}

void metal_compute_command_encoder_set_buffer(MetalComputeCommandEncoder* encoder, MetalBuffer* buffer, unsigned long offset, unsigned int index) {
    if (!encoder || !buffer) return;
    
    id<MTLComputeCommandEncoder> mtlEncoder = (id<MTLComputeCommandEncoder>)encoder;
    id<MTLBuffer> mtlBuffer = (id<MTLBuffer>)buffer;
    
    [mtlEncoder setBuffer:mtlBuffer offset:offset atIndex:index];
}

void metal_compute_command_encoder_set_bytes(MetalComputeCommandEncoder* encoder, const void* bytes, unsigned long length, unsigned int index) {
    if (!encoder || !bytes) return;
    id<MTLComputeCommandEncoder> mtlEncoder = (id<MTLComputeCommandEncoder>)encoder;

    [mtlEncoder setBytes:bytes length:length atIndex:index];
}

void metal_compute_command_encoder_dispatch_threads(MetalComputeCommandEncoder* encoder, unsigned int threadCountX, unsigned int threadCountY, unsigned int threadCountZ) {
    if (!encoder) return;
    
    id<MTLComputeCommandEncoder> mtlEncoder = (id<MTLComputeCommandEncoder>)encoder;
    MTLSize gridSize = MTLSizeMake(threadCountX, threadCountY, threadCountZ);
    MTLSize threadgroupSize = MTLSizeMake(16, 1, 1); // Using a default threadgroup size of 16x1x1
    
    [mtlEncoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
}

void metal_compute_command_encoder_end_encoding(MetalComputeCommandEncoder* encoder) {
    if (!encoder) return;
    
    id<MTLComputeCommandEncoder> mtlEncoder = (id<MTLComputeCommandEncoder>)encoder;
    [mtlEncoder endEncoding];
}

void metal_compute_command_encoder_release(MetalComputeCommandEncoder* encoder) {
    if (encoder) {
        [(id<MTLComputeCommandEncoder>)encoder release];
    }
}