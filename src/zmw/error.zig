/// Error type for Metal operations
pub const MetalError = error{
    // Initialization errors
    InitFailed,
    DeviceCreationFailed,
    DeviceNotSupported,
    NameFetchFailed,
    CommandQueueCreationFailed,
    OutOfMemory,

    // Buffer related errors
    BufferCreationFailed,
    BufferAccessFailed,
    BufferTooSmall,
    BufferCopyFailed,
    InvalidBufferOffset,
    InvalidBufferLength,

    // Shader related errors
    ShaderCompilationFailed,
    LibraryCreationFailed,
    FunctionNotFound,
    InvalidShaderSource,

    // Pipeline related errors
    PipelineCreationFailed,
    InvalidPipelineState,
    ThreadgroupSizeMismatch,

    // Command related errors
    CommandBufferCreationFailed,
    CommandEncoderCreationFailed,
    InvalidCommandState,
    CommandBufferAlreadyCommitted,

    // Execution related errors
    ExecutionFailed,
    ComputeDispatchFailed,
    InvalidThreadgroupSize,
    DeviceAccessDenied,
    AsyncCallbackFailed,
};
