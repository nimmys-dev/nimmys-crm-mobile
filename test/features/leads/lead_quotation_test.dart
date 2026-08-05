import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import '../../../oldLib/features/leads/data/models/lead_model.dart';
import '../../../oldLib/features/leads/domain/entities/lead.dart';

/// A quotation now carries a list of lines. These cover what the capture
/// screen relies on: blank rows never reach the payload, and a quotation
/// saved in the old single-line shape still loads.
void main() {
  group('items', () {
    test('blank rows are dropped from what gets saved', () {
      const LeadQuotation quotation = LeadQuotation(
        customerAddress: 'Marine Drive, Kochi',
        items: <QuotationItem>[
          QuotationItem(item: 'Sigma 85mm', quantity: 2, rate: 74500),
          // The row the user added and never filled in.
          QuotationItem(),
          QuotationItem(item: 'Cleaning Kit', quantity: 1, rate: 1250),
        ],
      );

      expect(quotation.filledItems, hasLength(2));
      final List<dynamic> json = quotation.toJson()['items'] as List<dynamic>;
      expect(json, hasLength(2));
      expect((json.first as Map<String, dynamic>)['item'], 'Sigma 85mm');
    });

    test('a quotation of only blank rows has no content', () {
      const LeadQuotation quotation = LeadQuotation(
        items: <QuotationItem>[QuotationItem(), QuotationItem()],
      );
      expect(quotation.hasContent, isFalse);
    });

    test('an address alone is still a quotation', () {
      const LeadQuotation quotation = LeadQuotation(
        customerAddress: 'Kanjikuzhi, Kottayam',
      );
      expect(quotation.hasContent, isTrue);
      expect(quotation.total, isNull);
    });

    test('the total adds up every line that has both figures', () {
      const LeadQuotation quotation = LeadQuotation(
        items: <QuotationItem>[
          QuotationItem(item: 'Sigma 85mm', quantity: 2, rate: 74500),
          QuotationItem(item: 'Cleaning Kit', quantity: 3, rate: 1250),
          // No rate — contributes nothing rather than counting as zero.
          QuotationItem(item: 'Carry Case', quantity: 1),
        ],
      );
      expect(quotation.total, 152750);
    });
  });

  group('parsing', () {
    test('reads a list of items', () {
      final LeadQuotation quotation = LeadQuotation.fromJson(
        jsonDecode('''
        {
          "customer_address": "Marine Drive, Kochi",
          "items": [
            {"item": "Sigma 85mm", "quantity": "2", "rate": "74500.50"},
            {"product": "Cleaning Kit", "qty": 3, "price": 1250}
          ]
        }
        ''')
            as Map<String, dynamic>,
      );

      expect(quotation.customerAddress, 'Marine Drive, Kochi');
      expect(quotation.items, hasLength(2));
      expect(quotation.items.first.quantity, 2);
      expect(quotation.items.first.rate, 74500.50);
      expect(quotation.items.last.item, 'Cleaning Kit');
      expect(quotation.items.last.quantity, 3);
    });

    test('a quotation saved in the old single-line shape still loads', () {
      final LeadQuotation quotation = LeadQuotation.fromJson(<String, dynamic>{
        'customer_address': 'Marine Drive, Kochi',
        'item': 'Sigma 85mm',
        'quantity': 2,
        'rate': 74500,
      });

      expect(quotation.items, hasLength(1));
      expect(quotation.items.single.item, 'Sigma 85mm');
      expect(quotation.total, 149000);
    });

    test('survives a round trip through the draft payload', () {
      const LeadQuotation quotation = LeadQuotation(
        customerAddress: 'Marine Drive, Kochi',
        items: <QuotationItem>[
          QuotationItem(item: 'Sigma 85mm', quantity: 2, rate: 74500),
          QuotationItem(item: 'Cleaning Kit', quantity: 3, rate: 1250),
        ],
      );
      const LeadDraft draft = LeadDraft(
        name: 'Sojan',
        mobile: '9961210000',
        source: LeadSource.instagram,
        quotation: quotation,
      );

      final Map<String, dynamic> body =
          jsonDecode(jsonEncode(draft.toJson())) as Map<String, dynamic>;
      expect(body['source'], 'instagram');

      final Lead lead = LeadModel.fromJson(<String, dynamic>{
        'id': '1',
        'name': 'Sojan',
        'mobile': '9961210000',
        'quotation': body['quotation'],
      });
      expect(lead.quotation, quotation);
    });

    test('an empty quotation object parses as no quotation', () {
      final Lead lead = LeadModel.fromJson(<String, dynamic>{
        'id': '1',
        'name': 'Sojan',
        'mobile': '9961210000',
        'quotation': <String, dynamic>{'items': <dynamic>[]},
      });
      expect(lead.quotation, isNull);
    });
  });
}
