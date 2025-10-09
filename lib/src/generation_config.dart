/// Configuration for text generation
/// 
/// Allows users to customize generation parameters
class GenerationConfig {
  /// Maximum tokens to generate (default: 150)
  final int maxTokens;
  
  /// Temperature for sampling (0.0-2.0, default: 0.7)
  /// Lower = more focused, Higher = more creative
  final double temperature;
  
  /// Top-p nucleus sampling (0.0-1.0, default: 0.9)
  final double topP;
  
  /// Top-k sampling (default: 40)
  final int topK;
  
  /// Repetition penalty (1.0-1.5, default: 1.1)
  final double repeatPenalty;
  
  /// Random seed for reproducibility (null = random)
  final int? seed;
  
  const GenerationConfig({
    this.maxTokens = 150,
    this.temperature = 0.7,
    this.topP = 0.9,
    this.topK = 40,
    this.repeatPenalty = 1.1,
    this.seed,
  });
}

/// Configuration for model loading
class ModelLoadConfig {
  /// Context window size in tokens (default: 2048)
  final int contextSize;
  
  /// Number of CPU threads (default: 4)
  final int threads;
  
  /// Number of GPU layers (null = CPU only)
  final int? gpuLayers;
  
  const ModelLoadConfig({
    this.contextSize = 2048,
    this.threads = 4,
    this.gpuLayers,
  });
}

/// Simple context management helper
/// 
/// **80% Rule**: Only use 80% of context to leave safety buffer
/// 
/// Example:
/// - Context: 2048 tokens
/// - Safe limit: 1638 tokens (80%)
/// - Safety buffer: 410 tokens (20%)
class ContextHelper {
  final int contextSize;
  
  /// Use 80% of context as the safe limit
  static const double safeUsageLimit = 0.80;
  
  /// Maximum messages to keep in history (including system prompt)
  final int maxMessagesToKeep;
  
  ContextHelper({
    required this.contextSize,
    this.maxMessagesToKeep = 10,
  });
  
  /// Get the safe token limit (80% of context)
  int get safeTokenLimit => (contextSize * safeUsageLimit).floor();
  
  /// Get the safety buffer size (20% of context)
  int get safetyBuffer => contextSize - safeTokenLimit;
  
  /// Check if context usage is approaching the safe limit (>72% of total)
  bool isNearLimit(int tokensUsed) {
    return tokensUsed >= (safeTokenLimit * 0.9); // 90% of 80% = 72%
  }
  
  /// Check if context must be cleared (≥80% of total)
  bool mustClear(int tokensUsed) {
    return tokensUsed >= safeTokenLimit;
  }
  
  /// Rough token estimation (1 token ≈ 3.5 characters)
  int estimateTokens(String text) => (text.length / 3.5).ceil();
  
  /// Calculate safe max tokens for generation based on current usage
  /// 
  /// Ensures generation won't exceed safe limit
  int calculateSafeMaxTokens(int tokensUsed, int requestedMaxTokens) {
    final available = safeTokenLimit - tokensUsed;
    
    if (available < 50) {
      return 50; // Minimum response
    } else if (available < requestedMaxTokens) {
      return available; // Use what's safely available
    } else {
      return requestedMaxTokens; // Use requested
    }
  }
  
  /// Get usage percentage (0-100)
  double getUsagePercentage(int tokensUsed) {
    return (tokensUsed / contextSize) * 100;
  }
}
