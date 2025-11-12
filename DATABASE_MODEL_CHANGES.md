# Database and Model Changes - Migration Summary

## Overview
This document summarizes the changes made to transition from the old schema (using `authorName`, `likes`, `dislikes`) to the new schema (using `userId` and `reactions` table).

---

## Database Schema Changes

### Posts Table
**Changed:**
- ❌ Removed: `authorName` (TEXT) 
- ✅ Added: `userId` (INTEGER NOT NULL) - Foreign key to users table

### Comments Table
**Changed:**
- ❌ Removed: `author` (TEXT)
- ❌ Removed: `likes` (INTEGER)
- ❌ Removed: `dislikes` (INTEGER)
- ✅ Added: `userId` (INTEGER NOT NULL) - Foreign key to users table

### Reactions Table
**New table added:**
```sql
CREATE TABLE reactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  targetType TEXT NOT NULL,     -- 'post' or 'comment'
  targetId INTEGER NOT NULL,    -- post.id or comment.id
  userId INTEGER NOT NULL,      -- user who reacted
  reactionType TEXT NOT NULL,   -- 'like', 'love', 'care', 'haha', 'wow', 'sad', 'angry'
  UNIQUE (targetType, targetId, userId)  -- one reaction per user per target
)
```

---

## Model Changes

### Post Model (`lib/models/postulation_model.dart`)
```dart
class Post {
  final int? id;
  final String title;
  final String description;
  final String? imagePath;
  final int userId;           // ✅ Changed from String authorName
  final DateTime date;
  final String tags;
  bool isFavorite;
}
```

### Comment Model (`lib/models/comment_model.dart`)
```dart
class Comment {
  int? id;
  int postId;
  int? parentCommentId;
  int userId;               // ✅ Changed from String author
  String content;
  String date;
  // ❌ Removed: int likes
  // ❌ Removed: int dislikes
}
```

### Reaction Model (`lib/models/reaction_model.dart`)
```dart
class Reaction {
  int? id;
  String targetType;     // 'post' or 'comment'
  int targetId;          // ID of the post or comment
  int userId;            // ID of the user who reacted
  String reactionType;   // 'like', 'love', 'care', 'haha', 'wow', 'sad', 'angry'
}
```

---

## Database Helper Changes

### Added Methods (reactions):
- ✅ `addReaction()` - Add or update a reaction
- ✅ `getReactionsByTarget()` - Get all reactions for a post/comment
- ✅ `getUserReaction()` - Get a specific user's reaction
- ✅ `deleteReaction()` - Remove a reaction
- ✅ `getReactionCounts()` - Get counts grouped by reaction type
- ✅ `toggleReaction()` - Toggle reaction (add/remove/change)

### Removed Methods:
- ❌ `likeComment()` - Replaced by reaction system
- ❌ `dislikeComment()` - Replaced by reaction system

---

## Provider Changes

### CommentsProvider (`lib/providers/comment_provider.dart`)

**Added:**
- ✅ `Map<int, List<Reaction>> _commentReactions` - Store reactions
- ✅ `Map<int, Map<String, int>> _reactionCounts` - Store reaction counts
- ✅ `getCommentReactions(int commentId)` - Get reactions for a comment
- ✅ `getReactionCounts(int commentId)` - Get reaction counts
- ✅ `toggleCommentReaction()` - Toggle reaction on a comment
- ✅ `getUserCommentReaction()` - Get user's reaction for a comment

**Removed:**
- ❌ `likeComment()` - Replaced by `toggleCommentReaction()`
- ❌ `dislikeComment()` - Replaced by `toggleCommentReaction()`

---

## Screen Changes

### 1. `post_details_screen.dart`
**Changes:**
- ✅ Uses `userId` instead of `authorName`
- ✅ Loads user name from database using `getUserById()`
- ✅ Displays reactions instead of likes/dislikes
- ✅ Shows reaction emojis (👍, ❤️, 😂, etc.)
- ✅ Allows users to react to comments
- ✅ Gets current user from `AuthProvider`

**New Features:**
- User name lookup and caching
- Reaction system with emoji display
- Real-time reaction counts

### 2. `create_post_screen.dart`
**Changes:**
- ✅ Removed `currentUser` parameter (String)
- ✅ Uses `AuthProvider` to get current user ID
- ✅ Validates user authentication before submission
- ✅ Creates post with `userId` (int) instead of `authorName` (String)

### 3. `posts_list_screen.dart`
**Changes:**
- ✅ Removed `currentUser` parameter
- ✅ Updated `CreatePostScreen` navigation (no currentUser param)

### 4. `main.dart`
**Changes:**
- ✅ Updated route definitions to remove `currentUser` parameters
- ✅ Both `PostsListScreen` and `CreatePostScreen` are now const

---

## Migration Steps for Existing Data

If you have existing data in the database, you may need to:

1. **Clear the database** (easiest for development):
   - Delete the database file and let it recreate with the new schema

2. **Manual migration** (if you need to preserve data):
   ```sql
   -- For posts: Map authorName to userId
   -- You would need to create a mapping table first
   
   -- For comments: Remove likes/dislikes data
   -- and migrate to reactions table
   ```

---

## Testing Checklist

- [ ] Create a new post (should use userId)
- [ ] View post details (should show author name from user table)
- [ ] Add a comment (should use userId)
- [ ] React to a comment (should create reaction in reactions table)
- [ ] Toggle reaction (should update/remove reaction)
- [ ] View reaction counts (should show correct totals)
- [ ] Multiple users reacting (should track per user)

---

## Breaking Changes

⚠️ **Important:** These changes are **breaking** for existing code that:
1. References `post.authorName` - Now use `post.userId` and lookup user
2. References `comment.author` - Now use `comment.userId` and lookup user
3. Uses `comment.likes` or `comment.dislikes` - Now use reactions system
4. Calls `likeComment()` or `dislikeComment()` - Now use `toggleCommentReaction()`

---

## Reaction Types Supported

The system now supports these reaction types:
- `like` 👍
- `love` ❤️
- `care` 🤗
- `haha` 😂
- `wow` 😮
- `sad` 😢
- `angry` 😠

---

## Benefits of New System

1. **Better Data Integrity**: Using foreign keys (userId) instead of text (authorName)
2. **Richer Reactions**: Multiple reaction types instead of just like/dislike
3. **One Reaction Per User**: Enforced at database level with UNIQUE constraint
4. **Flexible**: Can easily add more reaction types in the future
5. **Scalable**: Reactions are normalized in separate table

---

## Next Steps

Consider adding:
- [ ] Post reactions (currently only comments have reactions)
- [ ] Reaction picker UI (to select different reaction types)
- [ ] Notification system for reactions
- [ ] Analytics for popular reaction types
- [ ] Reply to comments (using parentCommentId)

---

Generated: October 19, 2025
