# AI Mentor System Documentation

## Overview
The AI Mentor System automatically provides educational hints and guidance for unanswered student questions. It uses intelligent question-type detection to generate contextual learning hints rather than direct answers.

## Features

### 1. **Automatic Hint Generation**
- **Trigger**: Posts with 0 comments that are 2+ hours old
- **Detection**: Automatic check when loading post details
- **Response**: AI Mentor generates a helpful hint silently in the background

### 2. **Question Type Detection**
The AI Mentor analyzes questions and provides tailored hints based on 6 types:

#### **How-to Questions**
- **Keywords**: "how to", "how can", "how do I"
- **Hint Strategy**: Step-by-step breakdown guidance
- **Example**: "💡 Great question! Try breaking this down into smaller steps. What's the very first action you need to take?"

#### **Why Questions**
- **Keywords**: "why does", "why is", "why can't"
- **Hint Strategy**: Understanding underlying principles
- **Example**: "🤔 Good question! Have you tried searching for similar examples in the documentation?"

#### **What Questions**
- **Keywords**: "what is", "what are", "what does"
- **Hint Strategy**: Definition and context exploration
- **Example**: "✨ Interesting! Before diving into the solution, have you checked if there are any built-in methods that might help?"

#### **Error/Bug Questions**
- **Keywords**: "error", "bug", "issue", "problem", "not working"
- **Hint Strategy**: Debugging techniques
- **Example**: "🔍 When debugging, start by checking: 1) Console logs, 2) Error messages, 3) Variable values. What do you see?"

#### **Concept Questions**
- **Keywords**: "understand", "concept", "explain", "learn"
- **Hint Strategy**: Learning methodology
- **Example**: "📚 To understand this better, try: 1) Reading the official docs, 2) Looking at code examples, 3) Experimenting with small test cases."

#### **Generic Questions**
- **Default**: When no specific pattern matches
- **Hint Strategy**: Systematic problem-solving
- **Example**: "💭 Have you tried: 1) Breaking down the problem, 2) Searching for similar issues, 3) Checking the documentation?"

### 3. **Manual Hint Generation**
- **Button**: "AI Mentor Hint" button appears when there are no comments
- **Location**: Comments section header (replaces sort button)
- **Design**: Orange/amber gradient with lightbulb icon
- **Loading State**: Shows "Generating..." with spinner

### 4. **Regenerate Hints**
- **Button**: "Generate more hints ✨" button on AI Mentor comments
- **Function**: Creates alternative hint variations
- **Purpose**: Provides different perspectives if first hint wasn't helpful

### 5. **Special UI Styling**

#### **Avatar**
- Icon: 💡 Lightbulb (instead of person icon)
- Background: Orange gradient (#FF9800)
- Color: White icon

#### **Name Badge**
- Name: "AI Mentor" (special display for userId = -1)
- Badge: Small "AI" tag with orange gradient
- Color: Dark orange text (#E65100)

#### **Comment Card**
- Background: Amber gradient (#FFF3E0 → #FFE0B2)
- Border: 2px orange (#FF9800)
- Shadow: Orange glow effect
- Text: Dark gray (#424242)

#### **Buttons**
- Regenerate: Orange-themed with sparkle icon (✨)
- No vote buttons (upvote/downvote hidden)
- No reply button (can't reply to AI Mentor)
- No edit/delete menu (system comment)

### 6. **Resource Suggestions**
The AI Mentor can suggest relevant learning resources based on keywords:

- **Flutter/Dart**: Flutter docs, DartPad, widget catalog
- **Algorithms**: Algorithm visualizers, complexity guides
- **JavaScript**: MDN Web Docs, JavaScript.info
- **Python**: Python.org tutorials, Real Python
- **Git**: Git documentation, GitHub guides
- **UI/UX**: Material Design guidelines

## Implementation Details

### Service Layer
**File**: `lib/services/ai_mentor_service.dart` (330+ lines)

```dart
class AIMentorService {
  static const int aiMentorUserId = -1; // Special system user ID
  
  // Check if post needs mentor help
  static bool needsMentorHelp({
    required int commentCount,
    required String postDate,
  });
  
  // Generate contextual hint
  static Future<String> generateHint({
    required String postTitle,
    required String postContent,
    bool regenerate = false,
  });
  
  // Suggest learning resources
  static List<Map<String, String>> suggestResources(String content);
}
```

### Database Integration
- **User ID**: AI Mentor uses special ID `-1` (system user)
- **Comment Storage**: Stored like regular comments
- **No Rating**: AI Mentor comments don't get quality ratings

### UI Integration
**File**: `lib/views/screens/postulation/post_details_screen.dart`

**State Variables**:
```dart
bool _loadingMentorHint = false;
bool _mentorHintGenerated = false;
```

**Methods**:
```dart
// Generate AI Mentor hint
Future<void> _generateAIMentorHint({bool regenerate = false});

// Check if mentor help is needed
void _checkForMentorHelp();

// Special user name handling
Future<String> _getUserName(int userId); // Returns "AI Mentor" for -1
```

## Configuration

### Timing Thresholds
```dart
// In AIMentorService.needsMentorHelp()
final hoursSincePost = DateTime.now().difference(postDateTime).inHours;
return commentCount == 0 && hoursSincePost >= 2; // 2 hours
```

### Gemini API Integration
To enable real AI-powered hints (instead of mock):

1. **Get API Key**: Obtain Gemini API key from Google AI Studio
2. **Add to Service**: Update `_generateWithGemini()` in `ai_mentor_service.dart`
3. **Set Key**: Replace `'YOUR_GEMINI_API_KEY_HERE'`

```dart
final response = await http.post(
  Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=YOUR_KEY'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({...}),
);
```

## User Experience Flow

### Scenario 1: New Post with No Comments
1. User posts a question
2. No one responds for 2+ hours
3. AI Mentor automatically generates a hint
4. Hint appears in comments with special orange styling
5. User can click "Generate more hints" for alternatives

### Scenario 2: Manual Hint Request
1. User creates a post
2. User immediately sees "AI Mentor Hint" button
3. User clicks button to get instant guidance
4. Hint is generated and displayed with orange theme
5. User can regenerate for different perspective

### Scenario 3: Regenerate Hints
1. User sees AI Mentor hint
2. User wants a different approach
3. User clicks "Generate more hints ✨"
4. New hint is generated with variation
5. Different strategy or perspective is provided

## Best Practices

### For Students
- **Read Hints Carefully**: Hints guide you to solve, not provide solutions
- **Try Suggestions**: Follow the hint's guidance before asking again
- **Regenerate if Needed**: Different hints offer different perspectives
- **Check Resources**: Click suggested resource links for deeper learning

### For Developers
- **Mock Testing**: Test with mock hints before enabling Gemini API
- **Monitor Costs**: Gemini API calls cost money, monitor usage
- **Hint Quality**: Review generated hints for educational value
- **Update Strategies**: Add new question types as patterns emerge

## Future Enhancements

### Planned Features
1. **Resource Links**: Clickable chips with documentation links
2. **Hint History**: Track which hints were most helpful
3. **Learning Path**: Sequential hints that build on each other
4. **Code Snippets**: Include small code examples in hints
5. **Related Posts**: Suggest similar solved questions

### Advanced Features
1. **Multi-language**: Hints in user's preferred language
2. **Difficulty Levels**: Adjust hint complexity based on user level
3. **Feedback System**: Rate hint helpfulness
4. **Mentor Analytics**: Track effectiveness of different hint types
5. **Custom Prompts**: Allow teachers to define hint templates

## Troubleshooting

### Hints Not Appearing
- **Check Time**: Post must be 2+ hours old for auto-hints
- **Check Comments**: Auto-hints only for 0-comment posts
- **Check State**: `_mentorHintGenerated` flag may be preventing duplicates

### Button Not Showing
- **Check Comments**: Button only shows when `parentComments.isEmpty`
- **Check Flag**: Button hidden if `_mentorHintGenerated == true`

### API Errors
- **Check Key**: Verify Gemini API key is valid
- **Check Network**: Ensure device has internet connection
- **Check Quota**: Verify API quota hasn't been exceeded
- **Fallback**: Mock hints always work as fallback

## Code Examples

### Using AI Mentor Service
```dart
// Check if help is needed
final needsHelp = AIMentorService.needsMentorHelp(
  commentCount: 0,
  postDate: post.date,
);

// Generate hint
final hint = await AIMentorService.generateHint(
  postTitle: post.title,
  postContent: post.description,
  regenerate: false,
);

// Get resources
final resources = AIMentorService.suggestResources(post.description);
```

### Detecting AI Mentor Comments
```dart
// In UI components
final isAIMentor = comment.userId == AIMentorService.aiMentorUserId;

if (isAIMentor) {
  // Apply special styling
  // Hide vote/reply buttons
  // Show regenerate button
}
```

## Color Scheme
- **Primary Orange**: `#FF9800`
- **Dark Orange**: `#FF6F00` / `#E65100`
- **Light Amber**: `#FFF3E0`
- **Medium Amber**: `#FFE0B2`

## Icons
- **Mentor Avatar**: `Icons.lightbulb` (💡)
- **Regenerate**: `Icons.auto_awesome` (✨)
- **Hint Button**: `Icons.lightbulb_outline`

---

**Version**: 1.0  
**Last Updated**: 2024  
**Status**: ✅ Fully Implemented
