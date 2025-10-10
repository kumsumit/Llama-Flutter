# Custom Chat Template Implementation - Issue & Solution

## Current Problem

Your app **already has** a custom template system, but it has a critical limitation:

### What Works ✅
- Users can create custom templates via `_showCustomTemplateEditor()`
- Templates are stored in `SharedPreferences` with name + content
- Templates appear in the settings dropdown
- The UI is fully functional

### What Doesn't Work ❌
- **Custom templates are never sent to native Kotlin code**
- The `ChatTemplateManager` in Kotlin only knows about hardcoded templates
- When a user selects a custom template, it's passed as a name (e.g., "my-custom-template")
- Kotlin can't find it, so it falls back to auto-detection or default

## Architecture Issue

```
┌─────────────────────────────────────────────────────────────┐
│ Flutter Side (Dart)                                         │
├─────────────────────────────────────────────────────────────┤
│ 1. User creates "mistral-custom" template                   │
│    Content: "<s>[INST] {user} [/INST]{assistant}</s>"       │
│                                                              │
│ 2. Stored in SharedPreferences ✅                           │
│    customTemplates["mistral-custom"] = "<s>[INST]..."       │
│                                                              │
│ 3. User selects "mistral-custom" in dropdown ✅             │
│                                                              │
│ 4. sendMessage() called with template: "mistral-custom"     │
│    ↓                                                         │
│    generateChat(template: "mistral-custom") // Just the name│
│                                                              │
└─────────────────────────────────────────────────────────────┘
                            ↓
                      Via Pigeon API
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Native Kotlin Side                                          │
├─────────────────────────────────────────────────────────────┤
│ 5. ChatRequest received:                                    │
│    template = "mistral-custom"  ← Just a string!            │
│                                                              │
│ 6. ChatTemplateManager.getTemplate("mistral-custom")        │
│    ❌ Returns null - not in hardcoded map!                 │
│                                                              │
│ 7. Falls back to auto-detection ❌                          │
│    Uses built-in template instead                           │
│                                                              │
│ ❌ User's custom template is never used!                   │
└─────────────────────────────────────────────────────────────┘
```

## Solution Options

### Option 1: Send Full Template Content (Recommended)

**Pros**: Simple, works immediately, no code regeneration
**Cons**: Sends template string on every message (small overhead)

#### Implementation:

**A) Modify `sendMessage` in ChatService**

```dart
void sendMessage(String message, {String? template}) async {
  // ... existing code ...
  
  // NEW: Get actual template content if it's a custom template
  String? templateContent;
  if (template != null && _settingsService.customTemplateNames.contains(template)) {
    templateContent = _settingsService.getCustomTemplateContent(template);
    debugPrint('[ChatService] Using custom template content for: $template');
  }
  
  // Pass to generateChat
  _generationSubscription = _llama!.generateChat(
    messages: messagesToSend,
    template: templateContent ?? template, // Send content OR name
    // ... other params
  ).listen(
    // ... existing code
  );
}
```

**B) Update Native Kotlin to Handle Raw Templates**

```kotlin
fun formatMessages(
    messages: List<TemplateChatMessage>,
    templateName: String? = null,
    modelPath: String? = null
): String {
    // NEW: Check if templateName looks like raw template content
    if (templateName != null && isRawTemplate(templateName)) {
        android.util.Log.d("ChatTemplateManager", "Using raw template content")
        return formatWithRawTemplate(messages, templateName)
    }
    
    // Existing template lookup logic
    val template = when {
        templateName != null -> {
            getTemplate(templateName) ?: run {
                android.util.Log.w("ChatTemplateManager", 
                    "Unknown template '$templateName', falling back to auto-detection")
                detectTemplate(modelPath ?: "")
            }
        }
        modelPath != null -> detectTemplate(modelPath)
        else -> {
            android.util.Log.w("ChatTemplateManager", 
                "No template or model path provided, using ChatML default")
            ChatMLTemplate()
        }
    }
    
    return template.format(messages)
}

private fun isRawTemplate(str: String): Boolean {
    // Check if it contains template placeholders
    return str.contains("{") && 
           (str.contains("{user}") || str.contains("{assistant}") || str.contains("{system}"))
}

private fun formatWithRawTemplate(
    messages: List<TemplateChatMessage>,
    template: String
): String {
    val builder = StringBuilder()
    
    for (message in messages) {
        val formatted = when (message.role) {
            "system" -> template.replace("{system}", message.content)
            "user" -> template.replace("{user}", message.content)
            "assistant" -> template.replace("{assistant}", message.content)
            else -> message.content
        }
        builder.append(formatted)
    }
    
    return builder.toString()
}
```

---

### Option 2: Dynamic Template Registration (More Complex)

**Pros**: Cleaner architecture, faster runtime
**Cons**: Requires Pigeon API changes, more complex

#### Implementation:

**A) Add method to Pigeon API**

```dart
// In pigeons/llama_api.dart
@HostApi()
abstract class LlamaHostApi {
  // ... existing methods ...
  
  /// Register a custom template
  void registerCustomTemplate(String name, String content);
  
  /// Unregister a custom template
  void unregisterCustomTemplate(String name);
}
```

**B) Regenerate Pigeon**
```bash
flutter pub run pigeon --input pigeons/llama_api.dart
```

**C) Implement in Kotlin**

```kotlin
// In LlamaFlutterAndroidPlugin.kt
override fun registerCustomTemplate(name: String, content: String) {
    ChatTemplateManager.registerCustomTemplate(name, content)
}

override fun unregisterCustomTemplate(name: String) {
    ChatTemplateManager.unregisterCustomTemplate(name)
}
```

**D) Update ChatTemplateManager**

```kotlin
object ChatTemplateManager {
    private val templates: MutableMap<String, ChatTemplate> = mutableMapOf(
        // ... existing hardcoded templates ...
    )
    
    // NEW: Custom template registry
    private val customTemplates: MutableMap<String, String> = mutableMapOf()
    
    fun registerCustomTemplate(name: String, content: String) {
        customTemplates[name.lowercase()] = content
        android.util.Log.i("ChatTemplateManager", 
            "Registered custom template: $name")
    }
    
    fun unregisterCustomTemplate(name: String) {
        customTemplates.remove(name.lowercase())
    }
    
    fun getTemplate(name: String): ChatTemplate? {
        // Check custom templates first
        customTemplates[name.lowercase()]?.let { content ->
            return RawTemplate(name, content)
        }
        
        // Fall back to hardcoded templates
        return templates[name.lowercase()]
    }
}

// NEW: Template that uses raw string content
class RawTemplate(
    override val name: String,
    private val templateContent: String
) : ChatTemplate {
    override fun format(messages: List<TemplateChatMessage>): String {
        // Parse and apply template content
        // Implement placeholder substitution logic
        return formatWithRawTemplate(messages, templateContent)
    }
    
    private fun formatWithRawTemplate(
        messages: List<TemplateChatMessage>,
        template: String
    ): String {
        // Implementation here (same as Option 1)
    }
}
```

**E) Register templates on app start**

```dart
// In ChatService.initialize()
Future<bool> initialize({String? systemMessage}) async {
  // ... existing code ...
  
  // Register all custom templates with native code
  final customTemplates = _settingsService.getAllCustomTemplates();
  for (final entry in customTemplates.entries) {
    await _llama?.registerCustomTemplate(entry.key, entry.value);
    debugPrint('[ChatService] Registered custom template: ${entry.key}');
  }
  
  return modelExists;
}
```

---

## Recommendation

### Quick Fix (Option 1)
Use **Option 1** for immediate functionality:
1. No API changes needed
2. Works with existing code
3. Small performance overhead (negligible)

### Long-term (Option 2)
Implement **Option 2** for better architecture:
1. Templates registered once
2. Cleaner separation of concerns
3. Better performance

---

## Enhanced UI Flow

### Improved Custom Template Dialog

The existing dialog works but could be enhanced:

```dart
void _showCustomTemplateEditor(BuildContext context) async {
  final nameController = TextEditingController();
  final contentController = TextEditingController();
  
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Create Custom Template'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name field
            Text('Template Name', 
              style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'e.g., mistral-instruct, zephyr',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Template format help
            ExpansionTile(
              title: Text('Template Format Help', 
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              children: [
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Use these placeholders:', 
                        style: TextStyle(fontWeight: FontWeight.w500)),
                      SizedBox(height: 8),
                      Text('• {system} - System message'),
                      Text('• {user} - User message'),  
                      Text('• {assistant} - AI response'),
                      SizedBox(height: 8),
                      Text('Examples:', 
                        style: TextStyle(fontWeight: FontWeight.w500)),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mistral:', 
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                            Text('<s>[INST] {user} [/INST]{assistant}</s>',
                              style: TextStyle(fontSize: 11, fontFamily: 'monospace')),
                            SizedBox(height: 8),
                            Text('Zephyr:', 
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                            Text('<|system|>\\n{system}<|endoftext|>\\n<|user|>\\n{user}<|endoftext|>\\n<|assistant|>\\n',
                              style: TextStyle(fontSize: 11, fontFamily: 'monospace')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Content field
            Text('Template Content', 
              style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: contentController,
              maxLines: 8,
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Enter template format with {user}, {assistant} placeholders...',
                hintStyle: TextStyle(fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Preview section
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tip: Test your template with a simple message after creating it',
                      style: TextStyle(fontSize: 11, color: Colors.blue[900]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final name = nameController.text.trim();
            final content = contentController.text.trim();
            
            if (name.isNotEmpty && content.isNotEmpty) {
              // Validate template has required placeholders
              if (!content.contains('{user}') && !content.contains('{assistant}')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Template must contain {user} or {assistant} placeholders'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              await _chatService.addCustomTemplate(name, content);
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Custom template "$name" created'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Please provide both name and content'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Create'),
        ),
      ],
    ),
  );
}
```

---

## Testing Custom Templates

### Test Template Examples

**Mistral Instruct:**
```
<s>[INST] {user} [/INST]{assistant}</s>
```

**Zephyr:**
```
<|system|>
{system}<|endoftext|>
<|user|>
{user}<|endoftext|>
<|assistant|>
```

**Orca:**
```
<|im_start|>system
{system}<|im_end|>
<|im_start|>user
{user}<|im_end|>
<|im_start|>assistant
```

### Testing Steps

1. Create custom template
2. Select it in settings
3. Send a test message
4. Check logs for which template was used
5. Verify response formatting

---

## Summary

**Current State:**
- ✅ UI for custom templates exists
- ✅ Storage works
- ❌ Templates not used by native code

**Quick Fix (Option 1):**
- Modify `sendMessage()` to send full content
- Add raw template handler in Kotlin
- Works immediately

**Better Solution (Option 2):**
- Add Pigeon API for template registration
- Register templates on app start
- Cleaner architecture

**Recommendation:**
Start with Option 1 for immediate functionality, then refactor to Option 2 for production quality.

---

Last Updated: October 10, 2025
