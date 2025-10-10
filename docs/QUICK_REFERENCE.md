# Quick Reference - Chat Template Issues Fixed

## 🚨 Your Problem
**Gemma 3 1B GGUF model giving random/incoherent responses**

## ✅ The Fix
**Missing `<bos>` token + wrong template format for Gemma 3**

---

## What Was Changed

### 1. Chat Templates (CRITICAL FIX)
```kotlin
// OLD (Broken):
class GemmaTemplate {
    // Missing <bos> token
    builder.append("<start_of_turn>user\n")
    // Wrong termination for Gemma 3
}

// NEW (Fixed):
class Gemma2Template {
    builder.append("<bos>")  // ← Added this!
    builder.append("<start_of_turn>user\n")
    // Correct dual termination for Gemma 2
}

class Gemma3Template {
    builder.append("<bos>")  // ← Added this!
    builder.append("<start_of_turn>user\n")
    // Correct single termination for Gemma 3
}
```

### 2. Auto-Unload (YOUR REQUEST)
```dart
// Changed default from false to true:
static const bool defaultAutoUnloadModel = true; // ✅ ON by default
static const int defaultAutoUnloadTimeout = 60;  // ✅ 60 seconds
```

### 3. Thinking Mode (YOUR REQUEST)
- ✅ Backend support added (settings persistence)
- ⚠️ UI integration needed (follow guide)

---

## Test Now! 🧪

### Test #1: Gemma 3 Coherence
```
Load: gemma-3-1b-it.gguf
Ask: "What is 2+2?"
Expected: "2 + 2 equals 4." (or similar coherent response)
NOT: Random garbage about unrelated topics
```

### Test #2: Auto-Unload
```
1. Load model
2. Wait 60 seconds without interaction
3. Model should unload automatically
4. Check logs for "Model unloaded automatically"
```

### Test #3: Gemma 2 Still Works
```
Load: gemma-2-2b-it.gguf
Ask: "Hello!"
Expected: Coherent greeting response
```

---

## If Still Having Issues

### Issue: Gemma 3 still random
**Solution**: Try Gemma 2 instead - better GGUF support
```
Use: gemma-2-2b-it.gguf
Reason: Gemma 3 is multimodal, may have GGUF conversion issues
```

### Issue: Auto-unload not working
**Check**:
1. Settings → Auto-unload enabled? ✅
2. Timer set to 60 seconds? ✅
3. Check logs for timer activity

### Issue: Model detection wrong
**Check filename**:
- ✅ `gemma-3-1b-it.gguf` → Detected as Gemma 3
- ✅ `gemma-2-2b-it.gguf` → Detected as Gemma 2
- ✅ `gemma-it.gguf` → Defaults to Gemma 2

---

## Thinking Mode (Optional)

### What is it?
Shows reasoning process of models like QwQ-32B:
```
<think>
Let me break this down...
First, I need to...
Then I should...
</think>

The answer is...
```

### How to enable?
1. Follow: `THINKING_MODE_IMPLEMENTATION_GUIDE.md`
2. Add UI toggle in settings
3. Test with QwQ or DeepSeek-R1 model

### Default: OFF ✅
- Saves tokens
- Faster responses
- Enable only for reasoning tasks

---

## Model Recommendations

### ✅ Best for GGUF/llama.cpp:
- **Gemma 2 2B** - Proven compatibility
- **Llama 3.3 8B** - Excellent general purpose
- **Qwen 2.5 7B** - Strong multilingual

### ⚠️ May have issues:
- **Gemma 3** - Multimodal, text-only GGUF conversion
- Very new models - Wait for stable GGUF

### 🧠 For Reasoning (with thinking mode):
- **QwQ-32B** - Math and reasoning
- **DeepSeek-R1** - General reasoning
- **DeepSeek-V3** - Latest version

---

## Quick Debug Commands

### Check template detection:
```kotlin
// Look for in logs:
"Detected Gemma 3 model - using gemma3 template"
"Detected Gemma 2 model - using gemma2 template"
```

### Verify BOS token:
```kotlin
// Look for in formatted prompt:
"<bos><start_of_turn>user"  // ✅ Correct
"<start_of_turn>user"        // ❌ Missing BOS
```

### Check auto-unload:
```
[ChatService] Starting auto-unload timer: 60 seconds
[ChatService] Auto-unload timer triggered
[ChatService] Model unloaded automatically
```

---

## Files You Can Reference

1. **Full Analysis**: `CHAT_TEMPLATE_ANALYSIS_AND_FIXES.md`
2. **Thinking Mode Guide**: `THINKING_MODE_IMPLEMENTATION_GUIDE.md`
3. **Summary**: `SUMMARY_OF_CHANGES.md`
4. **This File**: `QUICK_REFERENCE.md`

---

## TL;DR

**Problem**: Gemma 3 → Random responses
**Cause**: Missing `<bos>` token + wrong template
**Fix**: Separate Gemma2/Gemma3 templates with correct format
**Bonus**: Auto-unload ON by default (60s)
**Next**: Test immediately, follow thinking mode guide if needed

---

**Need Help?**
- Check logs for template detection
- Try Gemma 2 if Gemma 3 still has issues
- Refer to detailed guides in `docs/` folder

Last Updated: October 10, 2025
