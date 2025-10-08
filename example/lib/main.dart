import 'package:flutter/material.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _llama = LlamaController();
  final _textController = TextEditingController();
  final _messages = <String>[];
  bool _isLoading = false;
  double _loadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _llama.loadProgress.listen((progress) {
      setState(() => _loadProgress = progress);
    });
  }

  Future<void> _loadModel() async {
    setState(() => _isLoading = true);
    try {
      // Replace with your model path
      await _llama.loadModel(
        modelPath: '/sdcard/Download/model.gguf',
        threads: 4,
        contextSize: 2048,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Model loaded!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generate() async {
    final prompt = _textController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _messages.add('You: $prompt');
      _messages.add('AI: ');
    });

    try {
      final stream = _llama.generate(
        prompt: prompt,
        maxTokens: 256,
        temperature: 0.7,
      );

      await for (final token in stream) {
        setState(() {
          _messages[_messages.length - 1] += token;
        });
      }
    } catch (e) {
      setState(() {
        _messages[_messages.length - 1] += '\n[Error: $e]';
      });
    }

    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Llama Flutter Android')),
        body: Column(
          children: [
            if (_isLoading)
              LinearProgressIndicator(value: _loadProgress),
            FutureBuilder<bool>(
              future: _llama.isModelLoaded(),
              builder: (context, snapshot) {
                bool isLoaded = snapshot.data ?? false;
                if (!isLoaded) {
                  return ElevatedButton(
                    onPressed: _loadModel,
                    child: const Text('Load Model'),
                  );
                }
                return Container(); // Empty container when loaded
              },
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (ctx, i) => ListTile(
                  title: Text(_messages[i]),
                ),
              ),
            ),
            FutureBuilder<bool>(
              future: _llama.isModelLoaded(),
              builder: (context, snapshot) {
                bool isLoaded = snapshot.data ?? false;
                if (isLoaded) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _generate,
                        ),
                      ],
                    ),
                  );
                }
                return Container(); // Empty container when not loaded
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _llama.dispose();
    _textController.dispose();
    super.dispose();
  }
}