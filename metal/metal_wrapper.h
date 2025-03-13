#ifndef METAL_WRAPPER_H
#define METAL_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

// Opaque pointers to Metal objects
typedef struct MetalDevice MetalDevice;
typedef struct MetalCommandQueue MetalCommandQueue;
typedef struct MetalBuffer MetalBuffer;
typedef struct MetalLibrary MetalLibrary;
typedef struct MetalFunction MetalFunction;
typedef struct MetalComputePipelineState MetalComputePipelineState;
typedef struct MetalCommandBuffer MetalCommandBuffer;
typedef struct MetalComputeCommandEncoder MetalComputeCommandEncoder;

// Resource storage modes
typedef enum {
    ResourceStorageModeShared = 0,
    ResourceStorageModeManaged = 1,
    ResourceStorageModePrivate = 2,
    ResourceStorageModeMemoryless = 3
} ResourceStorageMode;

// Create a default Metal device
MetalDevice* metal_create_default_device(void);

// Get device name (caller must free the returned string)
const char* metal_device_get_name(MetalDevice* device);

// Create a command queue for the device
MetalCommandQueue* metal_device_create_command_queue(MetalDevice* device);

// Release a command queue
void metal_command_queue_release(MetalCommandQueue* queue);

// Release a Metal device
void metal_device_release(MetalDevice* device);

// Buffer functions
MetalBuffer* metal_device_create_buffer(MetalDevice* device, unsigned long length, ResourceStorageMode mode);
void* metal_buffer_get_contents(MetalBuffer* buffer);
unsigned long metal_buffer_get_length(MetalBuffer* buffer);
void metal_buffer_did_modify_range(MetalBuffer* buffer, unsigned long start, unsigned long length);
void metal_buffer_release(MetalBuffer* buffer);

// Shader management functions
MetalLibrary* metal_device_create_library_from_source(MetalDevice* device, const char* source, char** error_msg);
MetalFunction* metal_library_get_function(MetalLibrary* library, const char* name);
void metal_library_release(MetalLibrary* library);
void metal_function_release(MetalFunction* function);
const char* metal_function_get_name(MetalFunction* function);

// Compute pipeline functions
MetalComputePipelineState* metal_device_new_compute_pipeline_state(MetalDevice* device, MetalFunction* function, char** error_msg);
void metal_compute_pipeline_state_release(MetalComputePipelineState* state);

// Callback function type for command buffer completion
typedef void (*MetalCommandBufferCallback)(void* context);

// Command buffer functions
MetalCommandBuffer* metal_command_queue_create_command_buffer(MetalCommandQueue* queue);
void metal_command_buffer_commit(MetalCommandBuffer* buffer);
void metal_command_buffer_commit_with_callback(MetalCommandBuffer* buffer, MetalCommandBufferCallback callback, void* context);
void metal_command_buffer_wait_until_completed(MetalCommandBuffer* buffer);
int metal_command_buffer_get_status(MetalCommandBuffer* buffer); // 0=not-committed, 1=committed, 2=scheduled, 3=completed, 4=error
void metal_command_buffer_release(MetalCommandBuffer* buffer);

// Compute command encoder functions
MetalComputeCommandEncoder* metal_command_buffer_create_compute_command_encoder(MetalCommandBuffer* buffer);
void metal_compute_command_encoder_set_compute_pipeline_state(MetalComputeCommandEncoder* encoder, MetalComputePipelineState* state);
void metal_compute_command_encoder_set_buffer(MetalComputeCommandEncoder* encoder, MetalBuffer* buffer, unsigned long offset, unsigned int index);
void metal_compute_command_encoder_set_bytes(MetalComputeCommandEncoder* encoder, const void* bytes, unsigned long length, unsigned int index);
void metal_compute_command_encoder_dispatch_threads(MetalComputeCommandEncoder* encoder, unsigned int threadCountX, unsigned int threadCountY, unsigned int threadCountZ);
void metal_compute_command_encoder_end_encoding(MetalComputeCommandEncoder* encoder);
void metal_compute_command_encoder_release(MetalComputeCommandEncoder* encoder);

#ifdef __cplusplus
}
#endif

#endif // METAL_WRAPPER_H