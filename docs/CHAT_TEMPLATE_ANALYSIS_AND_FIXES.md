# Chat Template Analysis and Fixes

## Executive Summary

After analyzing your project's custom chat template implementation and researching Gemma 3 specifications, I've identified several critical issues:

### 🔴 Critical Issues Found

1. **Gemma 3 vs Gemma 2 Template Incompatibility**
   - Your current `GemmaTemplate` is designed for Gemma 2
   - Gemma 3 is a **multimodal model** with different token structure
   - **This is likely causing the random responses you're seeing**

2. **Llama.cpp Native Chat Template Support**
   - Llama.cpp has **native chat template** support in GGUF metadata
   - Your custom Kotlin implementation **bypasses** llama.cpp's built-in templating
   - This can cause conflicts when the model has its own template in metadata

3. **Missing Features**
   - No thinking mode support for reasoning models (QwQ, DeepSeek-R1)
   - No auto-unload functionality with timer (exists in UI but not fully integrated)

---

## 🔬 Technical Analysis

### Issue 1: Gemma 3 Chat Template Problem

#### Current Implementation (Gemma 2 format):
```kotlin
class GemmaTemplate : ChatTemplate {
    override val name = "gemma"
    
    override fun format(messages: List<TemplateChatMessage>): String {
        val builder = StringBuilder()
        
        for ((index, message) in messages.withIndex()) {
            when (message.role) {
                "system" -> continue
                "user" -> {
                    val systemMsg = if (index == 0 || (index == 1 && messages[0].role == "system")) {
                        messages.firstOrNull { it.role == "system" }?.content?.let { "$it\n\n" } ?: ""
                    } else ""
                    
                    builder.append("<start_of_turn>user\n")
                    builder.append("$systemMsg${message.content}<end_of_turn>\n")
                }
                "assistant" -> {
                    builder.append("<start_of_turn>model\n")
                    builder.append("${message.content}<end_of_turn>")
                    
                    if (index < messages.size - 1) {
                        builder.append("<eos>")  // Gemma 2 dual termination
                    }
                    builder.append("\n")
                }
            }
        }
        
        builder.append("<start_of_turn>model\n")
        return builder.toString()
    }
}
```

#### Problems:
1. **No `<bos>` token at start** - Gemma models need this
2. **Dual termination** (`<eos>` after `<end_of_turn>`) - Only for Gemma 2, not Gemma 3
3. **Model detection doesn't differentiate** Gemma 2 vs Gemma 3

#### Correct Gemma 2 Format:
```
<bos><start_of_turn>user
{content}<end_of_turn>
<start_of_turn>model
{content}<end_of_turn>
```

#### Gemma 3 Format (Multimodal):
Gemma 3 is **fundamentally different** - it's a vision-language model with:
- Text AND image input support
- Different tokenizer structure
- Requires transformers 4.50.0+
- Content as structured dict: `{"type": "text", "text": "..."}`

**Your current template won't work properly with Gemma 3 1B models.**

---

### Issue 2: Llama.cpp Native Template Conflict

#### How Llama.cpp Handles Chat Templates:

Modern GGUF files include chat template metadata:
```
metadata["tokenizer.chat_template"] = "<|im_start|>user\n{content}<|im_end|>\n..."
```

Llama.cpp will:
1. Read the template from GGUF metadata
2. Apply it automatically if you use the chat API
3. **Your manual formatting may conflict with this**

#### Current Flow:
```
User Message → Kotlin ChatTemplates.kt → Manual format → llama.cpp
                                              ↓
                                    May conflict with GGUF template
```

#### Recommended Flow:
```
User Message → Check if GGUF has template → Use native if available
                                           → Fall back to manual if not
```

---

### Issue 3: Missing Thinking Mode Support

Your QwQ template strips `<think>` blocks but doesn't:
1. Allow users to **enable/disable** thinking mode
2. Provide UI controls for thinking models
3. Handle thinking output specially in the UI

#### Current QwQ Implementation:
```kotlin
class QwQTemplate : ChatTemplate {
    // Strips thinking blocks from history
    private fun stripReasoningBlocks(content: String): String {
        return content.replace(Regex("<think>.*?</think>", 
            setOf(RegexOption.DOT_MATCHES_ALL, RegexOption.MULTILINE)), "")
            .trim()
    }
}
```

**This is correct** but needs:
- UI toggle for thinking mode
- Option to **show** reasoning in UI
- Proper token counting for thinking tokens

---

## 🛠️ Recommended Fixes

### Fix 1: Separate Gemma 2 and Gemma 3 Templates

```kotlin
/**
 * Gemma 2 format with BOS token and dual termination
 */
class Gemma2Template : ChatTemplate {
    override val name = "gemma2"
    
    override fun format(messages: List<TemplateChatMessage>): String {
        val builder = StringBuilder()
        builder.append("<bos>")  // Add BOS token
        
        var systemContent: String? = null
        
        for ((index, message) in messages.withIndex()) {
            when (message.role) {
                "system" -> {
                    systemContent = message.content
                    continue
                }
                "user" -> {
                    builder.append("<start_of_turn>user\n")
                    
                    // Prepend system to first user message
                    if (systemContent != null && index <= 1) {
                        builder.append("$systemContent\n\n")
                        systemContent = null
                    }
                    
                    builder.append("${message.content}<end_of_turn>\n")
                }
                "assistant" -> {
                    builder.append("<start_of_turn>model\n")
                    builder.append("${message.content}<end_of_turn>")
                    
                    // Gemma 2 dual termination (except last message)
                    if (index < messages.size - 1) {
                        builder.append("<eos>")
                    }
                    builder.append("\n")
                }
            }
        }
        
        builder.append("<start_of_turn>model\n")
        return builder.toString()
    }
}

/**
 * Gemma 3 format (text-only, for GGUF conversions)
 * Note: Full multimodal Gemma 3 requires Transformers, not llama.cpp
 */
class Gemma3Template : ChatTemplate {
    override val name = "gemma3"
    
    override fun format(messages: List<TemplateChatMessage>): String {
        val builder = StringBuilder()
        builder.append("<bos>")
        
        var systemContent: String? = null
        
        for (message in messages) {
            when (message.role) {
                "system" -> {
                    systemContent = message.content
                    continue
                }
                "user" -> {
                    builder.append("<start_of_turn>user\n")
                    
                    if (systemContent != null) {
                        builder.append("$systemContent\n\n")
                        systemContent = null
                    }
                    
                    builder.append("${message.content}<end_of_turn>\n")
                }
                "assistant" -> {
                    builder.append("<start_of_turn>model\n")
                    builder.append("${message.content}<end_of_turn>\n")
                    // Gemma 3 uses single termination
                }
            }
        }
        
        builder.append("<start_of_turn>model\n")
        return builder.toString()
    }
}
```

### Fix 2: Improved Model Detection

```kotlin
fun detectTemplate(modelPath: String): ChatTemplate {
    val lowerPath = modelPath.lowercase()
    
    return when {
        // ... other checks ...
        
        // Gemma detection - check version
        lowerPath.contains("gemma-3") || lowerPath.contains("gemma3") -> {
            android.util.Log.w("ChatTemplateManager", 
                "Gemma 3 detected - Note: Full multimodal support requires Transformers")
            templates["gemma3"]!!
        }
        lowerPath.contains("gemma-2") || lowerPath.contains("gemma2") -> {
            templates["gemma2"]!!
        }
        lowerPath.contains("gemma") -> {
            // Assume Gemma 2 for legacy models
            templates["gemma2"]!!
        }
        
        // ... rest ...
    }
}
```

### Fix 3: Add Thinking Mode Support

#### 1. Add to Pigeon API (`pigeons/llama_api.dart`):
```dart
class ChatRequest {
  // ... existing fields ...
  
  final bool enableThinking; // NEW: Enable thinking mode for reasoning models
  
  ChatRequest({
    // ... existing params ...
    this.enableThinking = false, // Default: disabled
  });
}
```

#### 2. Update Chat Service:
```dart
class ChatService {
  bool _thinkingModeEnabled = false;
  
  bool get thinkingModeEnabled => _thinkingModeEnabled;
  
  Future<void> setThinkingMode(bool enabled) async {
    _thinkingModeEnabled = enabled;
    await _settingsService.setThinkingMode(enabled);
  }
  
  // When sending messages:
  _llama.generateChat(
    messages: messages,
    template: _chatTemplate,
    enableThinking: _thinkingModeEnabled, // Pass to native
    // ... other params ...
  );
}
```

#### 3. UI Toggle:
```dart
// In settings dialog:
SwitchListTile(
  title: Text('Thinking Mode'),
  subtitle: Text('Enable for reasoning models (QwQ, DeepSeek-R1)'),
  value: _chatService.thinkingModeEnabled,
  onChanged: (value) {
    setState(() {
      _chatService.setThinkingMode(value);
    });
  },
),
```

### Fix 4: Auto-Unload with Timer (Already Exists!)

Your code **already has** auto-unload functionality! It just needs to be:
1. **Enabled by default** as you requested
2. Timer set to 60 seconds

#### Update in `SettingsService`:
```dart
class SettingsService {
  // Change defaults:
  static const bool _defaultAutoUnloadModel = true; // Changed from false
  static const int _defaultAutoUnloadTimeout = 60; // Confirm 60 seconds
  
  // ... rest of code ...
}
```

---

## 🎯 Action Plan

### Priority 1: Fix Gemma Template (HIGH - Causing your issue)
1. Add separate Gemma2Template and Gemma3Template classes
2. Update model detection to differentiate versions
3. Add `<bos>` token to templates
4. **Test with your Gemma 3 1B model**

### Priority 2: Add Thinking Mode (MEDIUM - User requested)
1. Add `enableThinking` parameter to Pigeon API
2. Regenerate Pigeon code
3. Update UI with thinking mode toggle
4. Default to `false`

### Priority 3: Enable Auto-Unload by Default (LOW - Easy fix)
1. Change default in SettingsService
2. Confirm 60-second timer

### Priority 4: Consider Llama.cpp Native Templates (FUTURE)
1. Check if GGUF has template metadata
2. Use native template if available
3. Fall back to custom templates

---

## 📝 Testing Checklist

After fixes:
- [ ] Test Gemma 2 2B model (should use gemma2 template)
- [ ] Test Gemma 3 1B model (should use gemma3 template with `<bos>`)
- [ ] Verify responses are coherent, not random
- [ ] Test thinking mode with QwQ model
- [ ] Confirm auto-unload triggers after 60 seconds
- [ ] Test template auto-detection for various models

---

## 🔗 References

1. **Gemma 2 Documentation**: https://huggingface.co/google/gemma-2-2b-it
2. **Gemma 3 Documentation**: https://huggingface.co/google/gemma-3-1b-it
3. **Chat Template Guide**: https://huggingface.co/docs/transformers/main/en/chat_templating
4. **QwQ Model**: https://huggingface.co/Qwen/QwQ-32B-Preview
5. **Llama.cpp Chat Templates**: Check GGUF metadata with `llama-quantize --help`

---

## ⚠️ Important Note on Gemma 3

**Gemma 3 is a multimodal model** designed for:
- Text + Image input
- Requires transformers library
- May not work optimally with llama.cpp GGUF conversions

If you're using a **Gemma 3 1B GGUF**, it's likely a text-only conversion that:
- Lost multimodal capabilities
- May need special template handling
- **Could be causing the random responses**

**Recommendation**: For Gemma 3, consider:
1. Using the official transformers implementation
2. Or use Gemma 2 models which are better supported in GGUF/llama.cpp
3. Or verify your GGUF conversion is correct

---

Last Updated: October 10, 2025
