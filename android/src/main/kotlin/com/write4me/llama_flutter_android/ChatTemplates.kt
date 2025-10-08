package com.write4me.llama_flutter_android

/**
 * Chat message with role and content
 */
data class ChatMessage(
    val role: String, // "system", "user", or "assistant"
    val content: String
)

/**
 * Interface for chat template formatters
 */
interface ChatTemplate {
    fun format(messages: List<ChatMessage>): String
    val name: String
}

/**
 * ChatML format used by Qwen, Llama-3, and others
 * Format:
 * <|im_start|>system
 * {system_message}<|im_end|>
 * <|im_start|>user
 * {user_message}<|im_end|>
 * <|im_start|>assistant
 * {assistant_message}<|im_end|>
 */
class ChatMLTemplate : ChatTemplate {
    override val name = "chatml"
    
    override fun format(messages: List<ChatMessage>): String {
        val builder = StringBuilder()
        
        for (message in messages) {
            builder.append("<|im_start|>${message.role}\n")
            builder.append("${message.content}<|im_end|>\n")
        }
        
        // Add the final assistant turn start
        builder.append("<|im_start|>assistant\n")
        
        return builder.toString()
    }
}

/**
 * Llama-2 format
 * Format:
 * [INST] <<SYS>>
 * {system_message}
 * <</SYS>>
 * 
 * {user_message} [/INST] {assistant_message} [INST] {user_message} [/INST]
 */
class Llama2Template : ChatTemplate {
    override val name = "llama2"
    
    override fun format(messages: List<ChatMessage>): String {
        val builder = StringBuilder()
        var isFirstUser = true
        var hasSystem = false
        
        for (message in messages) {
            when (message.role) {
                "system" -> {
                    if (isFirstUser) {
                        builder.append("[INST] <<SYS>>\n")
                        builder.append("${message.content}\n")
                        builder.append("<</SYS>>\n\n")
                        hasSystem = true
                    }
                }
                "user" -> {
                    if (isFirstUser && !hasSystem) {
                        builder.append("[INST] ")
                    } else if (!isFirstUser) {
                        builder.append(" [INST] ")
                    }
                    builder.append(message.content)
                    builder.append(" [/INST]")
                    isFirstUser = false
                }
                "assistant" -> {
                    builder.append(" ${message.content}")
                }
            }
        }
        
        return builder.toString()
    }
}

/**
 * Alpaca format
 * Format:
 * Below is an instruction that describes a task. Write a response that appropriately completes the request.
 * 
 * ### Instruction:
 * {user_message}
 * 
 * ### Response:
 */
class AlpacaTemplate : ChatTemplate {
    override val name = "alpaca"
    
    override fun format(messages: List<ChatMessage>): String {
        val builder = StringBuilder()
        val systemMessage = messages.firstOrNull { it.role == "system" }?.content
            ?: "Below is an instruction that describes a task. Write a response that appropriately completes the request."
        
        builder.append("$systemMessage\n\n")
        
        for (message in messages) {
            when (message.role) {
                "user" -> {
                    builder.append("### Instruction:\n")
                    builder.append("${message.content}\n\n")
                }
                "assistant" -> {
                    builder.append("### Response:\n")
                    builder.append("${message.content}\n\n")
                }
            }
        }
        
        // Add final response prompt
        builder.append("### Response:\n")
        
        return builder.toString()
    }
}

/**
 * Vicuna format
 * Format:
 * A chat between a curious user and an artificial intelligence assistant. The assistant gives helpful, detailed, and polite answers to the user's questions.
 * 
 * USER: {user_message}
 * ASSISTANT: {assistant_message}
 */
class VicunaTemplate : ChatTemplate {
    override val name = "vicuna"
    
    override fun format(messages: List<ChatMessage>): String {
        val builder = StringBuilder()
        val systemMessage = messages.firstOrNull { it.role == "system" }?.content
            ?: "A chat between a curious user and an artificial intelligence assistant. The assistant gives helpful, detailed, and polite answers to the user's questions."
        
        builder.append("$systemMessage\n\n")
        
        for (message in messages) {
            when (message.role) {
                "user" -> {
                    builder.append("USER: ${message.content}\n")
                }
                "assistant" -> {
                    builder.append("ASSISTANT: ${message.content}\n")
                }
            }
        }
        
        // Add final assistant prompt
        builder.append("ASSISTANT:")
        
        return builder.toString()
    }
}

/**
 * Phi-2/Phi-3 format (similar to ChatML but with different tokens)
 */
class PhiTemplate : ChatTemplate {
    override val name = "phi"
    
    override fun format(messages: List<ChatMessage>): String {
        val builder = StringBuilder()
        
        for (message in messages) {
            when (message.role) {
                "system" -> {
                    builder.append("<|system|>\n${message.content}<|end|>\n")
                }
                "user" -> {
                    builder.append("<|user|>\n${message.content}<|end|>\n")
                }
                "assistant" -> {
                    builder.append("<|assistant|>\n${message.content}<|end|>\n")
                }
            }
        }
        
        builder.append("<|assistant|>\n")
        
        return builder.toString()
    }
}

/**
 * Gemma format
 */
class GemmaTemplate : ChatTemplate {
    override val name = "gemma"
    
    override fun format(messages: List<ChatMessage>): String {
        val builder = StringBuilder()
        
        for (message in messages) {
            when (message.role) {
                "user" -> {
                    builder.append("<start_of_turn>user\n${message.content}<end_of_turn>\n")
                }
                "assistant" -> {
                    builder.append("<start_of_turn>model\n${message.content}<end_of_turn>\n")
                }
            }
        }
        
        builder.append("<start_of_turn>model\n")
        
        return builder.toString()
    }
}

/**
 * Manager for chat templates
 */
object ChatTemplateManager {
    private val templates: Map<String, ChatTemplate> = mapOf(
        "chatml" to ChatMLTemplate(),
        "qwen" to ChatMLTemplate(), // Qwen uses ChatML
        "llama3" to ChatMLTemplate(), // Llama-3 uses ChatML
        "llama2" to Llama2Template(),
        "alpaca" to AlpacaTemplate(),
        "vicuna" to VicunaTemplate(),
        "phi" to PhiTemplate(),
        "gemma" to GemmaTemplate()
    )
    
    fun getTemplate(name: String): ChatTemplate? {
        return templates[name.lowercase()]
    }
    
    fun getSupportedTemplates(): List<String> {
        return templates.keys.toList()
    }
    
    /**
     * Auto-detect template based on model name/path
     */
    fun detectTemplate(modelPath: String): ChatTemplate {
        val lowerPath = modelPath.lowercase()
        
        return when {
            lowerPath.contains("qwen") -> templates["qwen"]!!
            lowerPath.contains("llama-3") || lowerPath.contains("llama3") -> templates["llama3"]!!
            lowerPath.contains("llama-2") || lowerPath.contains("llama2") -> templates["llama2"]!!
            lowerPath.contains("phi") -> templates["phi"]!!
            lowerPath.contains("gemma") -> templates["gemma"]!!
            lowerPath.contains("alpaca") -> templates["alpaca"]!!
            lowerPath.contains("vicuna") -> templates["vicuna"]!!
            else -> templates["chatml"]!! // Default to ChatML
        }
    }
    
    /**
     * Format messages using specified or auto-detected template
     */
    fun formatMessages(
        messages: List<ChatMessage>,
        templateName: String? = null,
        modelPath: String? = null
    ): String {
        val template = when {
            templateName != null -> getTemplate(templateName) ?: detectTemplate(modelPath ?: "")
            modelPath != null -> detectTemplate(modelPath)
            else -> ChatMLTemplate() // Default
        }
        
        return template.format(messages)
    }
}
