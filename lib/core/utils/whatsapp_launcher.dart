import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a WhatsApp chat with a customer.
///
/// The sibling of [PhoneDialer]: same "open the other app, never act on the
/// user's behalf" rule, same SnackBar-instead-of-exception contract so a row
/// tap can never blow up the list.
///
/// Uses `wa.me` rather than the `whatsapp://` scheme. Both open the app when
/// it is installed, but the https link degrades to the browser's "get
/// WhatsApp" page when it is not, instead of failing with
/// ActivityNotFoundException.
class WhatsAppLauncher {
  const WhatsAppLauncher._();

  static final RegExp _nonDigits = RegExp(r'[^0-9]');

  /// The country code assumed for the 10-digit numbers the CRM stores.
  ///
  /// `wa.me` requires a full international number and silently opens an empty
  /// chat without one, which looks like the button did nothing.
  static const String defaultCountryCode = '91';

  /// Turns a stored number into the digits-only international form `wa.me`
  /// expects, or null when there is nothing dialable in it.
  ///
  /// Handles the three shapes the CRM has: `98765 43210`, `+91 98765 43210`
  /// and `0098765...`. A number that already carries a country code is left
  /// alone — only bare 10-digit numbers get [defaultCountryCode].
  static String? normalise(String rawNumber, {String? countryCode}) {
    String digits = rawNumber.replaceAll(_nonDigits, '');
    if (digits.isEmpty) {
      return null;
    }
    // `00` is the other way of writing a leading `+`.
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }
    if (digits.length == 10) {
      digits = '${countryCode ?? defaultCountryCode}$digits';
    }
    return digits;
  }

  /// The `wa.me` link for an already-normalised [number].
  ///
  /// An empty query map would still put a bare `?` on the end of the URL, so
  /// the no-message case passes null instead.
  static Uri chatUri(String number, {String? message}) => Uri.https(
    'wa.me',
    '/$number',
    message == null || message.isEmpty
        ? null
        : <String, String>{'text': message},
  );

  /// Opens a chat with [rawNumber], optionally pre-filling [message].
  static Future<void> openChat(
    BuildContext context,
    String rawNumber, {
    String? message,
  }) async {
    // Captured before the first await so the async gap never touches a
    // possibly-unmounted context.
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    final String? number = normalise(rawNumber);

    if (number == null) {
      _notify(messenger, 'No mobile number saved for this contact.');
      return;
    }

    final Uri uri = chatUri(number, message: message);

    bool launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      // Nothing on the device handles the link — emulators without WhatsApp
      // or a browser. Reported below rather than thrown.
      launched = false;
    }

    if (!launched) {
      _notify(messenger, 'Could not open WhatsApp for $rawNumber.');
    }
  }

  static void _notify(ScaffoldMessengerState? messenger, String message) {
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
