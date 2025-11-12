# 🧪 AI Tutor Testing Guide

## Quick Test Checklist

### 1. Setup (REQUIRED FIRST)
Before testing, you **MUST** configure the Gemini API key:

1. Get a FREE API key from: https://makersuite.google.com/app/apikey
2. Open `lib/services/ai_tutor_service.dart`
3. Replace line 8:
   ```dart
   static const String _geminiApiKey = 'YOUR_GOOGLE_GEMINI_API_KEY';
   ```
   With your actual key:
   ```dart
   static const String _geminiApiKey = 'AIzaSyC...';
   ```

### 2. Access AI Tutor

**Method 1: From Post Details**
1. Open any post
2. Click the 🤖 emoji button in the top-right corner
3. Chat interface opens with post context

**Method 2: From Comment Area**
1. Scroll to comment section
2. Click the 🤖 button next to the mic button
3. Chat interface opens

### 3. Test Scenarios

#### Test 1: Basic Question (No API Key - Fallback Mode)
**Setup**: Don't configure API key (leave default)
**Steps**:
1. Open AI Tutor
2. Ask: "I don't understand recursion"
3. **Expected**: Instant fallback response with detailed explanation
4. **Verify**: Response appears in <100ms, includes examples

**✅ Success Criteria**:
- Response is immediate
- Contains detailed explanation
- Includes code example
- Shows "fallback" model tag

---

#### Test 2: Real AI Response (Requires API Key)
**Setup**: Configure Gemini API key
**Steps**:
1. Open AI Tutor
2. Ask: "Can you explain recursion in simple terms?"
3. **Expected**: Wait 2-5 seconds, get Gemini-generated response
4. **Verify**: Response is contextual and well-formatted

**✅ Success Criteria**:
- Loading animation appears (3 pulsing dots)
- Response arrives in 2-5 seconds
- Answer is coherent and educational
- Topics tags appear below response (e.g., #recursion, #algorithm)
- Console shows: "🤖 Using AssemblyAI for transcription..."

---

#### Test 3: Context Awareness
**Setup**: Open a post about "Flutter Widgets"
**Steps**:
1. Click 🤖 button
2. Notice welcome message mentions the post title
3. Ask: "Can you explain this topic?"
4. **Expected**: AI references the post content in its answer

**✅ Success Criteria**:
- Welcome message says: "I see you're viewing: [Post Title]"
- AI's answer relates to the post content
- Response mentions Flutter/widgets

---

#### Test 4: Conversation History
**Steps**:
1. Ask: "What is a Flutter StatelessWidget?"
2. Wait for response
3. Ask follow-up: "What about StatefulWidget?"
4. **Expected**: AI remembers previous question context

**✅ Success Criteria**:
- Second answer references first question
- Compares StatelessWidget vs StatefulWidget
- Shows continuity in conversation

---

#### Test 5: Multilingual Support
**Steps**:
1. Open AI Tutor
2. Click language icon (🌐) in top-right
3. Select "Français 🇫🇷"
4. Ask: "Comment fonctionne la récursion?"
5. **Expected**: Response in French

**✅ Success Criteria**:
- Language dropdown shows all 5 languages
- Selected language has checkmark
- Fallback responses are in selected language
- (If API key set) Gemini responds in French

---

#### Test 6: Database Persistence
**Steps**:
1. Ask several questions (3-5)
2. Close AI Tutor
3. Reopen AI Tutor (same post)
4. Check if conversation history is maintained

**Note**: Currently, conversation is session-only. Database saves for statistics but doesn't reload history yet.

**✅ Success Criteria**:
- Questions are saved to database
- Console shows: "🤖 AI Tutor conversation saved with ID: X"
- Can query database to see saved conversations

---

#### Test 7: Topic Extraction
**Steps**:
1. Ask: "How do I use async/await in Flutter with HTTP requests?"
2. **Expected**: Multiple topic tags appear

**✅ Success Criteria**:
- Response includes topic chips below text
- Topics like: #async, #flutter, #http, #api
- Topics are clickable (purple chips)

---

#### Test 8: Error Handling
**Steps**:
1. Disconnect from internet (if testing real API)
2. Ask a question
3. **Expected**: Fallback response or friendly error message

**✅ Success Criteria**:
- No app crash
- User sees meaningful error message
- System gracefully falls back
- Console shows: "🔄 Using fallback response system"

---

#### Test 9: Rate Limit (Advanced)
**Setup**: Requires API key configured
**Steps**:
1. Ask 60+ questions rapidly (spam click send)
2. **Expected**: After 60 requests, see rate limit message

**✅ Success Criteria**:
- First 60 succeed
- 61st shows: "Too many requests. Please wait a moment..."
- After 1 minute, requests work again

---

#### Test 10: About Dialog
**Steps**:
1. Open AI Tutor
2. Click info icon (ℹ️) in top-right
3. Review information

**✅ Success Criteria**:
- Shows "Powered by Google Gemini AI"
- Lists features (languages, response time, etc.)
- Shows tips for best results
- Mentions free tier limit

---

### 4. Console Log Verification

**Expected Console Output** (with API key configured):
```
🤖 AI Tutor: Processing question in en...
📤 Sending request to Gemini API...
📥 Received response: 200
✅ AI response generated successfully
🤖 AI Tutor conversation saved with ID: 1
```

**Expected Console Output** (without API key):
```
🤖 AI Tutor: Processing question in en...
⚠️ Gemini API key not configured, using fallback
🔄 Using fallback response system
🤖 AI Tutor conversation saved with ID: 1
```

---

### 5. Database Verification

**Check saved conversations**:
```sql
-- In Android Studio Database Inspector or ADB
SELECT * FROM ai_tutor_conversations ORDER BY createdAt DESC LIMIT 10;
```

**Expected Columns**:
- `id`: Auto-increment ID
- `userId`: Current user ID
- `postId`: Post ID (if opened from post)
- `question`: User's question text
- `answer`: AI's response text
- `topics`: Comma-separated topics (e.g., "recursion,algorithm")
- `language`: Language code (e.g., "en")
- `createdAt`: ISO timestamp

---

### 6. UI/UX Testing

**Visual Elements to Verify**:
- ✅ Gradient background (blue to purple)
- ✅ User messages: Right-aligned, gradient bubble
- ✅ AI messages: Left-aligned, white bubble with 🤖 icon
- ✅ Loading indicator: 3 pulsing dots
- ✅ Topic tags: Purple chips below AI responses
- ✅ Timestamps: "Just now", "2m ago", "1h ago"
- ✅ Send button: Gradient purple/blue circle
- ✅ AI Tutor button: Emoji + gradient background

**Animations**:
- Message bubbles fade in
- Smooth scroll to new messages
- Loading dots pulse continuously
- Language dropdown opens smoothly

---

### 7. Integration Testing

**Test Post Details Integration**:
1. Open any post
2. Verify 🤖 button appears in:
   - AppBar (top-right, after debate mode button)
   - Comment input area (before mic button)
3. Click either button
4. Both open same AI Tutor interface
5. Post context is passed correctly

---

### 8. Common Issues & Solutions

#### Issue: "API Key Not Configured" message
**Solution**: Add your Gemini API key in `ai_tutor_service.dart`

#### Issue: Empty or generic responses
**Cause**: Fallback mode active (no API key)
**Solution**: Configure API key for real AI responses

#### Issue: Slow responses (>10 seconds)
**Cause**: Network latency or API overload
**Solution**: Normal - wait or check internet connection

#### Issue: Topics not appearing
**Cause**: Fallback mode doesn't extract topics
**Solution**: Use real API or check topic extraction logic

#### Issue: Database errors
**Cause**: Database not upgraded to v7
**Solution**: Uninstall and reinstall app, or clear app data

---

### 9. Performance Benchmarks

**Target Metrics**:
- API Response Time: < 5 seconds
- Fallback Response Time: < 100ms
- Database Save Time: < 50ms
- UI Render Time: < 16ms (60 FPS)
- Message Animation: Smooth (no jank)

---

### 10. Sample Test Questions

**Easy (Good for fallback testing)**:
- "I don't understand recursion"
- "What is a loop?"
- "Explain Flutter widgets"
- "How do databases work?"
- "What is async programming?"

**Medium (Good for API testing)**:
- "Can you explain the difference between StatelessWidget and StatefulWidget in Flutter?"
- "How do I handle errors with try-catch in async functions?"
- "What's the best way to manage state in a Flutter app?"

**Complex (Tests conversation history)**:
1. "What is a binary search tree?"
2. "How do I traverse it?"
3. "What's the time complexity?"
4. "Show me a code example in Dart"

**Debugging Questions**:
- "I'm getting a null pointer exception in Flutter, what should I check?"
- "My app crashes when I tap a button, how do I debug?"
- "What does 'RenderFlex overflowed' mean?"

---

## Test Results Template

```
Date: ___________
Tester: ___________
Device: ___________
Flutter Version: ___________

Test 1: Basic Question (Fallback) ..................... [ PASS / FAIL ]
Test 2: Real AI Response .............................. [ PASS / FAIL ]
Test 3: Context Awareness ............................. [ PASS / FAIL ]
Test 4: Conversation History .......................... [ PASS / FAIL ]
Test 5: Multilingual Support .......................... [ PASS / FAIL ]
Test 6: Database Persistence .......................... [ PASS / FAIL ]
Test 7: Topic Extraction .............................. [ PASS / FAIL ]
Test 8: Error Handling ................................ [ PASS / FAIL ]
Test 9: Rate Limit .................................... [ PASS / FAIL ]
Test 10: About Dialog ................................. [ PASS / FAIL ]

Overall Status: [ PASS / FAIL ]
Notes: _______________________________________________________
```

---

## Ready to Test?

1. ✅ Configure API key (or test fallback mode)
2. ✅ Run `flutter run`
3. ✅ Open any post
4. ✅ Click 🤖 button
5. ✅ Ask a question
6. ✅ Verify response appears
7. ✅ Check console logs
8. ✅ Repeat with different scenarios

**Good luck! 🎉**
