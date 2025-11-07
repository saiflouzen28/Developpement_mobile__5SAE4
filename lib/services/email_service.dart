import 'package:elearning_events_app/models/user_model.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../models/event_model.dart';

class EmailService {
  // Using the credentials you provided
  static const String _username = 'tbuilderscompro@gmail.com';
  static const String _password = 'xogm nkma dzgf yowz'; // Your Google App Password

  static final SmtpServer _smtpServer = gmail(_username, _password);

  static Future<void> sendConfirmationEmail({
    required User user,
    required Event event,
  }) async {
    try {
      final message = Message()
        ..from = Address(_username, 'E-Learning Events Platform')
        ..recipients.add(user.email)
        ..subject = '✅ Registration Confirmed: ${event.title}'
        ..html = _buildEmailHtml(
          recipientName: user.prenom,
          eventTitle: event.title,
          eventDate: event.formattedDate,
          eventTime: event.eventTime,
          eventLocation: event.location,
        );

      await send(message, _smtpServer);
      print('--- EMAIL SERVICE: Confirmation email sent successfully to ${user.email}');

    } catch (e) {
      print('--- EMAIL SERVICE: Error sending email: $e');
      // We catch the error so the app doesn't crash if the email fails.
    }
  }

  // This function builds a simple HTML email body.
  static String _buildEmailHtml({
    required String recipientName,
    required String eventTitle,
    required String eventDate,
    required String eventTime,
    required String eventLocation,
  }) {
    return '''
      <!DOCTYPE html>
      <html>
      <head>
          <style>
              body { font-family: 'Segoe UI', sans-serif; color: #333; }
              .container { max-width: 600px; margin: auto; padding: 20px; border: 1px solid #ddd; border-radius: 10px; }
              .header { background-color: #6366F1; color: white; padding: 20px; text-align: center; border-radius: 10px 10px 0 0; }
              h1 { margin: 0; }
              ul { list-style-type: none; padding: 0; }
              li { background-color: #f8f9fa; margin-bottom: 10px; padding: 10px; border-left: 4px solid #6366F1; }
          </style>
      </head>
      <body>
          <div class="container">
              <div class="header"><h1>🎉 Registration Confirmed!</h1></div>
              <div style="padding: 20px;">
                  <p>Hi <strong>$recipientName</strong>,</p>
                  <p>You have successfully registered for the event: <strong>$eventTitle</strong>.</p>
                  <h3>Event Details:</h3>
                  <ul>
                      <li><strong>Date:</strong> $eventDate</li>
                      <li><strong>Time:</strong> $eventTime</li>
                      <li><strong>Location:</strong> $eventLocation</li>
                  </ul>
                  <p>We look forward to seeing you there!</p>
                  <p><em>- The E-Learning Events Team</em></p>
              </div>
          </div>
      </body>
      </html>
    ''';
  }
}
