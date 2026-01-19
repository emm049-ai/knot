import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'linkedin_service.dart';

class ShareHandler {
  // Handle incoming share intents (Android/iOS)
  static Future<void> handleIncomingShare() async {
    try {
      // Get shared text from platform channel
      const platform = MethodChannel('knot.app/share');
      final String? sharedText = await platform.invokeMethod('getSharedText');

      if (sharedText != null && sharedText.contains('linkedin.com')) {
        await LinkedInService.handleShareIntent(sharedText);
      }
    } catch (e) {
      print('Error handling share: $e');
      // Share handler not implemented on this platform
    }
  }

  // Share contact (for sharing contact info)
  static Future<void> shareContact({
    required String name,
    String? email,
    String? phone,
    String? company,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln(name);
    if (company != null) buffer.writeln(company);
    if (email != null) buffer.writeln('Email: $email');
    if (phone != null) buffer.writeln('Phone: $phone');

    await Share.share(buffer.toString(), subject: 'Contact: $name');
  }
}
