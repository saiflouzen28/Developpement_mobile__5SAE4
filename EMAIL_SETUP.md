# 📧 Email Configuration Setup Guide

This guide will help you set up automatic email sending for quiz results using Gmail SMTP.

## 🚀 Quick Setup (Gmail)

### Step 1: Enable 2-Step Verification

1. Go to your Google Account: https://myaccount.google.com/
2. Click on **Security** in the left sidebar
3. Scroll to **"How you sign in to Google"**
4. Click on **2-Step Verification** and turn it ON
5. Follow the prompts to set it up (you'll need your phone)

### Step 2: Generate App Password

1. After enabling 2-Step Verification, go back to **Security**
2. Scroll to **"How you sign in to Google"**
3. Click on **App passwords**
4. Select **Mail** as the app
5. Select **Other (Custom name)** as the device
6. Enter "Quiz App" or any name you want
7. Click **Generate**
8. **COPY the 16-character password** (it looks like: `xxxx xxxx xxxx xxxx`)

### Step 3: Configure the App

1. Open `lib/core/email_config.dart`
2. Replace the placeholder values:

```dart
class EmailConfig {
  static const String senderEmail = 'your-actual-email@gmail.com';  // ← Your Gmail
  static const String senderPassword = 'abcd efgh ijkl mnop';       // ← Your 16-char app password
  
  // ... rest stays the same
}
```

### Step 4: Test

1. Run the app: `flutter run`
2. Complete a quiz
3. Click **"Enregistrer le résultat"**
4. Check your email inbox!

---

## 🔧 Alternative SMTP Providers

### Outlook/Hotmail

In `email_config.dart`, use:
```dart
static const String smtpHost = 'smtp-mail.outlook.com';
static const int smtpPort = 587;
static const String senderEmail = 'your-email@outlook.com';
static const String senderPassword = 'your-password';
```

### Yahoo

In `email_config.dart`, use:
```dart
static const String smtpHost = 'smtp.mail.yahoo.com';
static const int smtpPort = 587;
static const String senderEmail = 'your-email@yahoo.com';
static const String senderPassword = 'your-app-password';
```

(Yahoo also requires app passwords)

### Custom SMTP Server

```dart
static const String smtpHost = 'smtp.yourdomain.com';
static const int smtpPort = 587; // or 465 for SSL
static const String senderEmail = 'noreply@yourdomain.com';
static const String senderPassword = 'your-password';
```

---

## 📋 How It Works

When a user clicks **"Enregistrer le résultat"**:

1. ✅ Quiz result is saved to the database
2. 📧 A beautiful HTML email is sent to the user's email address
3. 📊 Email includes:
   - Score and percentage
   - Total questions
   - Personalized message based on performance
   - Professional formatting

---

## 🎨 Email Template Features

The email includes:
- 🎯 Beautiful gradient header
- 📊 Score statistics with visual cards
- 🏆 Performance-based message (Excellent, Bien, À améliorer)
- 📅 Automatic date stamp
- 💅 Responsive HTML design

---

## ⚠️ Important Security Notes

### ❌ DO NOT:
- Commit real credentials to Git
- Share your app password with anyone
- Use your regular Google password

### ✅ DO:
- Use app passwords (not your main password)
- Keep `email_config.dart` in `.gitignore` for production
- Use environment variables in production
- Rotate passwords regularly

---

## 🐛 Troubleshooting

### Email not sending?

**Check console logs:**
```
Email sent successfully: [...]  ← Success
Error sending email: [...]      ← Failed
```

**Common issues:**

1. **"Authentication failed"**
   - Make sure you're using an APP PASSWORD, not your regular password
   - Verify 2-Step Verification is enabled

2. **"Connection timeout"**
   - Check your internet connection
   - Some networks block SMTP ports (try different WiFi/mobile data)

3. **"Email address not found"**
   - User must have a valid email in their profile
   - Check `authProvider.user?.email`

4. **Email goes to spam**
   - This is normal for automated emails
   - Users should whitelist the sender email

### Test email sending separately:

```dart
// In a test file or button:
await EmailService.sendQuizResultEmail(
  recipientEmail: 'test@example.com',
  userName: 'Test User',
  quizTitle: 'Test Quiz',
  score: 8,
  totalQuestions: 10,
  percentage: 80.0,
);
```

---

## 🔐 Production Recommendations

For production apps:

1. **Use a backend server** to send emails
2. **Store credentials** in environment variables or secret managers
3. **Use a dedicated email service** like:
   - SendGrid (free tier: 100 emails/day)
   - Mailgun
   - AWS SES
   - Firebase Cloud Functions + Nodemailer

---

## 📦 Dependencies Used

```yaml
dependencies:
  mailer: ^6.1.0  # SMTP email sending
```

Already installed in your `pubspec.yaml`!

---

## 📝 Files Modified

1. `lib/core/email_service.dart` - Email sending logic
2. `lib/core/email_config.dart` - Configuration (edit this!)
3. `lib/views/screens/quizze/start_quiz_screen.dart` - Integrated email sending

---

## ✅ That's it!

You're all set! Users will now receive beautiful email reports when they save their quiz results.

**Questions?** Check the console logs or reach out for support!
