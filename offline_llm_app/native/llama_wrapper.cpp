// llama_wrapper.cpp
// Implementation of the clean C API wrapper for llama.cpp
// Provides thread-safe inference with streaming support for Flutter FFI

#include "llama_wrapper.h"
#include "llama.h"
#include "common.h"

#include <string>
#include <vector>
#include <mutex>
#include <atomic>
#include <cstring>

// ============================================================================
// Internal State
// ============================================================================

// Thread-safe error message storage
static std::string g_last_error;
static std::mutex g_error_mutex;

// Model info cache
static std::string g_model_info;

// Internal context structure holding all llama.cpp state
struct LlamaContextInternal {
    llama_model* model = nullptr;
    llama_context* ctx = nullptr;
    llama_sampler* sampler = nullptr;
    std::atomic<bool> cancel_requested{false};
    std::mutex generate_mutex;
    std::string model_path;
    int n_ctx = 2048;
};

// ============================================================================
// Helper Functions
// ============================================================================

static void set_error(const std::string& error) {
    std::lock_guard<std::mutex> lock(g_error_mutex);
    g_last_error = error;
}

static void clear_error() {
    std::lock_guard<std::mutex> lock(g_error_mutex);
    g_last_error.clear();
}

// ============================================================================
// API Implementation
// ============================================================================

LLAMA_API void llama_wrapper_init(void) {
    // Initialize llama backend
    llama_backend_init();
    clear_error();
}

LLAMA_API void llama_wrapper_cleanup(void) {
    llama_backend_free();
}

LLAMA_API LlamaContext llama_wrapper_load_model(
    const char* model_path,
    int n_ctx,
    int n_gpu_layers
) {
    clear_error();
    
    if (!model_path || strlen(model_path) == 0) {
        set_error("Model path is empty");
        return nullptr;
    }
    
    // Create internal context
    auto* internal = new LlamaContextInternal();
    internal->model_path = model_path;
    internal->n_ctx = (n_ctx > 0) ? n_ctx : 2048;
    
    // Configure model parameters
    llama_model_params model_params = llama_model_default_params();
    model_params.n_gpu_layers = n_gpu_layers;
    
    // Load the model
    internal->model = llama_model_load_from_file(model_path, model_params);
    if (!internal->model) {
        set_error("Failed to load model from: " + std::string(model_path));
        delete internal;
        return nullptr;
    }
    
    // Configure context parameters
    llama_context_params ctx_params = llama_context_default_params();
    ctx_params.n_ctx = internal->n_ctx;
    ctx_params.n_batch = 512;
    ctx_params.n_threads = 4;  // Good default for mobile
    ctx_params.n_threads_batch = 4;
    
    // Create the context
    internal->ctx = llama_init_from_model(internal->model, ctx_params);
    if (!internal->ctx) {
        set_error("Failed to create llama context");
        llama_free_model(internal->model);
        delete internal;
        return nullptr;
    }
    
    return static_cast<LlamaContext>(internal);
}

LLAMA_API void llama_wrapper_unload_model(LlamaContext ctx) {
    if (!ctx) return;
    
    auto* internal = static_cast<LlamaContextInternal*>(ctx);
    
    // Wait for any ongoing generation to finish
    std::lock_guard<std::mutex> lock(internal->generate_mutex);
    
    if (internal->sampler) {
        llama_sampler_free(internal->sampler);
        internal->sampler = nullptr;
    }
    
    if (internal->ctx) {
        llama_free(internal->ctx);
        internal->ctx = nullptr;
    }
    
    if (internal->model) {
        llama_model_free(internal->model);
        internal->model = nullptr;
    }
    
    delete internal;
}

LLAMA_API int llama_wrapper_generate(
    LlamaContext ctx,
    const char* prompt,
    int max_tokens,
    float temperature,
    float top_p,
    TokenCallback callback,
    void* user_data
) {
    if (!ctx) {
        set_error("Context is null");
        return -1;
    }
    
    if (!prompt) {
        set_error("Prompt is null");
        return -2;
    }
    
    auto* internal = static_cast<LlamaContextInternal*>(ctx);
    
    // Ensure only one generation at a time
    std::lock_guard<std::mutex> lock(internal->generate_mutex);
    
    // Reset cancellation flag
    internal->cancel_requested.store(false);
    clear_error();
    
    // Get the model's vocabulary
    const llama_vocab* vocab = llama_model_get_vocab(internal->model);
    
    // Tokenize the prompt
    const int n_prompt_max = internal->n_ctx;
    std::vector<llama_token> tokens(n_prompt_max);
    
    int n_tokens = llama_tokenize(
        vocab,
        prompt,
        strlen(prompt),
        tokens.data(),
        n_prompt_max,
        true,   // add_special (BOS)
        true    // parse_special
    );
    
    if (n_tokens < 0) {
        set_error("Failed to tokenize prompt");
        return -3;
    }
    
    tokens.resize(n_tokens);
    
    // Reset state (new context already has empty cache)
    
    // Create a sampler chain
    llama_sampler* sampler = llama_sampler_chain_init(llama_sampler_chain_default_params());
    
    // Add temperature sampler if temperature > 0
    if (temperature > 0.0f) {
        llama_sampler_chain_add(sampler, llama_sampler_init_top_p(top_p, 1));
        llama_sampler_chain_add(sampler, llama_sampler_init_temp(temperature));
        llama_sampler_chain_add(sampler, llama_sampler_init_dist(0));
    } else {
        // Greedy sampling
        llama_sampler_chain_add(sampler, llama_sampler_init_greedy());
    }
    
    internal->sampler = sampler;
    
    // Create batch for prompt processing
    llama_batch batch = llama_batch_get_one(tokens.data(), n_tokens);
    
    // Process the prompt
    if (llama_decode(internal->ctx, batch) != 0) {
        set_error("Failed to decode prompt");
        llama_sampler_free(sampler);
        internal->sampler = nullptr;
        return -4;
    }
    
    // Generate tokens
    int n_generated = 0;
    llama_token eos_token = llama_vocab_eos(vocab);
    llama_token eot_token = llama_vocab_eot(vocab);
    
    while (n_generated < max_tokens) {
        // Check for cancellation
        if (internal->cancel_requested.load()) {
            break;
        }
        
        // Sample next token
        llama_token new_token = llama_sampler_sample(sampler, internal->ctx, -1);
        
        // Check for end of generation
        if (llama_vocab_is_eog(vocab, new_token)) {
            break;
        }
        
        // Convert token to text
        char token_text[256];
        int token_len = llama_token_to_piece(vocab, new_token, token_text, sizeof(token_text) - 1, 0, true);
        
        if (token_len > 0) {
            token_text[token_len] = '\0';
            
            // Call the callback with the generated token
            if (callback) {
                int result = callback(token_text, user_data);
                if (result != 0) {
                    // Callback requested stop
                    break;
                }
            }
        }
        
        // Prepare batch for next token
        batch = llama_batch_get_one(&new_token, 1);
        
        // Decode the new token
        if (llama_decode(internal->ctx, batch) != 0) {
            set_error("Failed to decode generated token");
            break;
        }
        
        n_generated++;
    }
    
    // Cleanup sampler
    llama_sampler_free(sampler);
    internal->sampler = nullptr;
    
    return n_generated;
}

LLAMA_API void llama_wrapper_cancel_generate(LlamaContext ctx) {
    if (!ctx) return;
    auto* internal = static_cast<LlamaContextInternal*>(ctx);
    internal->cancel_requested.store(true);
}

LLAMA_API bool llama_wrapper_is_model_loaded(LlamaContext ctx) {
    if (!ctx) return false;
    auto* internal = static_cast<LlamaContextInternal*>(ctx);
    return internal->model != nullptr && internal->ctx != nullptr;
}

LLAMA_API const char* llama_wrapper_get_error(void) {
    std::lock_guard<std::mutex> lock(g_error_mutex);
    return g_last_error.c_str();
}

LLAMA_API const char* llama_wrapper_get_model_info(LlamaContext ctx) {
    if (!ctx) {
        g_model_info = "{}";
        return g_model_info.c_str();
    }
    
    auto* internal = static_cast<LlamaContextInternal*>(ctx);
    
    if (!internal->model) {
        g_model_info = "{}";
        return g_model_info.c_str();
    }
    
    const llama_vocab* vocab = llama_model_get_vocab(internal->model);
    if (!vocab) {
        g_model_info = "{}";
        return g_model_info.c_str();
    }
    
    // Build simple JSON info
    char buf[1024];
    snprintf(buf, sizeof(buf),
        "{\"n_ctx\":%d,\"n_vocab\":%d,\"model_path\":\"%s\"}",
        internal->n_ctx,
        llama_vocab_n_tokens(vocab),
        internal->model_path.c_str()
    );
    
    g_model_info = buf;
    return g_model_info.c_str();
}
