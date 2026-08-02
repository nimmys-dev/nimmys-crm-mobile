import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nimmys_crm/features/leads/domain/entities/lead.dart';
import 'package:nimmys_crm/features/leads/utils/quotation_pdf.dart';

/// The share path needs a device, but the document itself is pure Dart — so
/// the part that can silently produce a broken attachment is testable here.
void main() {
  test('renders a PDF for a complete quotation', () async {
    final Uint8List bytes = await QuotationPdf.build(
      customerName: 'Sejun',
      mobile: '9961210000',
      quotation: const LeadQuotation(
        customerAddress: 'Marine Drive, Kochi, Ernakulam 682031',
        items: <QuotationItem>[
          QuotationItem(item: 'Sigma 85mm 1:4 Lens', quantity: 2, rate: 74500),
          QuotationItem(item: 'Lens Cleaning Kit', quantity: 3, rate: 1250),
        ],
      ),
      generatedAt: DateTime(2026, 5, 12),
    );

    expect(bytes, isNotEmpty);
    // Every PDF starts with the %PDF- magic number.
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('renders a partly filled quotation without throwing', () async {
    final Uint8List bytes = await QuotationPdf.build(
      customerName: 'Abin',
      mobile: '8086140010',
      quotation: const LeadQuotation(
        items: <QuotationItem>[QuotationItem(item: 'Sony Camera')],
      ),
      generatedAt: DateTime(2026, 5, 12),
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test(
    'a name with path characters cannot escape the temp directory',
    () async {
      // Guards the file name built for the share sheet: the customer name is
      // user data and goes straight into a path.
      final Uint8List bytes = await QuotationPdf.build(
        customerName: '../../etc/passwd',
        mobile: '9961210000',
        quotation: const LeadQuotation(
          items: <QuotationItem>[
            QuotationItem(item: 'Lens', quantity: 1, rate: 100),
          ],
        ),
      );
      expect(bytes, isNotEmpty);
      expect(
        QuotationPdf.debugFileName('../../etc/passwd'),
        'Quotation_.._.._etc_passwd.pdf',
      );
      expect(QuotationPdf.debugFileName('   '), 'Quotation_Customer.pdf');
    },
  );
}
