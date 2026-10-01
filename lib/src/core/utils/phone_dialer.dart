import 'dart:developer';

import 'package:url_launcher/url_launcher.dart';

/// Hands a number to the phone app, ready to call: the customer presses call
/// there (the app never dials on its own).
abstract final class PhoneDialer {
  static const String _telScheme = 'tel';
  static const String _logName = 'dialer';

  /// Opens the dialer on [number]; `false` when no app on the phone can.
  static Future<bool> dial(String number) async {
    try {
      return await launchUrl(
        Uri(scheme: _telScheme, path: number),
        mode: LaunchMode.externalApplication,
      );
    } catch (error) {
      log('no dialer: $error', name: _logName);
      return false;
    }
  }
}
