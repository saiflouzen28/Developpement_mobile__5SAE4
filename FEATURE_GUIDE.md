# Quick Feature Guide - Post Details Screen

## 🎯 How to Use New Features

### 1. Upvote a Comment
```
👤 John Doe • 2h ago
    "Great post! Very informative."
    
    [⬆️ 15] [⬇️ 2] [+13] [💬 Reply 3]
     ^^^^
     Click here to upvote
```

- Click the **⬆️ Upvote** button (turns green when active)
- Click again to remove your upvote
- See live count update

### 2. Downvote a Comment
```
👤 Jane Smith • 5h ago
    "I disagree with this point."
    
    [⬆️ 5] [⬇️ 8] [-3] [💬 Reply 1]
            ^^^^
            Click here to downvote
```

- Click the **⬇️ Downvote** button (turns red when active)
- Click again to remove your downvote
- Net score shown in badge: **+13** (positive) or **-3** (negative)

### 3. Reply to a Comment
```
👤 Mike Johnson • 1d ago
    "This is exactly what I was looking for!"
    
    [⬆️ 23] [⬇️ 1] [+22] [💬 Reply 5]
                                ^^^^
                                Click here to reply
```

**Steps:**
1. Click the **💬 Reply** button
2. Reply input field appears below the comment
3. Type your reply
4. Click **Send** button
5. Reply appears indented under parent comment

### 4. View Nested Replies
```
👤 Sarah Lee • 3h ago
    "Amazing content!"
    [⬆️ 10] [⬇️ 0] [+10] [💬 Reply 2]
    
    ↳ 👤 Tom Wilson • 2h ago (Reply)
       "I agree completely!"
       [⬆️ 3] [⬇️ 0] [+3]
       
    ↳ 👤 Emma Brown • 1h ago (Reply)
       "Thanks for sharing!"
       [⬆️ 5] [⬇️ 1] [+4]
```

- Replies are **indented to the right**
- Have a **colored border** to distinguish them
- Show parent-child relationship clearly

### 5. Delete Your Own Comment
```
👤 You • 30m ago                    [⋮]
    "My comment here"                ^^^
    [⬆️ 2] [⬇️ 0] [+2] [💬 Reply]   Click three dots
```

**Steps:**
1. Find your comment (shows "You" as author)
2. Click the **three-dot menu** (⋮)
3. Select **"Delete"**
4. Comment is removed instantly

---

## 🎨 Visual Elements

### Comment Card Anatomy
```
┌─────────────────────────────────────────────┐
│ 👤 Username • Time ago              [⋮]     │
│                                              │
│ Comment text content here...                │
│ Can be multiple lines.                      │
│                                              │
│ [⬆️ 15] [⬇️ 2]          [+13] [💬 Reply 3] │
│   └─Upvote  └─Downvote   └─Score └─Reply   │
└─────────────────────────────────────────────┘
```

### Reply Card (Indented)
```
        ┌─────────────────────────────────────┐
        │ 👤 Username • Time ago        [⋮]   │
        │                                      │
        │ Reply text content...               │
        │                                      │
        │ [⬆️ 5] [⬇️ 1]          [+4]         │
        └─────────────────────────────────────┘
```

### Active States

**Upvoted:**
```
[⬆️ 15]  ← Green background, green text, filled icon
```

**Downvoted:**
```
[⬇️ 2]   ← Red background, red text, filled icon
```

**Neutral:**
```
[⬆️ 15]  ← Grey background, grey text, outline icon
```

---

## 🔢 Vote Score Badge

### Positive Score
```
[+13]  ← Green badge (more upvotes than downvotes)
```

### Negative Score
```
[-3]   ← Red badge (more downvotes than upvotes)
```

### Zero Score
```
(hidden)  ← No badge shown when votes are equal
```

---

## 📝 Comment Input Areas

### Main Comment Input (Bottom)
```
┌──────────────────────────────────────────────────┐
│ 👤 [Write a comment...                    ] [📤] │
└──────────────────────────────────────────────────┘
```

### Reply Input (Inline)
```
Parent Comment
[⬆️ 10] [⬇️ 0] [+10] [💬 Reply] ← Click here

└─ [Write a reply...                        ] [📤]
   ↑ Reply input appears here
```

---

## 🎭 Animations

All comments use **FadeInUp** animation:
- Smooth entrance from bottom
- Staggered delays for each comment
- 400ms duration
- 50ms delay between items

---

## 🌈 Color Indicators

| Element | Color | Meaning |
|---------|-------|---------|
| 🟢 Green | Upvote | Positive reaction |
| 🔴 Red | Downvote | Negative reaction |
| 🟣 Purple | Primary | App theme color |
| ⚫ Grey | Neutral | No reaction |
| 🟦 Blue | Reply Border | Nested comment |

---

## ⚡ Quick Tips

### For Users
1. **Vote honestly** - Your votes help surface quality comments
2. **Reply thoughtfully** - Nested replies keep discussions organized
3. **Edit vs Delete** - Currently only delete is available
4. **Score = Upvotes - Downvotes** - Net voting score

### For Developers
1. **Vote Counts Cached** - Stored in provider for performance
2. **User Names Cached** - Prevents repeated database calls
3. **Separate Controllers** - Each reply has its own text controller
4. **Async Loading** - FutureBuilder handles user data loading

---

## 🐛 Known Behavior

### Expected Behavior
- ✅ Clicking upvote when already upvoted **removes** the upvote
- ✅ Clicking downvote when already downvoted **removes** the downvote
- ✅ Can switch from upvote to downvote (and vice versa)
- ✅ Only one reaction per user per comment
- ✅ Replies inherit post ID from parent

### UI Feedback
- Vote buttons change color when active
- Net score updates in real-time
- Reply count shows on parent comment
- Time updates on page refresh

---

## 📱 Screen Layout

```
┌─────────────────────────────────────────┐
│     [←]                                 │  App Bar
│  ┌─────────────────────────────────┐   │
│  │                                 │   │
│  │      Post Image/Header         │   │  Expandable
│  │                                 │   │  300px
│  └─────────────────────────────────┘   │
├─────────────────────────────────────────┤
│  Title (28px bold)                      │
│  👤 Author • Time ago                   │  Content
│  #tags                                  │  Card
│  Description text...                    │
│  ─────────────────────────────          │
│  💬 Comments (12)                       │
├─────────────────────────────────────────┤
│  Comment 1                              │
│    ↳ Reply 1                            │  Scrollable
│    ↳ Reply 2                            │  Comments
│  Comment 2                              │
│  Comment 3                              │
│    ↳ Reply 1                            │
│    ...                                  │
├─────────────────────────────────────────┤
│  👤 [Write comment...      ] [📤]       │  Fixed
└─────────────────────────────────────────┘  Bottom
```

---

## 🎯 User Flow Examples

### Flow 1: Upvoting a Comment
```
User sees comment
    ↓
Clicks ⬆️ button
    ↓
Button turns green
    ↓
Count increases (+1)
    ↓
Net score updates
```

### Flow 2: Replying to Comment
```
User reads comment
    ↓
Clicks 💬 Reply
    ↓
Input field appears
    ↓
User types reply
    ↓
Clicks Send 📤
    ↓
Reply appears indented
    ↓
Parent shows reply count
```

### Flow 3: Changing Vote
```
User has upvoted (+1)
    ↓
Clicks ⬇️ downvote
    ↓
Upvote removed
    ↓
Downvote added
    ↓
Net score changes (-2)
```

---

## 🎉 Enjoy Your New Features!

The comment system now supports:
- ✅ Reddit-style voting
- ✅ Twitter-style nested replies  
- ✅ Modern Material Design 3
- ✅ Smooth animations
- ✅ Real-time updates

Happy commenting! 💬
