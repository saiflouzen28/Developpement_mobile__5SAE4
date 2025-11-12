# 🤖 AI Tutor Assistant Feature

## Overview
The AI Tutor Assistant is an intelligent educational chatbot that helps learners understand concepts, solve problems, and get instant answers to their questions related to course content and posts.

## Features

### 🎯 Core Capabilities
- **Context-Aware Responses**: Understands the post content and provides relevant answers
- **Multilingual Support**: Supports 5+ languages (English, French, Arabic, Spanish, German)
- **Conversation History**: Maintains context across multiple questions
- **Topic Extraction**: Automatically identifies and tags discussed topics
- **Educational Tone**: Provides patient, encouraging, and clear explanations
- **Fallback System**: Works even when API is unavailable with pre-programmed responses

### 💡 Key Features
1. **Instant Access**: Click 🤖 button in post details or comment area
2. **Smart Context**: AI knows what post you're viewing
3. **Topic Tags**: See relevant topics in each response
4. **Language Switching**: Change language mid-conversation
5. **Conversation Saving**: All Q&A pairs saved for later review
6. **Statistics**: Track your learning progress

## Technology Stack

### AI Model
- **Provider**: Google Gemini AI (1.5 Flash)
- **Tier**: Free (60 requests/minute)
- **Endpoint**: `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent`

### Integration Points
- **Service**: `lib/services/ai_tutor_service.dart`
- **Widget**: `lib/views/widgets/ai_tutor_chat_widget.dart`
- **Database**: `ai_tutor_conversations` table (version 7)

## Setup Instructions

### 1. Get Google Gemini API Key (FREE)
1. Visit: https://makersuite.google.com/app/apikey
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the generated key

### 2. Configure the API Key
Open `lib/services/ai_tutor_service.dart` and replace:
```dart
static const String _geminiApiKey = 'YOUR_GOOGLE_GEMINI_API_KEY';
```
With your actual API key:
```dart
static const String _geminiApiKey = 'AIzaSyC...your_actual_key_here';
```

### 3. Run the App
```bash
flutter pub get
flutter run
```

## Usage Guide

### For Students

#### Ask a Question
1. Open any post in the app
2. Click the 🤖 button (top-right or near comment input)
3. Type your question in plain language
4. Wait 2-5 seconds for AI response
5. Ask follow-up questions for clarification

#### Example Questions
- "Can you explain recursion?"
- "I don't understand how loops work"
- "What's the difference between Flutter StatelessWidget and StatefulWidget?"
- "How do I debug this error: [error message]?"
- "Give me an example of async/await in Dart"

#### Tips for Best Results
✅ **Good Questions:**
- "Can you explain how recursion works with a simple example?"
- "What's the difference between const and final in Dart?"
- "I'm getting a null pointer exception, how do I fix it?"

❌ **Avoid:**
- "Help" (too vague)
- "It doesn't work" (no context)
- Very long questions (break them down)

### For Instructors

#### Monitor Usage
Check database for conversation statistics:
```sql
SELECT 
  COUNT(*) as total_questions,
  COUNT(DISTINCT userId) as active_students,
  AVG(LENGTH(question)) as avg_question_length
FROM ai_tutor_conversations;
```

#### Popular Topics
```sql
SELECT topics, COUNT(*) as frequency
FROM ai_tutor_conversations
WHERE topics IS NOT NULL
GROUP BY topics
ORDER BY frequency DESC
LIMIT 10;
```

## API Details

### Request Format
```json
{
  "contents": [
    {
      "parts": [
        {"text": "System instructions + context + question"}
      ]
    }
  ],
  "generationConfig": {
    "temperature": 0.7,
    "topK": 40,
    "topP": 0.95,
    "maxOutputTokens": 1024
  }
}
```

### Response Format
```json
{
  "success": true,
  "response": "AI-generated answer text",
  "topics": ["recursion", "algorithm", "debugging"],
  "language": "en",
  "model": "gemini-1.5-flash",
  "timestamp": "2025-11-08T10:30:00Z"
}
```

## Database Schema

### ai_tutor_conversations Table
```sql
CREATE TABLE ai_tutor_conversations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  userId INTEGER NOT NULL,              -- Who asked
  postId INTEGER,                        -- Which post context
  question TEXT NOT NULL,                -- Student's question
  answer TEXT NOT NULL,                  -- AI's response
  topics TEXT,                           -- Comma-separated topics
  language TEXT DEFAULT 'en',            -- Response language
  createdAt TEXT NOT NULL,               -- Timestamp
  FOREIGN KEY (userId) REFERENCES users(id),
  FOREIGN KEY (postId) REFERENCES posts(id)
);
```

### Database Methods
```dart
// Save conversation
DatabaseHelper.instance.saveAITutorConversation(
  userId: userId,
  postId: postId,
  question: "How does recursion work?",
  answer: "Recursion is when...",
  topics: ["recursion", "algorithm"],
  language: "en",
);

// Get conversation history
final conversations = await DatabaseHelper.instance.getAITutorConversations(
  userId: userId,
  postId: postId,
  limit: 50,
);

// Get statistics
final stats = await DatabaseHelper.instance.getAITutorStats(userId);
print(stats['totalConversations']); // e.g., 25
print(stats['topTopics']); // [{"topic": "flutter", "count": 10}, ...]
```

## Fallback System

If the API is unavailable, the system provides pre-programmed responses for common topics:

### Supported Topics
- **Recursion**: Detailed explanation with examples
- **Loops**: For/while/do-while concepts
- **Flutter/Widgets**: Flutter basics
- **Database/SQL**: Database concepts
- **Async/Await**: Asynchronous programming
- **General**: Default helpful message

### Example Fallback
```dart
Question: "I don't understand recursion"
Fallback Response: 
"📚 Recursion Explained:
Recursion is when a function calls itself...
[Detailed explanation with examples]
💡 Tip: Always ensure you have a base case!"
```

## Multilingual Support

### Supported Languages
| Code | Language | Flag |
|------|----------|------|
| `en` | English | 🇬🇧 |
| `fr` | Français | 🇫🇷 |
| `ar` | العربية | 🇸🇦 |
| `es` | Español | 🇪🇸 |
| `de` | Deutsch | 🇩🇪 |

### How It Works
1. User selects language from dropdown
2. System instructions sent to AI in selected language
3. AI responds in that language
4. Conversation saved with language tag

## UI Components

### Chat Interface
- **Welcome Message**: Context-aware greeting
- **Message Bubbles**: User (right, gradient) vs AI (left, white)
- **Loading Animation**: 3-dot pulsing indicator
- **Topic Tags**: Clickable topic chips below AI responses
- **Timestamps**: Relative time (e.g., "2m ago", "1h ago")
- **Selectable Text**: Users can copy AI responses

### Actions
- **Language Selector**: Top-right dropdown
- **About Dialog**: Info button with API details
- **Input Field**: Auto-expanding text field
- **Send Button**: Gradient purple/blue circle

## Performance

### Response Times
- **API Call**: 1-3 seconds (depends on question complexity)
- **Fallback**: <100ms (instant)
- **Database Save**: <50ms

### Rate Limits
- **Gemini Free Tier**: 60 requests/minute
- **Handling**: Automatic error message if exceeded
- **Recommendation**: Monitor usage, upgrade if needed

## Troubleshooting

### "API Key Not Configured" Message
**Solution**: Add your Gemini API key in `ai_tutor_service.dart`

### Empty Responses
**Cause**: Network issue or API timeout
**Solution**: System automatically uses fallback responses

### "Too Many Requests" Error
**Cause**: Rate limit exceeded (60/min)
**Solution**: Wait 1 minute or upgrade API tier

### Responses in Wrong Language
**Cause**: Language setting not properly passed
**Solution**: Reselect language from dropdown

## Best Practices

### For Students
1. **Be Specific**: Include error messages, code snippets, or exact concepts
2. **Follow Up**: Ask for clarification or examples
3. **Break Down**: Split complex questions into smaller parts
4. **Use Context**: AI knows the post you're viewing, reference it

### For Developers
1. **Monitor API Usage**: Track request count to avoid rate limits
2. **Update Fallbacks**: Add more pre-programmed responses for common topics
3. **Test Languages**: Verify responses in all supported languages
4. **Database Cleanup**: Periodically archive old conversations

## Future Enhancements

### Planned Features
- [ ] **Voice Input**: Speak questions instead of typing
- [ ] **Code Execution**: Test code snippets in-app
- [ ] **Visual Diagrams**: Generate diagrams for complex concepts
- [ ] **Quiz Generation**: Create practice questions from conversations
- [ ] **Peer Comparison**: Compare learning progress with others
- [ ] **Instructor Dashboard**: Analytics on common questions

### Potential Integrations
- OpenAI GPT-4 as alternative model
- Claude AI for longer conversations
- Hugging Face models for offline mode
- Custom fine-tuned models for specific courses

## Cost Analysis

### Free Tier Limits
- **Gemini 1.5 Flash**: 60 requests/min, unlimited daily
- **Cost**: $0/month
- **Suitable For**: Up to ~500 students with moderate usage

### Paid Tier (if needed)
- **Gemini Pro**: Higher rate limits
- **Cost**: Pay-as-you-go pricing
- **When to Upgrade**: >1000 active students

## Security & Privacy

### Data Handling
- ✅ Questions and answers stored locally in SQLite
- ✅ No conversation data sent to third parties (except AI provider)
- ✅ User IDs anonymized in API requests
- ✅ No personal information shared with AI

### API Security
- API key stored in code (for development)
- **Production**: Move to environment variables or secure backend
- **Recommendation**: Use backend proxy to hide API key

## Support

### Getting Help
- Check this documentation first
- Review console logs for errors
- Test with fallback mode (remove API key)
- Contact developer with error details

### Reporting Issues
Include:
1. Error message (screenshot)
2. Question that caused the error
3. Language setting
4. Device/platform information

## Credits

- **AI Provider**: Google Gemini
- **UI Framework**: Flutter
- **Icons**: Material Icons + Emoji
- **Fonts**: Google Fonts (Poppins)
- **Database**: SQLite

## License

This feature is part of the E-Learning Events App and follows the same license terms.

---

**Version**: 1.0.0  
**Last Updated**: November 8, 2025  
**Author**: Development Team  
**Status**: ✅ Production Ready
