import 'package:flutter/material.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';

void main() {
  runApp(const ChatTemplateExampleApp());
}

class ChatTemplateExampleApp extends StatelessWidget {
  const ChatTemplateExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Template Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = LlamaController();
  final _messageController = TextEditingController();
  final _messages = <ChatMessage>[];
  final _displayMessages = <String>[];
  
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _currentResponse;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Replace with actual model path
      await _controller.loadModel(
        modelPath: '/storage/emulated/0/Download/Qwen2-0.5B-Instruct-Q4_K_M.gguf',
        threads: 4,
        contextSize: 2048,
      );
      
      // Add system message
      _messages.add(ChatMessage(
        role: 'system',
        content: 'You are a helpful AI assistant. Provide concise and accurate responses.',
      ));
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Model loaded successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading model: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isGenerating) return;

    _messageController.clear();
    
    // Add user message
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _displayMessages.add('You: $text');
      _displayMessages.add('AI: ');
      _isGenerating = true;
      _currentResponse = '';
    });

    try {
      // Generate response using chat template
      final stream = _controller.generateChat(
        messages: _messages,
        maxTokens: 256,
        temperature: 0.7,
        topP: 0.9,
        topK: 40,
      );

      await for (final token in stream) {
        setState(() {
          _currentResponse = (_currentResponse ?? '') + token;
          _displayMessages[_displayMessages.length - 1] = 'AI: $_currentResponse';
        });
      }

      // Add assistant message to history
      if (_currentResponse != null && _currentResponse!.isNotEmpty) {
        _messages.add(ChatMessage(
          role: 'assistant',
          content: _currentResponse!,
        ));
      }
    } catch (e) {
      setState(() {
        _displayMessages[_displayMessages.length - 1] = 'AI: Error: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
        _currentResponse = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Template Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_messages.length > 1)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                setState(() {
                  // Keep only system message
                  _messages.removeRange(1, _messages.length);
                  _displayMessages.clear();
                });
              },
              tooltip: 'Clear chat',
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading)
            const LinearProgressIndicator(),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _displayMessages.isEmpty
                    ? const Center(
                        child: Text(
                          'Send a message to start chatting!',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _displayMessages.length,
                        itemBuilder: (context, index) {
                          final message = _displayMessages[index];
                          final isUser = message.startsWith('You:');
                          
                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? Colors.blue[100]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                message,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isUser ? Colors.blue[900] : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_isLoading && !_isGenerating,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: _isLoading || _isGenerating ? null : _sendMessage,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
