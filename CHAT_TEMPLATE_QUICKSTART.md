# Chat Template Quick Start

## Overview

The plugin now includes automatic chat template formatting for popular models like Qwen, Llama-2/3, Phi, Gemma, and more. No more manual prompt formatting!

## Basic Usage

```dart
import 'package:llama_flutter_android/llama_flutter_android.dart';

final controller = LlamaController();

// 1. Load model (template auto-detected from filename)
await controller.loadModel(
  modelPath: '/path/to/Qwen2-0.5B-Instruct-Q4_K_M.gguf',
  threads: 4,
  contextSize: 2048,
);

// 2. Create conversation
final messages = [
  ChatMessage(role: 'system', content: 'You are a helpful assistant.'),
  ChatMessage(role: 'user', content: 'Hello!'),
];

// 3. Generate response (automatic template formatting)
final stream = controller.generateChat(
  messages: messages,
  maxTokens: 256,
  temperature: 0.7,
);

// 4. Listen to tokens
await for (final token in stream) {
  print(token);
}
```

## Complete Chat App Example

```dart
class ChatService {
  final _controller = LlamaController();
  final _messages = <ChatMessage>[];
  
  Future<void> initialize(String modelPath) async {
    await _controller.loadModel(
      modelPath: modelPath,
      threads: 4,
      contextSize: 2048,
    );
    
    // Add system message
    _messages.add(ChatMessage(
      role: 'system',
      content: 'You are a helpful AI assistant.',
    ));
  }
  
  Stream<String> sendMessage(String userMessage) async* {
    // Add user message
    _messages.add(ChatMessage(
      role: 'user',
      content: userMessage,
    ));
    
    final responseBuffer = StringBuffer();
    
    // Generate with automatic template
    final stream = _controller.generateChat(
      messages: _messages,
      maxTokens: 256,
      temperature: 0.7,
    );
    
    await for (final token in stream) {
      responseBuffer.write(token);
      yield token;
    }
    
    // Add assistant response to history
    _messages.add(ChatMessage(
      role: 'assistant',
      content: responseBuffer.toString(),
    ));
  }
  
  void clearHistory() {
    // Keep only system message
    if (_messages.isNotEmpty) {
      final systemMsg = _messages.first;
      _messages.clear();
      _messages.add(systemMsg);
    }
  }
  
  Future<void> dispose() => _controller.dispose();
}
```

## Supported Models & Templates

| Model | Auto-Detected | Template Format |
|-------|---------------|-----------------|
| Qwen / Qwen2 | ✅ | ChatML |
| Llama-3 | ✅ | ChatML |
| Llama-2 | ✅ | Llama-2 format |
| Phi-2 / Phi-3 | ✅ | Phi format |
| Gemma | ✅ | Gemma format |
| Alpaca | ✅ | Alpaca format |
| Vicuna | ✅ | Vicuna format |

## Manual Template Selection

Override auto-detection if needed:

```dart
final stream = controller.generateChat(
  messages: messages,
  template: 'chatml', // Force specific template
  maxTokens: 256,
);
```

## Available Templates

```dart
final templates = await controller.getSupportedTemplates();
print(templates); 
// ['chatml', 'qwen', 'llama3', 'llama2', 'phi', 'gemma', 'alpaca', 'vicuna']
```

## Message Roles

```dart
ChatMessage(role: 'system', content: '...')   // System prompt
ChatMessage(role: 'user', content: '...')     // User input
ChatMessage(role: 'assistant', content: '...') // AI response
```

## Migration from Raw Prompts

**Before:**
```dart
final prompt = '''
<|im_start|>system
You are helpful.<|im_end|>
<|im_start|>user
$userInput<|im_end|>
<|im_start|>assistant
''';

controller.generate(prompt: prompt, ...);
```

**After:**
```dart
final messages = [
  ChatMessage(role: 'system', content: 'You are helpful.'),
  ChatMessage(role: 'user', content: userInput),
];

controller.generateChat(messages: messages, ...);
```

## Example App

See `example/lib/chat_template_example.dart` for a complete working example with:
- Multi-turn conversations
- Streaming responses
- Message history
- Clear chat functionality

## Benefits

✅ **Automatic formatting** - No manual template syntax  
✅ **Multi-model support** - Works with 7+ model families  
✅ **Type-safe** - Compile-time message validation  
✅ **Context management** - Easy conversation history  
✅ **Stream responses** - Real-time token generation  

## Troubleshooting

**Q: Model generates gibberish**  
A: Wrong template. Try: `template: 'chatml'` or check model docs

**Q: Model doesn't respond**  
A: Add system message:
```dart
ChatMessage(role: 'system', content: 'You are a helpful assistant.')
```

**Q: Want custom template?**  
A: Use raw `generate()` with your own format:
```dart
final customPrompt = formatMyWay(messages);
controller.generate(prompt: customPrompt, ...);
```

## More Info

- [Complete Documentation](../CHAT_TEMPLATES.md)
- [Template Formats](../CHAT_TEMPLATES.md#supported-templates)
- [API Reference](../README.md)
