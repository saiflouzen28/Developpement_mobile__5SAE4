/// Email Configuration
/// 
/// IMPORTANT: To use Gmail SMTP, follow these steps:
/// 
/// 1. Go to your Google Account: https://myaccount.google.com/
/// 2. Select "Security" from the left menu
/// 3. Enable "2-Step Verification" if not already enabled
/// 4. Scroll down to "App passwords"
/// 5. Generate a new app password for "Mail"
/// 6. Copy the 16-character password (without spaces)
/// 7. Replace the values below with your credentials
/// 
/// SECURITY NOTE: 
/// - Never commit real credentials to version control
/// - Use environment variables or secure storage in production
/// - This file is for development/testing only

class EmailConfig {
  // Replace these with your actual Gmail credentials
  static const String senderEmail = 'louzensaifeddin@gmail.com';
  static const String senderPassword = 'gqxj bpyu xjrt xjli'; // App password, not regular password
  
  // SMTP Configuration
  static const String smtpHost = 'smtp.gmail.com';
  static const int smtpPort = 587;
  
  // Email sender details
  static const String senderName = 'Quiz App';
  
  // Alternative SMTP providers (uncomment to use):
  
  // Outlook/Hotmail:
  // static const String smtpHost = 'smtp-mail.outlook.com';
  // static const int smtpPort = 587;
  
  // Yahoo:
  // static const String smtpHost = 'smtp.mail.yahoo.com';
  // static const int smtpPort = 587;
  
  // Custom SMTP:
  // static const String smtpHost = 'your-smtp-server.com';
  // static const int smtpPort = 587;
}
