import 'package:flutter_test/flutter_test.dart';
import '../../oldLib/core/utils/whatsapp_launcher.dart';

/// `wa.me` opens an empty chat rather than erroring when the number is not in
/// full international form, so the normalisation is what decides whether the
/// button appears to work at all.
void main() {
  group('normalise', () {
    test('adds the country code to a bare 10-digit number', () {
      expect(WhatsAppLauncher.normalise('9961210000'), '919961210000');
    });

    test('strips the formatting the CRM stores numbers with', () {
      expect(WhatsAppLauncher.normalise('99612 10000'), '919961210000');
      expect(WhatsAppLauncher.normalise('+91 99612-10000'), '919961210000');
      expect(WhatsAppLauncher.normalise('(0091) 9961210000'), '919961210000');
    });

    test('leaves a number that already carries a country code alone', () {
      expect(WhatsAppLauncher.normalise('919961210000'), '919961210000');
      expect(WhatsAppLauncher.normalise('+1 415 555 0132'), '14155550132');
    });

    test('honours an explicit country code', () {
      expect(
        WhatsAppLauncher.normalise('4155550132', countryCode: '1'),
        '14155550132',
      );
    });

    test('returns null when there is nothing dialable', () {
      expect(WhatsAppLauncher.normalise(''), isNull);
      expect(WhatsAppLauncher.normalise('  --  '), isNull);
    });
  });

  group('chatUri', () {
    test('has no stray query when there is no message', () {
      expect(
        WhatsAppLauncher.chatUri('919961210000').toString(),
        'https://wa.me/919961210000',
      );
    });

    test('encodes the prefilled message', () {
      final Uri uri = WhatsAppLauncher.chatUri(
        '919961210000',
        message: 'Hi Sejun, following up on your enquiry for Sigma 85mm Lens.',
      );
      expect(uri.host, 'wa.me');
      expect(uri.path, '/919961210000');
      expect(
        uri.queryParameters['text'],
        'Hi Sejun, following up on your enquiry for Sigma 85mm Lens.',
      );
    });
  });
}
