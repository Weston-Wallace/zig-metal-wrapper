#ifndef METAL_WRAPPER_H
#define METAL_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

// Opaque pointers to Metal objects
typedef struct MetalDevice MetalDevice;
typedef struct MetalCommandQueue MetalCommandQueue;

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

// Clean up Metal
void metal_cleanup(void);

#ifdef __cplusplus
}
#endif

#endif // METAL_WRAPPER_H