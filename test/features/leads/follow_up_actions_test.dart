import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../oldLib/core/theme/app_theme.dart';
import '../../../oldLib/features/leads/domain/entities/lead.dart';
import '../../../oldLib/features/leads/widgets/follow_up_table.dart';

/// The row's action cluster: WhatsApp and Call always, the quotation PDF only
/// for a lead that has one.
void main() {
  const FollowUpEntry withQuotation = FollowUpEntry(
    name: 'Sejun',
    mobile: '9961210000',
    requiredItems: 'Sigma 85mm Lens.',
    nextFollowUp: '12-05-2024',
    quotation: LeadQuotation(
      customerAddress: 'Marine Drive, Kochi',
      items: <QuotationItem>[
        QuotationItem(item: 'Sigma 85mm 1:4 Lens', quantity: 2, rate: 74500),
      ],
    ),
  );

  const FollowUpEntry withoutQuotation = FollowUpEntry(
    name: 'Abin',
    mobile: '8086140010',
    requiredItems: 'Sony Camera.',
    nextFollowUp: '12-05-2024',
  );

  Future<void> pumpTable(
    WidgetTester tester,
    List<FollowUpEntry> entries,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(child: FollowUpTable(entries: entries)),
        ),
      ),
    );
  }

  testWidgets('every row offers WhatsApp and Call', (
    WidgetTester tester,
  ) async {
    await pumpTable(tester, <FollowUpEntry>[withQuotation, withoutQuotation]);

    expect(find.byIcon(FontAwesomeIcons.whatsapp.data), findsNWidgets(2));
    expect(find.byIcon(Icons.call_rounded), findsNWidgets(2));
  });

  testWidgets('only a lead with a quotation gets the PDF action', (
    WidgetTester tester,
  ) async {
    await pumpTable(tester, <FollowUpEntry>[withQuotation, withoutQuotation]);

    expect(find.byIcon(Icons.picture_as_pdf_rounded), findsOneWidget);
    // The share mark rides on the same button.
    expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    expect(find.byType(FollowUpActionBadge), findsOneWidget);
  });

  testWidgets('an empty quotation counts as no quotation', (
    WidgetTester tester,
  ) async {
    await pumpTable(tester, <FollowUpEntry>[
      const FollowUpEntry(
        name: 'Madhu',
        mobile: '8081616161',
        requiredItems: 'Mac Mini',
        nextFollowUp: '12-05-2024',
        quotation: LeadQuotation(),
      ),
    ]);

    expect(find.byIcon(Icons.picture_as_pdf_rounded), findsNothing);
    expect(find.byIcon(FontAwesomeIcons.whatsapp.data), findsOneWidget);
  });
}
