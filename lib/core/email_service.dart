import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'email_config.dart';

class EmailService {
  // SMTP Configuration from config file
  static const String _username = EmailConfig.senderEmail;
  static const String _password = EmailConfig.senderPassword;
  
  /// Send quiz result email
  /// 
  /// To use Gmail SMTP:
  /// 1. Go to Google Account settings
  /// 2. Enable 2-Step Verification
  /// 3. Generate an "App Password" for Mail
  /// 4. Use that app password in _password above
  static Future<bool> sendQuizResultEmail({
    required String recipientEmail,
    required String userName,
    required String quizTitle,
    required int score,
    required int totalQuestions,
    required double percentage,
  }) async {
    try {
      // Configure Gmail SMTP server
      final smtpServer = gmail(_username, _password);
      
      // Alternative SMTP servers:
      // final smtpServer = SmtpServer('smtp.gmail.com',
      //   port: 587,
      //   username: _username,
      //   password: _password,
      // );

      // Determine result status
      String status;
      String statusEmoji;
      String statusColor;
      
      if (percentage >= 80) {
        status = 'Excellent';
        statusEmoji = '🎉';
        statusColor = '#10B981';
      } else if (percentage >= 50) {
        status = 'Bien';
        statusEmoji = '👏';
        statusColor = '#F59E0B';
      } else {
        status = 'À améliorer';
        statusEmoji = '💪';
        statusColor = '#EF4444';
      }

      // Create email message with HTML formatting
      final message = Message()
        ..from = Address(_username, EmailConfig.senderName)
        ..recipients.add(recipientEmail)
        ..subject = '📊 Résultats du Quiz: $quizTitle'
        ..html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background-color: #f3f4f6;
      margin: 0;
      padding: 20px;
    }
    .container {
      max-width: 600px;
      margin: 0 auto;
      background-color: white;
      border-radius: 16px;
      box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
      overflow: hidden;
    }
    .header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      padding: 40px 20px;
      text-align: center;
      color: white;
    }
    .header h1 {
      margin: 0;
      font-size: 28px;
      font-weight: bold;
    }
    .header p {
      margin: 10px 0 0 0;
      opacity: 0.9;
    }
    .content {
      padding: 30px;
    }
    .result-card {
      background-color: #f9fafb;
      border-left: 4px solid $statusColor;
      padding: 20px;
      border-radius: 8px;
      margin: 20px 0;
    }
    .result-title {
      font-size: 18px;
      font-weight: bold;
      color: #1f2937;
      margin-bottom: 15px;
    }
    .stats {
      display: flex;
      justify-content: space-around;
      margin: 20px 0;
      text-align: center;
    }
    .stat-box {
      flex: 1;
      padding: 15px;
    }
    .stat-value {
      font-size: 32px;
      font-weight: bold;
      color: $statusColor;
    }
    .stat-label {
      font-size: 14px;
      color: #6b7280;
      margin-top: 5px;
    }
    .footer {
      text-align: center;
      padding: 20px;
      background-color: #f9fafb;
      color: #6b7280;
      font-size: 14px;
    }
    .button {
      display: inline-block;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 12px 30px;
      border-radius: 8px;
      text-decoration: none;
      font-weight: bold;
      margin-top: 20px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>$statusEmoji Quiz Terminé!</h1>
      <p>Résultats de: $userName</p>
    </div>
    
    <div class="content">
      <h2 style="color: #1f2937;">📝 $quizTitle</h2>
      
      <div class="stats">
        <div class="stat-box">
          <div class="stat-value">$score</div>
          <div class="stat-label">Bonnes réponses</div>
        </div>
        <div class="stat-box">
          <div class="stat-value">$totalQuestions</div>
          <div class="stat-label">Questions totales</div>
        </div>
        <div class="stat-box">
          <div class="stat-value">${percentage.toStringAsFixed(1)}%</div>
          <div class="stat-label">Score</div>
        </div>
      </div>
      
      <div class="result-card">
        <div class="result-title">🎯 Résultat: $status $statusEmoji</div>
        <p style="color: #4b5563; margin: 0;">
          ${percentage >= 80 
            ? 'Excellent travail ! Vous maîtrisez parfaitement ce sujet.' 
            : percentage >= 50 
              ? 'Bon travail ! Continuez à vous améliorer.'
              : 'Continuez à apprendre et réessayez !'}
        </p>
      </div>
      
      <div style="text-align: center; margin-top: 30px;">
        <p style="color: #6b7280; font-size: 14px;">
          Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}
        </p>
      </div>
    </div>
    
    <div class="footer">
      <p>Cet email a été généré automatiquement par Quiz App</p>
      <p style="margin-top: 10px;">Continuez à apprendre et à progresser ! 📚</p>
    </div>
  </div>
</body>
</html>
''';

      // Send the email
      final sendReport = await send(message, smtpServer);
      print('Email sent successfully: ${sendReport.toString()}');
      return true;
      
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }
}
