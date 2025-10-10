# Custom Chat Template User Guide

## Quick Start Guide 🚀

### Creating Your First Custom Template

1. **Open Settings**
   - Tap the settings icon in the app
   - Scroll to "Custom Chat Templates" section (blue box)

2. **Click "Create New Template"**
   - A dialog will open with template editor

3. **Enter Template Name**
   - Example: `mistral-instruct`, `my-llama`, `custom-phi`
   - Use descriptive names to remember what model it's for

4. **Enter Template Content**
   - Use the placeholders: `{system}`, `{user}`, `{assistant}`
   - See examples below for common formats

5. **Click "Create"**
   - Template is automatically saved and registered
   - You'll see a green success message

6. **Select Your Template**
   - Go to "Chat Template" dropdown in settings
   - Your custom template will appear at the bottom of the list
   - Select it

7. **Use It!**
   - Load your model
   - Send messages
   - The template will be applied automatically

---

## Template Format Guide 📝

### Placeholders

| Placeholder | Purpose | Required |
|-------------|---------|----------|
| `{system}` | System message (instructions) | Optional |
| `{user}` | User's input message | **Required** |
| `{assistant}` | AI's response | **Required** |

### Template Examples

#### 1. Mistral Instruct (Simple)
```
<s>[INST]{user}[/INST]{assistant}</s>
```

#### 2. Mistral Instruct (With System)
```
<s>[INST]{system}

{user}[/INST]{assistant}</s>
```

#### 3. Llama 3
```
<|begin_of_text|><|start_header_id|>system<|end_header_id|>

{system}<|eot_id|><|start_header_id|>user<|end_header_id|>

{user}<|eot_id|><|start_header_id|>assistant<|end_header_id|>

{assistant}<|eot_id|>
```

#### 4. ChatML Format
```
<|im_start|>system
{system}<|im_end|>
<|im_start|>user
{user}<|im_end|>
<|im_start|>assistant
{assistant}<|im_end|>
```

#### 5. Alpaca Style
```
### Instruction:
{user}

### Response:
{assistant}
```

#### 6. Simple Format
```
User: {user}
Assistant: {assistant}

```

#### 7. Phi-3 Format
```
<|system|>
{system}<|end|>
<|user|>
{user}<|end|>
<|assistant|>
{assistant}<|end|>
```

#### 8. Gemma Format
```
<bos><start_of_turn>user
{user}<end_of_turn>
<start_of_turn>model
{assistant}<end_of_turn>
```

---

## Finding Your Model's Template 🔍

### Method 1: Model Card/Documentation
1. Check Hugging Face model card
2. Look for "Chat Template" section
3. Find the Jinja2 template or format description
4. Convert to our placeholder format

### Method 2: Common Patterns

**If your model is based on**:
- **Mistral/Mixtral** → Use Mistral Instruct format
- **Llama 2** → Use `[INST]` tags
- **Llama 3** → Use `<|start_header_id|>` tags
- **Phi** → Use `<|system|>`, `<|user|>`, `<|assistant|>` tags
- **Gemma** → Use `<start_of_turn>` tags
- **Qwen** → Use ChatML format

### Method 3: Test and Iterate
1. Start with a similar model's format
2. Send a test message
3. If responses are bad, try a different format
4. Check logs for template usage confirmation

---

## Managing Templates 🗂️

### View Saved Templates
- Open Settings
- Scroll to "Custom Chat Templates"
- See "Saved Templates (X)" with chips showing each template

### Delete a Template
1. Find the template chip
2. Click the ❌ icon
3. Confirm deletion
4. Template is removed and unregistered

### Update a Template
Currently, you need to:
1. Delete the old template
2. Create a new one with the same name
(Direct editing coming in future update!)

---

## Tips & Best Practices 💡

### ✅ DO:
- **Test with simple prompts first** - "Hello" or "What is 2+2?"
- **Keep template names descriptive** - "mistral-7b-instruct", not "temp1"
- **Include special tokens** - `<s>`, `</s>`, `<|im_start|>`, etc. if your model needs them
- **Check model documentation** - Official templates work best
- **Use newlines** - `\n` for line breaks if the model expects them

### ❌ DON'T:
- Use spaces in template names - use hyphens: `my-template` not `my template`
- Forget required placeholders - At minimum include `{user}` and `{assistant}`
- Copy templates with syntax errors - Test carefully
- Mix different format styles - Stick to one consistent format

---

## Troubleshooting 🔧

### Problem: "Template created but not in dropdown"
**Solution**: Close and reopen settings dialog to refresh the list

### Problem: "Model gives weird/random responses"
**Solution**: 
1. Your template might not match the model's expected format
2. Try a built-in template (Auto-Detect)
3. Check model documentation for correct format
4. Verify placeholders are spelled correctly

### Problem: "Console errors when clicking Apply"
**Solution**: 
1. Make sure template name and content are not empty
2. Check for special characters in template name
3. Verify template content has `{user}` and `{assistant}`

### Problem: "Template doesn't seem to be used"
**Solution**:
1. Check logs for: `[ChatTemplateManager] Using template: <your-name>`
2. If it says `chatml` or other name, your template wasn't selected
3. Go to Settings → Chat Template → Select your custom template
4. Reload model and try again

### Problem: "App crashes when using template"
**Solution**:
1. Template format might be incompatible with model
2. Delete the problematic template
3. Try a simpler format first
4. Check for unescaped special characters

---

## Advanced Usage 🚀

### Multi-turn Conversations
Your template is applied to **each message** in the conversation. For example:

**Template**: `<s>[INST]{user}[/INST]{assistant}</s>`

**Conversation**:
- User: "Hello"
- Bot: "Hi there!"
- User: "How are you?"

**Result**:
```
<s>[INST]Hello[/INST]Hi there!</s><s>[INST]How are you?[/INST]
```

### System Message Integration
If your template includes `{system}`, it will be used from your System Message setting:

**Template**: `[INST]<<SYS>>{system}<</SYS>>\n\n{user}[/INST]{assistant}`
**System Message**: "You are a helpful assistant"
**User Input**: "Hello"

**Result**:
```
[INST]<<SYS>>You are a helpful assistant<</SYS>>

Hello[/INST]
```

### Special Characters
Use `\n` for newlines in your template if the model expects line breaks:
```
System: {system}\nUser: {user}\nAssistant: {assistant}\n
```

---

## Examples from Popular Models 📚

### Mistral 7B Instruct
```
<s>[INST]{system}

{user}[/INST]{assistant}</s>
```

### Llama 3.1 Instruct
```
<|begin_of_text|><|start_header_id|>system<|end_header_id|>

{system}<|eot_id|><|start_header_id|>user<|end_header_id|>

{user}<|eot_id|><|start_header_id|>assistant<|end_header_id|>

{assistant}<|eot_id|>
```

### Phi-3 Mini
```
<|system|>
{system}<|end|>
<|user|>
{user}<|end|>
<|assistant|>
{assistant}<|end|>
```

### Qwen 2.5
```
<|im_start|>system
{system}<|im_end|>
<|im_start|>user
{user}<|im_end|>
<|im_start|>assistant
{assistant}<|im_end|>
```

### Gemma 2
```
<bos><start_of_turn>user
{user}<end_of_turn>
<start_of_turn>model
{assistant}<end_of_turn>
```

---

## FAQ ❓

**Q: Do I need to restart the app after creating a template?**  
A: No! Templates are registered immediately and work right away.

**Q: Can I override built-in templates?**  
A: Yes! If you create a custom template with the same name (e.g., "chatml"), yours will be used instead. A warning will be logged.

**Q: How many templates can I create?**  
A: Unlimited! But keep it organized - create only what you need.

**Q: Will my templates be saved if I close the app?**  
A: Yes! They're saved in SharedPreferences and automatically restored when you restart the app.

**Q: Can I share my templates with others?**  
A: Currently no export feature, but you can manually share the template name and content text.

**Q: What if I don't know my model's template?**  
A: Start with "Auto-Detect" - the app will try to guess based on the model filename. If that doesn't work well, try similar models' templates.

**Q: Can I use emojis or special characters in template names?**  
A: Stick to letters, numbers, hyphens, and underscores for best compatibility.

---

## Getting Help 🆘

If you're still having issues:

1. **Check the logs** - Look for `[ChatTemplateManager]` and `[ChatService]` messages
2. **Try Auto-Detect first** - Make sure your model works with built-in templates
3. **Compare with examples** - Use one of the example templates above
4. **Start simple** - Use the simplest format first, then add complexity

---

**Last Updated**: October 10, 2025  
**Version**: 2.0 (Option 2 Implementation)
