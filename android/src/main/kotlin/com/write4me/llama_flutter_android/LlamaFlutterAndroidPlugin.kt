package com.write4me.llama_flutter_android

import android.                )

                currentModelPath = config.modelPath
                isModelLoaded.set(true)
                withContext(Dispatchers.Main) {
                    callback(Result.success(Unit))
                }t.Context
import android.content.Intent
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import kotlinx.coroutines.*
import java.util.concurrent.atomic.AtomicBoolean

class LlamaFlutterAndroidPlugin : FlutterPlugin, LlamaHostApi {
    private lateinit var context: Context
    private lateinit var flutterApi: LlamaFlutterApi
    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    private var generationJob: Job? = null
    private val isModelLoaded = AtomicBoolean(false)
    private val isStopping = AtomicBoolean(false)
    private var currentModelPath: String? = null

    companion object {
        init {
            System.loadLibrary("llama_jni")
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        flutterApi = LlamaFlutterApi(binding.binaryMessenger)
        LlamaHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        scope.cancel()
        if (isModelLoaded.get()) {
            nativeFreeModel()
        }
        LlamaHostApi.setUp(binding.binaryMessenger, null)
    }

    override fun loadModel(config: ModelConfig, callback: (Result<Unit>) -> Unit) {
        scope.launch {
            try {
                // Start foreground service for long-running task
                val intent = Intent(context, InferenceService::class.java)
                ContextCompat.startForegroundService(context, intent)

                // Load model with progress callback
                nativeLoadModel(
                    config.modelPath,
                    config.nThreads,
                    config.contextSize,
                    config.nGpuLayers ?: 0L
                ) { progress ->
                    scope.launch {
                        withContext(Dispatchers.Main) {
                            flutterApi.onLoadProgress(progress) { result ->
                                // Handle result if needed
                            }
                        }
                    }
                }

                isModelLoaded.set(true)
                withContext(Dispatchers.Main) {
                    callback(Result.success(Unit))
                }
            } catch (e: Exception) {
                scope.launch {
                    withContext(Dispatchers.Main) {
                        flutterApi.onError(e.message ?: "Failed to load model") { result ->
                            // Handle result if needed
                        }
                        callback(Result.failure(e))
                    }
                }
            }
        }
    }

    override fun generate(request: GenerateRequest, callback: (Result<Unit>) -> Unit) {
        if (!isModelLoaded.get()) {
            callback(Result.failure(IllegalStateException("Model not loaded")))
            return
        }

        isStopping.set(false)
        generationJob = scope.launch {
            try {
                nativeGenerate(
                    request.prompt,
                    request.maxTokens,
                    request.temperature,
                    request.topP,
                    request.topK
                ) { token ->
                    if (!isStopping.get()) {
                        scope.launch {
                            withContext(Dispatchers.Main) {
                                flutterApi.onToken(token) { result ->
                                    // Handle result if needed
                                }
                            }
                        }
                    }
                }

                if (!isStopping.get()) {
                    scope.launch {
                        withContext(Dispatchers.Main) {
                            flutterApi.onDone { result ->
                                // Handle result if needed
                            }
                        }
                    }
                }

                withContext(Dispatchers.Main) {
                    callback(Result.success(Unit))
                }
            } catch (e: Exception) {
                if (!isStopping.get()) {
                    scope.launch {
                        withContext(Dispatchers.Main) {
                            flutterApi.onError(e.message ?: "Generation failed") { result ->
                                // Handle result if needed
                            }
                            callback(Result.failure(e))
                        }
                    }
                }
            }
        }
    }

    override fun stop(callback: (Result<Unit>) -> Unit) {
        isStopping.set(true)
        generationJob?.cancel()
        nativeStop()
        callback(Result.success(Unit))
    }

    override fun dispose(callback: (Result<Unit>) -> Unit) {
        scope.launch {
            try {
                stop { }
                if (isModelLoaded.get()) {
                    nativeFreeModel()
                    isModelLoaded.set(false)
                }
                
                // Stop foreground service
                val intent = Intent(context, InferenceService::class.java)
                context.stopService(intent)
                
                withContext(Dispatchers.Main) {
                    callback(Result.success(Unit))
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun isModelLoaded(): Boolean {
        return isModelLoaded.get()
    }

    override fun generateChat(request: ChatRequest, callback: (Result<Unit>) -> Unit) {
        if (!isModelLoaded.get()) {
            callback(Result.failure(IllegalStateException("Model not loaded")))
            return
        }

        // Convert ChatMessage list to Kotlin ChatMessage list
        val messages = request.messages.map { msg ->
            com.write4me.llama_flutter_android.ChatMessage(
                role = msg.role,
                content = msg.content
            )
        }

        // Format using chat template
        val formattedPrompt = ChatTemplateManager.formatMessages(
            messages = messages,
            templateName = request.template,
            modelPath = currentModelPath
        )

        // Use existing generate method with formatted prompt
        val generateRequest = GenerateRequest(
            prompt = formattedPrompt,
            maxTokens = request.maxTokens,
            temperature = request.temperature,
            topP = request.topP,
            topK = request.topK
        )

        generate(generateRequest, callback)
    }

    override fun getSupportedTemplates(): List<String> {
        return ChatTemplateManager.getSupportedTemplates()
    }

    // Native methods
    private external fun nativeLoadModel(
        path: String,
        nThreads: Long,
        contextSize: Long,
        nGpuLayers: Long,
        progressCallback: (Double) -> Unit
    )

    private external fun nativeGenerate(
        prompt: String,
        maxTokens: Long,
        temperature: Double,
        topP: Double,
        topK: Long,
        tokenCallback: (String) -> Unit
    )

    private external fun nativeStop()
    private external fun nativeFreeModel()
}