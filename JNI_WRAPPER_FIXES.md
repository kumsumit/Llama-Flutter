# JNI Wrapper Fixes - October 8, 2025

## Summary
Completely rewrote JNI wrapper to use **raw llama.cpp API only**, eliminating all common library dependencies.

## Key Changes

### 1. Removed Common Library Dependencies
- Removed `#include "llama.cpp/common/common.h"`
- Removed `#include "llama.cpp/common/sampling.h"`
- Updated CMakeLists.txt to not link common sources

### 2. Direct Tokenization API
**Before (common library):**
```cpp
std::vector<llama_token> tokens = common_tokenize(g_ctx, prompt_str, true, true);
```

**After (raw API):**
```cpp
const int n_prompt_tokens = llama_tokenize(g_vocab, prompt_str, prompt_len, nullptr, 0, true, true);
if (n_prompt_tokens < 0) {
    // Error handling
}
std::vector<llama_token> tokens(n_prompt_tokens);
llama_tokenize(g_vocab, prompt_str, prompt_len, tokens.data(), tokens.size(), true, true);
```

### 3. Manual Batch Operations
**Before (common library):**
```cpp
common_batch_add(batch, token, pos, {0}, logits);
common_batch_clear(batch);
```

**After (manual):**
```cpp
// Adding tokens
batch.token[i] = tokens[i];
batch.pos[i] = i;
batch.n_seq_id[i] = 1;
batch.seq_id[i][0] = 0;
batch.logits[i] = (i == tokens.size() - 1);
batch.n_tokens = tokens.size();

// Clearing batch
batch.n_tokens = 0;
```

### 4. Raw Sampler Chain API
**Before (common library):**
```cpp
common_params_sampling sparams;
sparams.temp = temperature;
auto smpl = common_sampler_init(g_model, sparams);
llama_token tok = common_sampler_sample(smpl, g_ctx, -1);
common_sampler_accept(smpl, tok, true);
common_sampler_free(smpl);
```

**After (raw API):**
```cpp
g_sampler = llama_sampler_chain_init({0});
llama_sampler_chain_add(g_sampler, llama_sampler_init_temp(temperature));
llama_sampler_chain_add(g_sampler, llama_sampler_init_top_k(top_k));
llama_sampler_chain_add(g_sampler, llama_sampler_init_top_p(top_p, 1));
llama_sampler_chain_add(g_sampler, llama_sampler_init_dist(time(nullptr)));
llama_token tok = llama_sampler_sample(g_sampler, g_ctx, -1);
llama_sampler_free(g_sampler);
```

### 5. Vocab-Based Token Decoding
**Before:**
```cpp
llama_token_to_piece(g_model, token, buffer, size, 0, true);
```

**After:**
```cpp
llama_token_to_piece(g_vocab, token, buffer, size, 0, true);
```

### 6. Error Handling Improvements
- Added null check for tokenization result (returns -1 on error)
- Added null check for vocab pointer after initialization
- Added detailed error messages with return codes
- Added debug logging for tokenization and vocab pointers

## Global State Changes
```cpp
static llama_model* g_model = nullptr;
static llama_context* g_ctx = nullptr;
static const llama_vocab* g_vocab = nullptr;  // NEW: stores vocab pointer
static llama_sampler* g_sampler = nullptr;     // NEW: persistent sampler
static std::atomic<bool> g_stop_flag{false};
```

## Cleanup Updates
```cpp
// nativeFreeModel now also frees sampler
if (g_sampler) {
    llama_sampler_free(g_sampler);
    g_sampler = nullptr;
}
```

## Build Configuration
**android/CMakeLists.txt** - Simplified to:
```cmake
add_library(llama_jni SHARED
    src/main/cpp/jni_wrapper.cpp
)
```

No common library sources needed!

## API Compatibility
All functions now use **llama.cpp October 2025 API**:
- ✅ `llama_tokenize(vocab, ...)` - vocab-based tokenization
- ✅ `llama_token_to_piece(vocab, ...)` - vocab-based decoding
- ✅ `llama_sampler_chain_*` - new sampler chain API
- ✅ Manual batch operations - direct struct manipulation
- ✅ `llama_vocab_is_eog(vocab, ...)` - vocab-based EOS check

## Testing Status
- ✅ Compilation: PASSED
- ⏳ Model loading: Testing
- ⏳ Token generation: Testing
- ⏳ Memory management: Testing

## Known Issues
1. Tokenization returning -1 (under investigation)
   - Vocab pointer may be null
   - Added validation and logging

## Next Steps
1. Verify vocab pointer is valid after model load
2. Test tokenization with simple prompt
3. Verify sampler chain produces valid output
4. Performance benchmarking
