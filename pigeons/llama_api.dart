import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  kotlinOut: 'android/src/main/kotlin/com/write4me/llama_flutter_android/LlamaHostApi.kt',
  kotlinOptions: KotlinOptions(
    package: 'com.write4me.llama_flutter_android',
  ),
  dartOut: 'lib/src/llama_api.dart',
  dartOptions: DartOptions(),
))
  
/// Configuration for model loading
class ModelConfig {
  final String modelPath;
  final int nThreads;
  final int contextSize;
  final int? nGpuLayers;
  
  ModelConfig({
    required this.modelPath,
    this.nThreads = 4,
    this.contextSize = 2048,
    this.nGpuLayers,
  });
}

/// Chat message
class ChatMessage {
  /// Role: 'system', 'user', or 'assistant'
  final String role;
  final String content;
  
  ChatMessage({
    required this.role,
    required this.content,
  });
}

/// Request for text generation
class GenerateRequest {
  final String prompt;
  final int maxTokens;
  final double temperature;
  final double topP;
  final int topK;
  
  GenerateRequest({
    required this.prompt,
    this.maxTokens = 512,
    this.temperature = 0.7,
    this.topP = 0.9,
    this.topK = 40,
  });
}

/// Request for chat generation with template formatting
class ChatRequest {
  final List<ChatMessage> messages;
  final String? template; // null = auto-detect from model
  final int maxTokens;
  final double temperature;
  final double topP;
  final int topK;
  
  ChatRequest({
    required this.messages,
    this.template,
    this.maxTokens = 512,
    this.temperature = 0.7,
    this.topP = 0.9,
    this.topK = 40,
  });
}

/// Host API (Dart calls Kotlin)
@HostApi()
abstract class LlamaHostApi {
  /// Load a GGUF model
  @async
  void loadModel(ModelConfig config);
  
  /// Start text generation (tokens streamed via FlutterApi)
  @async
  void generate(GenerateRequest request);
  
  /// Start chat generation with automatic template formatting
  @async
  void generateChat(ChatRequest request);
  
  /// Get list of supported chat templates
  List<String> getSupportedTemplates();
  
  /// Stop current generation
  @async
  void stop();
  
  /// Unload model and free resources
  @async
  void dispose();
  
  /// Check if model is loaded
  bool isModelLoaded();
}

/// Flutter API (Kotlin calls Dart)
@FlutterApi()
abstract class LlamaFlutterApi {
  /// Stream token to Dart
  void onToken(String token);
  
  /// Generation completed
  void onDone();
  
  /// Error occurred
  void onError(String error);
  
  /// Loading progress (0.0 to 1.0)
  void onLoadProgress(double progress);
}