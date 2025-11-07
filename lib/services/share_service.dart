import 'package:share_plus/share_plus.dart';
import '../models/event_model.dart'; // Make sure this path is correct for your project

class ShareService {
  /// Shares event details using the native sharing dialog.
  static Future<void> shareEvent(Event event) async {
    // 1. Craft the message text to be shared.
    final String textToShare = """
Check out this amazing event on the E-Learning Platform!

🗓️ *Event:* ${event.title}
*Date:* ${event.formattedDate} at ${event.eventTime}
*Location:* ${event.location}

Find out more and join here: [Your App Link]
""";
    // Note: Replace "[Your App Link]" with a real link to your app in the App/Play Store later.

    // 2. Use the Share.share method to invoke the native dialog.
    try {
      await Share.share(
        textToShare,
        subject: 'Check out this event: ${event.title}', // 'subject' is used by email apps
      );
    } catch (e) {
      print('Error sharing event: $e');
    }
  }
}
