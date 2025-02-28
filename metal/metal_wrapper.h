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

// Resource storage modes
typedef enum {
    ResourceStorageModeShared = 0,
    ResourceStorageModeManaged = 1,
    ResourceStorageModePrivate = 2,
    ResourceStorageModeMemoryless = 3
} ResourceStorageMode;

// Initialize Metal
int metal_init(void);

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

// Clean up Metal
void metal_cleanup(void);

#ifdef __cplusplus
}
#endif

#endif // METAL_WRAPPER_H