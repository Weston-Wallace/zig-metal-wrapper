#ifndef METAL_WRAPPER_H
#define METAL_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

// Opaque pointer to Metal device
typedef struct MetalDevice MetalDevice;

// Initialize Metal
int metal_init(void);

// Create a default Metal device
MetalDevice* metal_create_default_device(void);

// Get device name (caller must free the returned string)
const char* metal_device_get_name(MetalDevice* device);

// Release a Metal device
void metal_device_release(MetalDevice* device);

// Clean up Metal
void metal_cleanup(void);

#ifdef __cplusplus
}
#endif

#endif // METAL_WRAPPER_H
