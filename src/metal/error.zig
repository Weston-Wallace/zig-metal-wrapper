pub const MetalError = error{
    InitFailed,
    DeviceCreationFailed,
    NameFetchFailed,
    CommandQueueCreationFailed,
    OutOfMemory,

    // Buffer related errors
    BufferCreationFailed,
    BufferAccessFailed,
    BufferTooSmall,

    // Future shader related errors
    ShaderCompilationFailed,
    LibraryCreationFailed,
    FunctionNotFound,

    // Pipeline related errors
    PipelineCreationFailed,

    // Command related errors
    CommandBufferCreationFailed,
    CommandEncoderCreationFailed,

    // Execution related errors
    ExecutionFailed,
};
