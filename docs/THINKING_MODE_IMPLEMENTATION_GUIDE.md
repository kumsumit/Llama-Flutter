# Thinking Mode Implementation Guide

## Overview

This guide explains how to complete the implementation of thinking mode support for reasoning models (QwQ, DeepSeek-R1, etc.) in your Flutter llama.cpp project.

## What's Already Done ✅

1. ✅ **Settings Service Updated**
   - Added `thinkingMode` setting with default `false`
   - Added getter/setter methods in `SettingsService`

2. ✅ **Chat Templates Updated**
   - `QwQTemplate` already strips `<think>` blocks from history
   - `DeepSeekR1Template` handles thinking tags

3. ✅ **Auto-Unload Enabled by Default**
   - Changed `defaultAutoUnloadModel` from `false` to `true`
   - Timer already implemented with 60-second default

4. ✅ **Gemma Templates Fixed**
   - Separated into `Gemma2Template` and `Gemma3Template`
   - Added `<bos>` token
   - Fixed model detection

## What You Need to Do 🔧

### Step 1: Update Pigeon API Definition

**File**: `pigeons/llama_api.dart`

Add `enableThinking` parameter to `ChatRequest`:

```dart
/// Request for chat generation with template formatting
class ChatRequest {
  final List<ChatMessage> messages;
  final String? template; // null = auto-detect from model
  final int maxTokens;
  
  // Sampling parameters
  final double temperature;
  final double topP;
  final int topK;
  final double minP;
  final double typicalP;
  
  // Penalties
  final double repeatPenalty;
  final double frequencyPenalty;
  final double presencePenalty;
  final int repeatLastN;
  
  // Mirostat sampling
  final int mirostat;
  final double mirostatTau;
  final double mirostatEta;
  
  // Other
  final int? seed;
  final bool penalizeNewline;
  final bool enableThinking; // NEW: Enable thinking mode for reasoning models
  
  ChatRequest({
    required this.messages,
    this.template,
    this.maxTokens = 512,
    this.temperature = 0.7,
    this.topP = 0.9,
    this.topK = 40,
    this.minP = 0.05,
    this.typicalP = 1.0,
    this.repeatPenalty = 1.1,
    this.frequencyPenalty = 0.0,
    this.presencePenalty = 0.0,
    this.repeatLastN = 64,
    this.mirostat = 0,
    this.mirostatTau = 5.0,
    this.mirostatEta = 0.1,
    this.seed,
    this.penalizeNewline = true,
    this.enableThinking = false, // NEW: Default disabled
  });
}
```

### Step 2: Regenerate Pigeon Code

Run in terminal:

```bash
flutter pub run pigeon --input pigeons/llama_api.dart
```

This will regenerate:
- `lib/src/llama_api.dart` (Dart side)
- `android/src/main/kotlin/com/write4me/llama_flutter_android/LlamaHostApi.kt` (Kotlin side)

### Step 3: Update LlamaController

**File**: `lib/src/llama_controller.dart`

Update the `generateChat` method:

```dart
/// Generate chat response with automatic template formatting
Stream<String> generateChat({
  required List<ChatMessage> messages,
  String? template,
  int maxTokens = 512,
  double temperature = 0.7,
  double topP = 0.9,
  int topK = 40,
  double minP = 0.05,
  double typicalP = 1.0,
  double repeatPenalty = 1.1,
  double frequencyPenalty = 0.0,
  double presencePenalty = 0.0,
  int repeatLastN = 64,
  int mirostat = 0,
  double mirostatTau = 5.0,
  double mirostatEta = 0.1,
  int? seed,
  bool penalizeNewline = true,
  bool enableThinking = false, // NEW parameter
}) {
  if (_isGenerating) {
    throw StateError('Already generating');
  }

  _isGenerating = true;
  _tokenController = StreamController<String>.broadcast();
  
  // Start chat generation
  _api.generateChat(ChatRequest(
    messages: messages,
    template: template,
    maxTokens: maxTokens,
    temperature: temperature,
    topP: topP,
    topK: topK,
    minP: minP,
    typicalP: typicalP,
    repeatPenalty: repeatPenalty,
    frequencyPenalty: frequencyPenalty,
    presencePenalty: presencePenalty,
    repeatLastN: repeatLastN,
    mirostat: mirostat,
    mirostatTau: mirostatTau,
    mirostatEta: mirostatEta,
    seed: seed,
    penalizeNewline: penalizeNewline,
    enableThinking: enableThinking, // NEW: Pass to native
  ));

  return _tokenController!.stream;
}
```

### Step 4: Update ChatService

**File**: `example/lib/services/chat_service.dart`

Add thinking mode state and methods:

```dart
class ChatService {
  // ... existing fields ...
  
  bool _thinkingModeEnabled = false;
  
  // ... existing getters ...
  
  bool get thinkingModeEnabled => _thinkingModeEnabled;
  
  /// Initialize the chat service
  Future<bool> initialize({String? systemMessage}) async {
    debugPrint('[ChatService] Initializing ChatService...');
    
    // Initialize the settings service
    await _settingsService.init();
    
    // Load settings
    _contextSize = _settingsService.contextSize;
    _chatTemplate = _settingsService.chatTemplate;
    _autoUnloadModel = _settingsService.autoUnloadModel;
    _autoUnloadTimeout = _settingsService.autoUnloadTimeout;
    _thinkingModeEnabled = _settingsService.thinkingMode; // NEW: Load thinking mode
    
    // ... rest of initialization ...
  }
  
  /// Toggle thinking mode
  Future<void> setThinkingMode(bool enabled) async {
    debugPrint('[ChatService] Setting thinking mode: $enabled');
    _thinkingModeEnabled = enabled;
    await _settingsService.setThinkingMode(enabled);
  }
  
  // In sendMessage method, pass thinking mode to generateChat:
  Future<void> sendMessage(String userMessage, {bool regenerate = false}) async {
    // ... existing code ...
    
    _generationSubscription = _llama!.generateChat(
      messages: messagesToSend,
      template: _chatTemplate == 'auto' ? null : _chatTemplate,
      maxTokens: generationConfig.maxTokens,
      temperature: generationConfig.temperature,
      topP: generationConfig.topP,
      topK: generationConfig.topK,
      minP: generationConfig.minP,
      typicalP: generationConfig.typicalP,
      repeatPenalty: generationConfig.repeatPenalty,
      frequencyPenalty: generationConfig.frequencyPenalty,
      presencePenalty: generationConfig.presencePenalty,
      repeatLastN: generationConfig.repeatLastN,
      mirostat: generationConfig.mirostat,
      mirostatTau: generationConfig.mirostatTau,
      mirostatEta: generationConfig.mirostatEta,
      seed: generationConfig.seed,
      penalizeNewline: generationConfig.penalizeNewline,
      enableThinking: _thinkingModeEnabled, // NEW: Pass thinking mode
    ).listen(
      // ... rest of the code ...
    );
  }
}
```

### Step 5: Add UI Toggle for Thinking Mode

**File**: `example/lib/main.dart`

Find the settings dialog (around line 400-700) and add a toggle:

```dart
// In _showAdvancedSettingsDialog or wherever settings are displayed:

SwitchListTile(
  title: const Text(
    'Thinking Mode',
    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  ),
  subtitle: const Text(
    'Enable for reasoning models (QwQ, DeepSeek-R1). Shows model\'s reasoning process.',
    style: TextStyle(fontSize: 12),
  ),
  value: _chatService.thinkingModeEnabled,
  onChanged: (value) async {
    await _chatService.setThinkingMode(value);
    setState(() {});
    
    // Show info message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value 
            ? 'Thinking mode enabled - model will show reasoning' 
            : 'Thinking mode disabled - reasoning will be hidden',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  },
),

const Divider(),

// Add info text:
Padding(
  padding: const EdgeInsets.all(16.0),
  child: Text(
    'Note: Thinking mode only works with reasoning models like QwQ-32B and DeepSeek-R1. '
    'Regular models will ignore this setting.',
    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
  ),
),
```

### Step 6: (Optional) Show Thinking Blocks Differently in UI

You can optionally highlight thinking blocks in the UI:

```dart
// In message display widget:

Widget _buildMessageContent(String content, bool isUser) {
  // Detect thinking blocks
  final thinkRegex = RegExp(r'<think>(.*?)</think>', dotAll: true);
  final hasThinking = thinkRegex.hasMatch(content);
  
  if (hasThinking && _chatService.thinkingModeEnabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Extract thinking blocks
        ...thinkRegex.allMatches(content).map((match) {
          final thinkingContent = match.group(1) ?? '';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology, size: 16, color: Colors.amber[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Thinking...',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  thinkingContent.trim(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        }),
        
        // Show final answer (content without thinking blocks)
        Text(
          content.replaceAll(thinkRegex, '').trim(),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
  
  // Regular message display
  return Text(content, style: const TextStyle(fontSize: 14));
}
```

## Testing Checklist ✅

After implementation:

- [ ] Verify thinking mode toggle appears in settings
- [ ] Default value is `false` (disabled)
- [ ] Setting persists across app restarts
- [ ] Test with QwQ model:
  - [ ] With thinking mode OFF: reasoning blocks are hidden
  - [ ] With thinking mode ON: reasoning blocks are shown
- [ ] Test with regular models (Llama, Gemma):
  - [ ] Setting has no effect (as expected)
- [ ] Verify auto-unload is enabled by default
- [ ] Verify auto-unload timer works after 60 seconds

## Recommended Models for Testing

### Reasoning Models (Support Thinking Mode):
- **QwQ-32B-Preview** - Best for math and reasoning
- **DeepSeek-R1** - Excellent reasoning capabilities
- **DeepSeek-V3** - Latest version with thinking

### Standard Models (Don't use thinking mode):
- **Gemma 2 2B** - Good general purpose
- **Gemma 3 1B** - Latest multimodal (text only in GGUF)
- **Llama 3.3** - Excellent general purpose
- **Qwen 2.5** - Strong multilingual

## Additional Notes

### Why Thinking Mode Matters

Reasoning models like QwQ generate their thoughts in `<think>` tags:
```
<think>
Let me break this down:
1. First, I need to understand...
2. Then I should consider...
3. Finally, the answer is...
</think>

The answer is 42.
```

**Without thinking mode**: User only sees "The answer is 42."
**With thinking mode**: User sees the reasoning process too.

### Performance Considerations

- **Tokens**: Thinking blocks add significant tokens to context
- **Speed**: Generation is slower with thinking enabled
- **Context**: May fill context faster with reasoning
- **Accuracy**: Usually more accurate answers but slower

### Chat Template Compatibility

Thinking mode is automatically handled by:
- ✅ `QwQTemplate` - Strips `<think>` blocks from history
- ✅ `DeepSeekR1Template` - Handles `<think>` tags
- ⚠️ Other templates - Ignore thinking mode (pass through)

---

## Summary

Your implementation now has:

1. ✅ **Fixed Gemma templates** - Should resolve random responses
2. ✅ **Auto-unload enabled** - Default ON with 60s timer
3. ⚠️ **Thinking mode** - Backend ready, needs UI integration (follow steps above)

The main issue with Gemma 3 1B giving random responses should be fixed with the corrected template that includes `<bos>` token and proper turn handling.

**Next Steps**:
1. Test with Gemma 3 1B model - responses should be coherent now
2. Complete thinking mode UI integration (optional)
3. Consider using Gemma 2 models for better llama.cpp compatibility

---

Last Updated: October 10, 2025
