// llama_wrapper.h
// Clean C API wrapper for llama.cpp to be used with Flutter FFI
// This header exposes the minimal interface needed for mobile inference

#ifndef LLAMA_WRAPPER_H
#define LLAMA_WRAPPER_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Export macro for shared library
#if defined(_WIN32) || defined(__CYGWIN__)
    #define LLAMA_API __declspec(dllexport)
#else
    #define LLAMA_API __attribute__((visibility("default")))
#endif

// Opaque context pointer for the loaded model
typedef void* LlamaContext;

// Callback function type for streaming tokens
// Called for each generated token during inference
// Returns: 0 to continue, non-zero to stop generation
typedef int (*TokenCallback)(const char* token, void* user_data);

// ============================================================================
// Core API Functions
// ============================================================================

// Initialize the llama backend (call once at app start)
LLAMA_API void llama_wrapper_init(void);

// Cleanup the llama backend (call once at app shutdown)
LLAMA_API void llama_wrapper_cleanup(void);

// Load a GGUF model from the specified path
// Parameters:
//   model_path: Full path to the .gguf model file
//   n_ctx: Context size (default 2048, use 0 for default)
//   n_gpu_layers: Number of layers to offload to GPU (0 for CPU only)
// Returns: Context pointer on success, NULL on failure
LLAMA_API LlamaContext llama_wrapper_load_model(
    const char* model_path,
    int n_ctx,
    int n_gpu_layers
);

// Unload a model and free all associated resources
// Parameters:
//   ctx: Context pointer returned by llama_wrapper_load_model
LLAMA_API void llama_wrapper_unload_model(LlamaContext ctx);

// Generate text from a prompt with streaming callback
// Parameters:
//   ctx: Context pointer from llama_wrapper_load_model
//   prompt: Input text prompt
//   max_tokens: Maximum number of tokens to generate
//   temperature: Sampling temperature (0.0 = greedy, higher = more random)
//   top_p: Top-p (nucleus) sampling parameter
//   callback: Function called for each generated token
//   user_data: User data passed to callback
// Returns: 0 on success, negative on error
LLAMA_API int llama_wrapper_generate(
    LlamaContext ctx,
    const char* prompt,
    int max_tokens,
    float temperature,
    float top_p,
    TokenCallback callback,
    void* user_data
);

// Request cancellation of ongoing generation
// Safe to call from any thread
LLAMA_API void llama_wrapper_cancel_generate(LlamaContext ctx);

// Check if a model is currently loaded
LLAMA_API bool llama_wrapper_is_model_loaded(LlamaContext ctx);

// Get the last error message
LLAMA_API const char* llama_wrapper_get_error(void);

// Get model info (returns JSON string, caller must not free)
LLAMA_API const char* llama_wrapper_get_model_info(LlamaContext ctx);

#ifdef __cplusplus
}
#endif

#endif // LLAMA_WRAPPER_H
