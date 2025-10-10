# Testing Checklist - Custom Template Implementation

## Pre-Test Setup

- [ ] Code compiles successfully (`flutter analyze` shows 0 errors)
- [ ] App builds successfully (`flutter build apk --debug`)
- [ ] Model file available for testing

---

## Test 1: App Initialization ✅

### Steps:
1. Cold start the app (force stop first)
2. Check logs during initialization

### Expected Logs:
```
[ChatService] Initializing ChatService...
[ChatService] No custom templates to register
  OR
[ChatService] Registering X custom template(s)...
[ChatService]   ✓ Registered: <template-name>
[ChatService] ✓ Custom template registration complete
```

### Result:
- [ ] ✅ Pass - Logs show template registration
- [ ] ❌ Fail - No registration logs

---

## Test 2: Create Custom Template ✅

### Steps:
1. Open app settings
2. Find "Custom Templates" section
3. Click "Add Custom Template" (if UI is connected)
   OR use programmatic test:
   ```dart
   await chatService.addCustomTemplate(
     'test-mistral',
     '<s>[INST]{user}[/INST]{assistant}</s>',
   );
   ```
4. Check logs

### Expected Logs:
```
[ChatService] ✓ Custom template "test-mistral" added and registered
[ChatTemplateManager] Registered custom template: test-mistral
```

### Verify:
- [ ] Template appears in settings dropdown
- [ ] Template saved (check SharedPreferences)
- [ ] Registration logged

### Result:
- [ ] ✅ Pass - Template created and registered
- [ ] ❌ Fail - Error in logs

---

## Test 3: Use Custom Template ✅

### Steps:
1. Ensure custom template created (Test 2)
2. Select custom template in settings dropdown
3. Load a model
4. Send a test message: "Hello, how are you?"
5. Check logs for template usage

### Expected Logs:
```
[ChatTemplateManager] Using template: test-mistral for formatting X messages
```

### Verify:
- [ ] Log shows custom template name (not "chatml" or auto-detected)
- [ ] Response generated successfully
- [ ] Format looks correct (check raw tokens if possible)

### Result:
- [ ] ✅ Pass - Custom template used
- [ ] ❌ Fail - Different template used or error

---

## Test 4: App Restart Persistence ✅

### Steps:
1. Ensure custom template exists (Test 2)
2. Force stop app
3. Cold start app again
4. Check initialization logs

### Expected Logs:
```
[ChatService] Registering 1 custom template(s)...
[ChatService]   ✓ Registered: test-mistral
[ChatService] ✓ Custom template registration complete
```

### Verify:
- [ ] Template appears in dropdown after restart
- [ ] Registration logged on startup
- [ ] Can still use template (repeat Test 3)

### Result:
- [ ] ✅ Pass - Template persisted and re-registered
- [ ] ❌ Fail - Template lost or not registered

---

## Test 5: Delete Custom Template ✅

### Steps:
1. Ensure custom template exists (Test 2)
2. Delete template (via UI or programmatic):
   ```dart
   await chatService.removeCustomTemplate('test-mistral');
   ```
3. Check logs

### Expected Logs:
```
[ChatService] ✓ Custom template "test-mistral" removed and unregistered
[ChatTemplateManager] Unregistered custom template: test-mistral
```

### Verify:
- [ ] Template removed from dropdown
- [ ] Unregistration logged
- [ ] Template no longer usable

### Result:
- [ ] ✅ Pass - Template deleted and unregistered
- [ ] ❌ Fail - Template still present or error

---

## Test 6: Multiple Custom Templates ✅

### Steps:
1. Create 3 custom templates:
   ```dart
   await chatService.addCustomTemplate('template-1', '<s>{user}</s>');
   await chatService.addCustomTemplate('template-2', '{user}|{assistant}');
   await chatService.addCustomTemplate('template-3', '### {user}\n### {assistant}');
   ```
2. Verify all appear in dropdown
3. Restart app
4. Check all re-registered

### Expected Logs:
```
[ChatService] Registering 3 custom template(s)...
[ChatService]   ✓ Registered: template-1
[ChatService]   ✓ Registered: template-2
[ChatService]   ✓ Registered: template-3
```

### Result:
- [ ] ✅ Pass - All templates work
- [ ] ❌ Fail - Some templates missing

---

## Test 7: Override Built-in Template ⚠️

### Steps:
1. Create custom template with built-in name:
   ```dart
   await chatService.addCustomTemplate('chatml', 'CUSTOM: {user}');
   ```
2. Check logs for warning
3. Use the template

### Expected Logs:
```
[ChatTemplateManager] Registering custom template 'chatml' that overrides built-in template
```

### Verify:
- [ ] Warning logged
- [ ] Custom template takes priority
- [ ] Original built-in still works after deletion

### Result:
- [ ] ✅ Pass - Override works with warning
- [ ] ❌ Fail - Error or no warning

---

## Test 8: Error Handling ✅

### Test 8a: Empty Name
```dart
await chatService.addCustomTemplate('', 'content');
```
- [ ] Handled gracefully (no crash)

### Test 8b: Empty Content
```dart
await chatService.addCustomTemplate('test', '');
```
- [ ] Handled gracefully (no crash)

### Test 8c: Unregister Non-existent
```dart
await chatService.removeCustomTemplate('non-existent');
```
- [ ] Handled gracefully (no crash)

### Result:
- [ ] ✅ Pass - All errors handled
- [ ] ❌ Fail - App crashed

---

## Test 9: Built-in Templates Still Work ✅

### Steps:
1. Don't create any custom templates
2. Use built-in template (e.g., "llama3")
3. Verify it works

### Expected Logs:
```
[ChatTemplateManager] Using template: llama3 for formatting X messages
```

### Result:
- [ ] ✅ Pass - Built-in templates unaffected
- [ ] ❌ Fail - Built-in templates broken

---

## Test 10: getSupportedTemplates() ✅

### Steps:
1. Get supported templates:
   ```dart
   final templates = await controller.getSupportedTemplates();
   print('Supported: $templates');
   ```
2. Create custom template
3. Get templates again
4. Verify custom template in list

### Expected Output:
```
Before: [chatml, llama2, llama3, mistral, ...]
After:  [chatml, llama2, llama3, mistral, ..., my-template]
```

### Result:
- [ ] ✅ Pass - Custom templates appear in list
- [ ] ❌ Fail - Custom templates not listed

---

## Integration Test (End-to-End) 🎯

### Full Workflow:
1. [ ] Start app (cold start)
2. [ ] Create custom template "my-template"
3. [ ] Select "my-template" in settings
4. [ ] Load model
5. [ ] Send message "Hello"
6. [ ] Verify custom template used in logs
7. [ ] Restart app
8. [ ] Verify template persisted
9. [ ] Send another message
10. [ ] Verify template still used
11. [ ] Delete template
12. [ ] Verify template removed

### Expected Result:
- [ ] ✅ All steps pass - Full workflow works!
- [ ] ❌ Any step fails - Debug that step

---

## Performance Test ⚡

### Steps:
1. Create 10 custom templates
2. Measure startup time
3. Send 100 messages
4. Check for performance degradation

### Expected:
- [ ] Startup: < 1 second overhead
- [ ] Per message: < 1ms overhead
- [ ] Memory: < 1MB for 10 templates

### Result:
- [ ] ✅ Pass - No performance impact
- [ ] ❌ Fail - Noticeable slowdown

---

## Thread Safety Test 🔒

### Steps:
1. Register templates from multiple isolates:
   ```dart
   await Future.wait([
     chatService.addCustomTemplate('t1', 'content1'),
     chatService.addCustomTemplate('t2', 'content2'),
     chatService.addCustomTemplate('t3', 'content3'),
   ]);
   ```
2. Check for race conditions

### Result:
- [ ] ✅ Pass - All templates registered
- [ ] ❌ Fail - Missing templates or crash

---

## Summary

### Core Functionality (MUST PASS)
- [ ] Test 1: Initialization
- [ ] Test 2: Create template
- [ ] Test 3: Use template
- [ ] Test 4: Persistence
- [ ] Test 5: Delete template

### Advanced Features (SHOULD PASS)
- [ ] Test 6: Multiple templates
- [ ] Test 7: Override built-in
- [ ] Test 8: Error handling
- [ ] Test 9: Built-in templates
- [ ] Test 10: getSupportedTemplates()

### Quality (NICE TO HAVE)
- [ ] Integration test
- [ ] Performance test
- [ ] Thread safety test

---

## Debugging Tips

### If templates don't register:
1. Check `_registerCustomTemplates()` is called in `initialize()`
2. Verify `_llama` is not null
3. Check SharedPreferences has templates saved
4. Enable verbose logging

### If templates don't persist:
1. Check SharedPreferences is saving correctly
2. Verify `_registerCustomTemplates()` runs on startup
3. Check for exceptions in logs

### If wrong template is used:
1. Verify `chatTemplate` setting is correct
2. Check `ChatTemplateManager.getTemplate()` returns custom template
3. Verify custom templates checked before built-in
4. Check for auto-detection override

---

## Success Criteria ✅

**Minimum to Pass**:
- Core functionality tests (1-5) all pass
- No crashes or exceptions
- Templates persist across restarts

**Production Ready**:
- All tests pass
- Performance acceptable
- Error handling works

---

**Test Date**: _____________  
**Tested By**: _____________  
**Result**: [ ] ✅ Pass  [ ] ❌ Fail  [ ] ⚠️ Partial

**Notes**:
_____________________________________________________________
_____________________________________________________________
_____________________________________________________________
