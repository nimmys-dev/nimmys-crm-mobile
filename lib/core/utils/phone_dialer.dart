import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the platform dialer for a customer's number.
///
/// The app only *opens* the dialer with the number filled in; it never places
/// the call itself. That needs no runtime permission on either platform, which
/// is why there is no permission handling here.
class PhoneDialer {
  const PhoneDialer._();

  /// Everything a `tel:` URI is allowed to contain. Numbers arrive from the
  /// CRM with spaces, dashes and brackets in them, and Android's dialer
  /// rejects the URI rather than cleaning it up.
  static final RegExp _disallowed = RegExp(r'[^0-9+*#,;]');

  /// Strips formatting from [rawNumber], leaving dialable characters only.
  static String normalise(String rawNumber) =>
      rawNumber.replaceAll(_disallowed, '');

  /// Launches the dialer for [rawNumber], telling the user when it can't.
  ///
  /// Safe to call from an `onTap`: failures surface as a SnackBar instead of
  /// an unhandled exception.
  static Future<void> call(BuildContext context, String rawNumber) async {
    // Captured before the first await so the async gap never touches a
    // possibly-unmounted context.
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    final String number = normalise(rawNumber);

    if (number.isEmpty) {
      _notify(messenger, 'No phone number saved for this contact.');
      return;
    }

    bool launched = false;
    try {
      launched = await launchUrl(
        Uri(scheme: 'tel', path: number),
        mode: LaunchMode.externalApplication,
      );
    } on PlatformException {
      // No dialer installed — emulators and most tablets. Fall through to the
      // message below rather than crashing the row.
      launched = false;
    }

    if (!launched) {
      _notify(messenger, 'Could not open the dialer for $number.');
    }
  }

  static void _notify(ScaffoldMessengerState? messenger, String message) {
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
