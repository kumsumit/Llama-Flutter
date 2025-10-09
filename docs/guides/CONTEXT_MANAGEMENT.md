# Context Management Guide

## Overview

The `llama_flutter_android` package now includes intelligent context management to handle token limits gracefully in both short chat sessions and long-form text generation.

## Features

### Phase 1: Core APIs ✅

#### 1. Context Monitoring
Get real-time information about context usage:

```dart
// Get current context info
final contextInfo = await controller.getContextInfo();
print('Used: ${contextInfo.tokensUsed}/${contextInfo.contextSize}');
print('Usage: ${contextInfo.usagePercentage.toStringAsFixed(1)}%');
```

#### 2. Context Clearing
Clear conversation context while keeping the model loaded:

```dart
// Clear context (faster than reloading model)
await controller.clearContext();
```

#### 3. System Prompt Tracking
Track system prompt length for smart context management:

```dart
// Optional: Set system prompt length for smarter trimming
controller.setSystemPromptLength(50); // number of tokens
```

### Phase 2: Smart Management ✅

#### 1. Context Strategy
Automatic context management with configurable thresholds:

```dart
// Initialize strategy
final strategy = ContextStrategy(
  contextSize: 2048,
  reservedForGeneration: 512,
);

// Check status
if (strategy.needsWarning) {
  print('Context at ${(strategy.usageRatio * 100).toStringAsFixed(0)}%');
}

// Get recommended action
final action = strategy.getRecommendedAction(userMessage);
switch (action) {
  case ContextAction.proceed:
    // All good
    break;
  case ContextAction.showWarning:
    // Show warning to user
    break;
  case ContextAction.shouldTrimOrSummarize:
    // Trim old messages
    break;
  case ContextAction.mustClear:
    // Must clear context
    break;
}
```

#### 2. Dynamic Token Allocation
Automatically adjust response length based on available context:

```dart
// Calculate optimal max tokens
final maxTokens = strategy.calculateDynamicMaxTokens(
  defaultMaxTokens: 512,
);
// Returns: 512 if plenty of space, 256 if moderate, 100 if tight
```

#### 3. Context-Aware Chat Service
Integrated in the example app's `ChatService`:

```dart
final chatService = ChatService();

// Configure behavior
chatService.autoManageContext = true;  // Auto-trim when needed
chatService.maxMessagesToKeep = 10;    // Keep last 10 messages

// Send message - context managed automatically
chatService.sendMessage('Hello!');

// Listen to context updates
chatService.contextInfoStream.listen((info) {
  print('Context: ${info.usagePercentage.toStringAsFixed(0)}%');
});
```

#### 4. UI Context Indicator
Visual feedback in the example app:

- **Green** (< 70%): Normal operation
- **Orange** (70-85%): Warning
- **Red** (> 85%): Critical - clear button appears

## Usage Examples

### Basic Context Monitoring

```dart
// Load model
await controller.loadModel(
  modelPath: modelPath,
  contextSize: 2048,
);

// Check context periodically
final info = await controller.getContextInfo();
if (info.usagePercentage > 80) {
  print('Context nearly full!');
  await controller.clearContext();
}
```

### Automatic Management (Recommended)

```dart
class MyChatService {
  final controller = LlamaController();
  final strategy = ContextStrategy(contextSize: 2048);
  final messages = <ChatMessage>[];
  
  Future<void> sendMessage(String text) async {
    // Update context info
    final info = await controller.getContextInfo();
    strategy.currentTokens = info.tokensUsed;
    
    // Check and act
    final action = strategy.getRecommendedAction(text);
    
    if (action == ContextAction.mustClear) {
      // Clear context
      await controller.clearContext();
      
      // Keep only recent messages
      final systemMsg = messages.first;
      final recent = messages.reversed.take(10).toList().reversed.toList();
      messages.clear();
      messages.addAll([systemMsg, ...recent]);
    }
    
    // Calculate dynamic tokens
    final maxTokens = strategy.calculateDynamicMaxTokens();
    
    // Generate
    messages.add(ChatMessage(role: 'user', content: text));
    final stream = controller.generateChat(
      messages: messages,
      maxTokens: maxTokens,
    );
    
    // Process response...
  }
}
```

### Manual Management

```dart
class ManualChatService {
  final controller = LlamaController();
  
  Future<void> sendMessage(String text) async {
    final info = await controller.getContextInfo();
    
    if (info.usagePercentage > 90) {
      // Ask user
      final shouldClear = await showClearDialog();
      if (shouldClear) {
        await controller.clearContext();
      } else {
        throw Exception('Context full');
      }
    }
    
    // Continue...
  }
}
```

## Configuration Options

### Context Strategy Settings

```dart
final strategy = ContextStrategy(
  contextSize: 2048,           // Match your model's context
  reservedForGeneration: 512,  // Reserve for responses
);

// Thresholds
ContextStrategy.warningThreshold;   // 0.70 (70%)
ContextStrategy.criticalThreshold;  // 0.85 (85%)
```

### Chat Service Settings

```dart
final chatService = ChatService();

// Automatic mode (default)
chatService.autoManageContext = true;
chatService.maxMessagesToKeep = 10;

// Manual mode
chatService.autoManageContext = false;
// Handle context overflow yourself
```

## Best Practices

### 1. For Short Chat Messages

```dart
// Use higher message retention
chatService.maxMessagesToKeep = 15;

// Standard reserve
final strategy = ContextStrategy(
  contextSize: 2048,
  reservedForGeneration: 512,
);
```

### 2. For Long-Form Generation

```dart
// Keep fewer messages
chatService.maxMessagesToKeep = 5;

// Reserve more space for generation
final strategy = ContextStrategy(
  contextSize: 2048,
  reservedForGeneration: 1024,  // Larger reserve
);
```

### 3. Mixed Usage

```dart
// Let dynamic allocation handle it
final maxTokens = strategy.calculateDynamicMaxTokens();
// Automatically adjusts: 512 → 256 → 100 as context fills
```

## Token Estimation

The `ContextStrategy` provides rough token estimation:

```dart
// Estimate tokens for text (1 token ≈ 3.5 characters)
final estimated = strategy.estimateTokens('Hello, world!');

// Estimate for multiple strings
final total = strategy.estimateTokensForList([
  'First message',
  'Second message',
]);
```

**Note**: This is a rough approximation. Actual tokenization may vary by model.

## Troubleshooting

### Context Fills Too Quickly

```dart
// Increase context size when loading
await controller.loadModel(
  modelPath: modelPath,
  contextSize: 4096,  // Larger context
);

// Or reduce message retention
chatService.maxMessagesToKeep = 5;
```

### Generation Stops Early

```dart
// Check available tokens
final available = strategy.tokensAvailable;
print('Available for generation: $available');

// Use dynamic allocation
final maxTokens = strategy.calculateDynamicMaxTokens();
```

### Memory Issues on Mobile

```dart
// Use smaller context
await controller.loadModel(
  modelPath: modelPath,
  contextSize: 1024,  // Smaller for mobile
);

// More aggressive trimming
chatService.maxMessagesToKeep = 5;
```

## API Reference

### LlamaController

```dart
// Get context information
Future<ContextInfo> getContextInfo()

// Clear context
Future<void> clearContext()

// Set system prompt length (optional)
void setSystemPromptLength(int length)
```

### ContextInfo

```dart
class ContextInfo {
  int tokensUsed;
  int contextSize;
  double usagePercentage;
}
```

### ContextStrategy

```dart
class ContextStrategy {
  ContextStrategy({
    required int contextSize,
    int reservedForGeneration = 512,
  });
  
  // Properties
  double get usageRatio;
  bool get needsWarning;
  bool get needsAction;
  int get tokensAvailable;
  
  // Methods
  int estimateTokens(String text);
  int estimateTokensForList(List<String> texts);
  ContextAction getRecommendedAction(String nextMessage);
  int calculateDynamicMaxTokens({int defaultMaxTokens = 512});
}
```

### ContextAction

```dart
enum ContextAction {
  proceed,                 // All good
  showWarning,            // Show warning
  shouldTrimOrSummarize,  // Should trim
  mustClear,              // Must clear
}
```

## Performance Considerations

### Context Clearing vs. Model Reload

- **Clear Context**: ~10ms, keeps model loaded
- **Reload Model**: ~5-30 seconds

Always prefer clearing context over reloading.

### Memory Usage

- Context size affects memory:
  - 1024 tokens: ~50-100 MB
  - 2048 tokens: ~100-200 MB
  - 4096 tokens: ~200-400 MB

Choose based on device capabilities.

## Migration Guide

### From Basic to Context-Aware

**Before:**
```dart
// No context management
await controller.generateChat(
  messages: messages,
  maxTokens: 512,
);
```

**After:**
```dart
// With context management
final info = await controller.getContextInfo();
if (info.usagePercentage > 85) {
  await controller.clearContext();
  // Trim messages
}

final strategy = ContextStrategy(contextSize: info.contextSize);
strategy.currentTokens = info.tokensUsed;
final maxTokens = strategy.calculateDynamicMaxTokens();

await controller.generateChat(
  messages: messages,
  maxTokens: maxTokens,
);
```

## Examples

See the example app for a complete implementation:
- `example/lib/services/chat_service.dart` - Context-aware chat service
- `example/lib/main.dart` - UI with context indicator

## Future Enhancements (Not Implemented)

Possible future features:
- Conversation summarization
- Multi-session context management
- Conversation archiving/restore
- Advanced context statistics

## Support

For issues or questions:
- GitHub: [llama_flutter](https://github.com/dragneel2074/llama_flutter)
- Issues: [Report a bug](https://github.com/dragneel2074/llama_flutter/issues)
