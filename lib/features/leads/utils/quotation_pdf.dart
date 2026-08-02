import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../domain/entities/lead.dart';

/// Renders a lead's quotation as a PDF and hands it to WhatsApp.
///
/// The document is built from the quotation passed in at tap time rather than
/// from anything cached, so what goes out is always the latest saved detail.
///
/// Money is written as `Rs.` and not `₹`: the PDF's built-in Helvetica has no
/// rupee glyph, and an unembedded one comes out blank on the reader's phone.
/// Embedding a font would mean shipping a TTF for a two-character gain. The
/// same rule is why a blank cell here is `-` rather than the `—` the app's own
/// screens use.
class QuotationPdf {
  const QuotationPdf._();

  static final NumberFormat _amount = NumberFormat.decimalPattern('en_IN');
  static final DateFormat _date = DateFormat('dd MMM yyyy');

  /// Everything that goes into the share sheet's file name.
  static final RegExp _unsafeFileChars = RegExp(r'[^A-Za-z0-9._-]');

  /// Builds the document bytes. Separated from [share] so a preview screen or
  /// a test can render the same PDF without touching the file system.
  static Future<Uint8List> build({
    required String customerName,
    required String mobile,
    required LeadQuotation quotation,
    DateTime? generatedAt,
  }) async {
    final pw.Document document = pw.Document(
      title: 'Quotation — $customerName',
      author: 'NIMMYS CRM',
    );
    final DateTime issuedOn = generatedAt ?? DateTime.now();

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            _header(issuedOn),
            pw.SizedBox(height: 24),
            _customerBlock(customerName, mobile, quotation.customerAddress),
            pw.SizedBox(height: 24),
            _itemsTable(quotation),
            pw.SizedBox(height: 16),
            _total(quotation),
            pw.Spacer(),
            _footer(),
          ],
        ),
      ),
    );

    return document.save();
  }

  /// Writes the PDF to a temp file and opens the share sheet on it.
  ///
  /// WhatsApp is the intended target and the sheet's first suggestion for a
  /// contact you just messaged, but the platform decides the list — neither
  /// Android nor iOS lets an app push a file straight into another app
  /// without its own native intent plumbing.
  static Future<void> share(
    BuildContext context, {
    required String customerName,
    required String mobile,
    required LeadQuotation quotation,
  }) async {
    // Both captured before the first await: the messenger so a failure can be
    // reported without touching a stale context, the rect because iPad needs
    // an anchor for the share popover.
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    final Rect? origin = _shareOrigin(context);

    if (!quotation.hasContent) {
      _notify(messenger, 'No quotation saved for $customerName.');
      return;
    }

    try {
      final Uint8List bytes = await build(
        customerName: customerName,
        mobile: mobile,
        quotation: quotation,
      );
      final Directory directory = await getTemporaryDirectory();
      final File file = File('${directory.path}/${_fileName(customerName)}');
      await file.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[
            XFile(
              file.path,
              mimeType: 'application/pdf',
              name: _fileName(customerName),
            ),
          ],
          text: 'Hi $customerName, please find your quotation attached.',
          subject: 'Quotation from NIMMYS',
          sharePositionOrigin: origin,
        ),
      );
    } on Object {
      // Rendering, disk and the platform channel can all fail here. None of
      // them should take the follow-up list down with them.
      _notify(messenger, 'Could not prepare the quotation PDF.');
    }
  }

  /// The share sheet's file name. The customer name is user data going
  /// straight into a path, so anything outside `[A-Za-z0-9._-]` — separators
  /// included — is replaced before it gets there.
  static String _fileName(String customerName) {
    final String safe = customerName.trim().replaceAll(_unsafeFileChars, '_');
    return 'Quotation_${safe.isEmpty ? 'Customer' : safe}.pdf';
  }

  @visibleForTesting
  static String debugFileName(String customerName) => _fileName(customerName);

  static Rect? _shareOrigin(BuildContext context) {
    final RenderObject? box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      return null;
    }
    return box.localToGlobal(Offset.zero) & box.size;
  }

  static void _notify(ScaffoldMessengerState? messenger, String message) {
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ------------------------------------------------------------ PDF sections

  static pw.Widget _header(DateTime issuedOn) => pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: <pw.Widget>[
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            'NIMMYS',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: _red,
              letterSpacing: 1.5,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Quotation',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
        ],
      ),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: <pw.Widget>[
          pw.Text(
            'Date',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            _date.format(issuedOn),
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    ],
  );

  static pw.Widget _customerBlock(
    String name,
    String mobile,
    String? address,
  ) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          'QUOTATION FOR',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          name,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        if (mobile.trim().isNotEmpty) ...<pw.Widget>[
          pw.SizedBox(height: 2),
          pw.Text(mobile, style: const pw.TextStyle(fontSize: 10)),
        ],
        if (address != null && address.trim().isNotEmpty) ...<pw.Widget>[
          pw.SizedBox(height: 6),
          pw.Text(
            address.trim(),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
          ),
        ],
      ],
    ),
  );

  static pw.Widget _itemsTable(LeadQuotation quotation) {
    final List<QuotationItem> items = quotation.filledItems;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const <int, pw.TableColumnWidth>{
        0: pw.FlexColumnWidth(4),
        1: pw.FlexColumnWidth(1.4),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
      },
      children: <pw.TableRow>[
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: <pw.Widget>[
            _cell('ITEM / PRODUCT', isHeader: true),
            _cell('QTY', isHeader: true, align: pw.TextAlign.center),
            _cell('RATE', isHeader: true, align: pw.TextAlign.right),
            _cell('AMOUNT', isHeader: true, align: pw.TextAlign.right),
          ],
        ),
        for (final QuotationItem item in items)
          pw.TableRow(
            children: <pw.Widget>[
              _cell(item.item ?? '-'),
              _cell(
                item.quantity?.toString() ?? '-',
                align: pw.TextAlign.center,
              ),
              _cell(_money(item.rate), align: pw.TextAlign.right),
              _cell(_money(item.amount), align: pw.TextAlign.right),
            ],
          ),
        // A quotation with an address but no lines still prints a table, so
        // the reader sees an empty one rather than a missing section.
        if (items.isEmpty)
          pw.TableRow(
            children: <pw.Widget>[
              _cell('-'),
              _cell('-', align: pw.TextAlign.center),
              _cell('-', align: pw.TextAlign.right),
              _cell('-', align: pw.TextAlign.right),
            ],
          ),
      ],
    );
  }

  static pw.Widget _total(LeadQuotation quotation) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.end,
    children: <pw.Widget>[
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: pw.BoxDecoration(
          color: _red,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: <pw.Widget>[
            pw.Text(
              'TOTAL',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Text(
              _money(quotation.total),
              style: pw.TextStyle(
                fontSize: 13,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  static pw.Widget _footer() => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.Divider(color: PdfColors.grey300),
      pw.SizedBox(height: 4),
      pw.Text(
        'This quotation is indicative and valid for 15 days from the date '
        'above. Taxes extra as applicable.',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    ],
  );

  static pw.Widget _cell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(
        fontSize: isHeader ? 8.5 : 10.5,
        fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: isHeader ? PdfColors.grey700 : PdfColors.black,
      ),
    ),
  );

  static String _money(double? value) {
    if (value == null) {
      return '-';
    }
    final bool whole = value == value.roundToDouble();
    return 'Rs. ${whole ? _amount.format(value) : value.toStringAsFixed(2)}';
  }

  static const PdfColor _red = PdfColor.fromInt(0xFFE62B1E);
}
