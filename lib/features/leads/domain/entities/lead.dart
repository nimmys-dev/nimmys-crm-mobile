import 'package:equatable/equatable.dart';

/// Where a lead sits in the pipeline.
///
/// An enum rather than a raw string so a typo is a compile error and a
/// `switch` on status is checked for completeness. [wireValue] is the only
/// place the server's spelling appears.
enum LeadStatus {
  fresh('new', 'New'),
  contacted('contacted', 'Contacted'),
  qualified('qualified', 'Qualified'),
  negotiating('negotiating', 'Negotiating'),
  won('won', 'Won'),
  lost('lost', 'Lost');

  const LeadStatus(this.wireValue, this.label);

  /// What the API sends and expects.
  final String wireValue;

  /// What the user reads.
  final String label;

  /// Maps an API string to a status, defaulting to [fresh] for anything
  /// unrecognised — a new status added server-side should not crash the app.
  static LeadStatus fromWire(String? value) {
    if (value == null) {
      return LeadStatus.fresh;
    }
    final String normalised = value.toLowerCase().trim();
    for (final LeadStatus status in LeadStatus.values) {
      if (status.wireValue == normalised) {
        return status;
      }
    }
    return LeadStatus.fresh;
  }

  bool get isClosed => this == LeadStatus.won || this == LeadStatus.lost;
}

/// Where the enquiry came from.
///
/// Same shape as [LeadStatus]: an enum so the capture screen, the payload and
/// any later reporting all agree on the spelling, with [wireValue] the single
/// place the server's version lives.
enum LeadSource {
  website('website', 'Website'),
  instagram('instagram', 'Instagram'),
  whatsapp('whatsapp', 'WhatsApp'),
  call('call', 'Call'),
  facebook('facebook', 'Facebook'),
  other('other', 'Other');

  const LeadSource(this.wireValue, this.label);

  /// What the API sends and expects.
  final String wireValue;

  /// What the user reads.
  final String label;

  /// Maps an API string to a source, returning null for anything missing or
  /// unrecognised — an unknown source is shown as blank rather than silently
  /// reported as one of the known channels.
  static LeadSource? fromWire(String? value) {
    if (value == null) {
      return null;
    }
    final String normalised = value.toLowerCase().trim();
    for (final LeadSource source in LeadSource.values) {
      if (source.wireValue == normalised) {
        return source;
      }
    }
    return null;
  }

  /// Matches on the display label too, so a picker built from [label] can be
  /// read back without the screen holding its own lookup table.
  static LeadSource? fromLabel(String? value) {
    if (value == null) {
      return null;
    }
    final String normalised = value.toLowerCase().trim();
    for (final LeadSource source in LeadSource.values) {
      if (source.label.toLowerCase() == normalised) {
        return source;
      }
    }
    return null;
  }

  /// The picker options, in declaration order.
  static List<String> get labels =>
      LeadSource.values.map((LeadSource source) => source.label).toList();
}

/// One line of a quotation — a product, how many, and at what rate.
///
/// Every field is nullable because the capture screen adds an empty row the
/// moment the user taps "Add Item"; a row they then leave blank is dropped on
/// save rather than stored as a phantom line.
class QuotationItem extends Equatable {
  const QuotationItem({this.item, this.quantity, this.rate});

  factory QuotationItem.fromJson(Map<String, dynamic> json) => QuotationItem(
    item: _text(json['item'] ?? json['product'] ?? json['name']),
    quantity: _int(json['quantity'] ?? json['qty']),
    rate: _double(json['rate'] ?? json['price']),
  );

  final String? item;
  final int? quantity;
  final double? rate;

  /// True when anything at all was typed into the row.
  bool get hasContent =>
      (item?.trim().isNotEmpty ?? false) || quantity != null || rate != null;

  /// Quantity × rate, or null when either half is missing — a line may carry
  /// only a product name.
  double? get amount =>
      quantity == null || rate == null ? null : quantity! * rate!;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (item != null && item!.trim().isNotEmpty) 'item': item!.trim(),
    if (quantity != null) 'quantity': quantity,
    if (rate != null) 'rate': rate,
  };

  @override
  List<Object?> get props => <Object?>[item, quantity, rate];
}

/// The optional quotation captured alongside a lead.
///
/// Holds an address and any number of [items]. The capture screen attaches
/// one only when something was actually entered, which is what [hasContent]
/// decides.
class LeadQuotation extends Equatable {
  const LeadQuotation({
    this.customerAddress,
    this.items = const <QuotationItem>[],
  });

  /// Reads a quotation from an API object, tolerating numbers that arrive as
  /// strings — the same defensiveness the rest of the parsing layer uses.
  ///
  /// Also accepts the single-line shape this used to have (a flat `item`,
  /// `quantity` and `rate` on the quotation itself), so quotations saved
  /// before the list existed still load.
  factory LeadQuotation.fromJson(Map<String, dynamic> json) {
    final Object? rawItems = json['items'];
    final List<QuotationItem> items = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(QuotationItem.fromJson)
              .where((QuotationItem item) => item.hasContent)
              .toList()
        : <QuotationItem>[];

    if (items.isEmpty) {
      final QuotationItem legacy = QuotationItem.fromJson(json);
      if (legacy.hasContent) {
        items.add(legacy);
      }
    }

    return LeadQuotation(
      customerAddress: _text(json['customer_address'] ?? json['address']),
      items: items,
    );
  }

  final String? customerAddress;

  /// The quoted lines, in the order the user entered them.
  final List<QuotationItem> items;

  /// The lines worth saving or showing — blank rows the user added and never
  /// filled in are not part of the quotation.
  List<QuotationItem> get filledItems =>
      items.where((QuotationItem item) => item.hasContent).toList();

  /// True when at least one field was filled in. A quotation with nothing in
  /// it is not saved, and never renders a section on the details screen.
  bool get hasContent =>
      (customerAddress?.trim().isNotEmpty ?? false) || filledItems.isNotEmpty;

  /// The sum of every line that has both a quantity and a rate, or null when
  /// no line does.
  double? get total {
    double? sum;
    for (final QuotationItem item in filledItems) {
      final double? amount = item.amount;
      if (amount != null) {
        sum = (sum ?? 0) + amount;
      }
    }
    return sum;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (customerAddress != null && customerAddress!.trim().isNotEmpty)
      'customer_address': customerAddress!.trim(),
    'items': filledItems
        .map((QuotationItem item) => item.toJson())
        .toList(growable: false),
  };

  @override
  List<Object?> get props => <Object?>[customerAddress, items];
}

String? _text(Object? value) {
  if (value == null) {
    return null;
  }
  final String text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _int(Object? value) => switch (value) {
  final num number => number.toInt(),
  final String text => int.tryParse(text.trim()),
  _ => null,
};

double? _double(Object? value) => switch (value) {
  final num number => number.toDouble(),
  final String text => double.tryParse(text.trim()),
  _ => null,
};

/// A sales lead, as the app understands it.
///
/// Pure domain: no JSON, no Dio, no Flutter. That is what lets the blocs and
/// use cases be tested with plain constructors and no mocking of a transport.
/// Serialization lives in `LeadModel` one layer out.
class Lead extends Equatable {
  const Lead({
    required this.id,
    required this.name,
    required this.mobile,
    required this.status,
    required this.createdAt,
    this.email,
    this.source,
    this.quotation,
    this.requiredItems,
    this.nextFollowUpAt,
    this.assignedToId,
    this.assignedToName,
    this.createdByName,
    this.notes,
  });

  final String id;
  final String name;
  final String mobile;
  final LeadStatus status;
  final DateTime createdAt;

  final String? email;

  /// The channel the enquiry arrived through. Null for leads captured before
  /// the field existed, or when the server does not send it.
  final String? source;

  /// Set only when a quotation was captured with the lead. Null is what the
  /// details screen reads to know there is no quotation section to show.
  final LeadQuotation? quotation;

  /// What the customer is asking about — the "Required Items" row on the
  /// details screen.
  final String? requiredItems;

  final DateTime? nextFollowUpAt;

  final String? assignedToId;
  final String? assignedToName;
  final String? createdByName;
  final String? notes;

  /// True when the follow-up is due today or overdue — the thing the
  /// follow-up screen sorts and colours by.
  bool isFollowUpDue({DateTime? now}) {
    final DateTime? due = nextFollowUpAt;
    if (due == null) {
      return false;
    }
    final DateTime today = now ?? DateTime.now();
    return !due.isAfter(
      DateTime(today.year, today.month, today.day, 23, 59, 59),
    );
  }

  Lead copyWith({
    String? name,
    String? mobile,
    LeadStatus? status,
    String? email,
    String? source,
    LeadQuotation? quotation,
    String? requiredItems,
    DateTime? nextFollowUpAt,
    String? assignedToId,
    String? assignedToName,
    String? notes,
  }) => Lead(
    id: id,
    name: name ?? this.name,
    mobile: mobile ?? this.mobile,
    status: status ?? this.status,
    createdAt: createdAt,
    email: email ?? this.email,
    source: source ?? this.source,
    quotation: quotation ?? this.quotation,
    requiredItems: requiredItems ?? this.requiredItems,
    nextFollowUpAt: nextFollowUpAt ?? this.nextFollowUpAt,
    assignedToId: assignedToId ?? this.assignedToId,
    assignedToName: assignedToName ?? this.assignedToName,
    createdByName: createdByName,
    notes: notes ?? this.notes,
  );

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    mobile,
    status,
    createdAt,
    email,
    source,
    quotation,
    requiredItems,
    nextFollowUpAt,
    assignedToId,
    assignedToName,
    createdByName,
    notes,
  ];
}

/// The fields a create or update actually sends.
///
/// Separate from [Lead] because a write is not a read: there is no id yet, no
/// `createdAt`, and no server-derived display names. Posting a whole entity
/// back would send fields the server ignores at best and rejects at worst.
class LeadDraft extends Equatable {
  const LeadDraft({
    required this.name,
    required this.mobile,
    this.email,
    this.status = LeadStatus.fresh,
    this.source,
    this.quotation,
    this.requiredItems,
    this.nextFollowUpAt,
    this.assignedToId,
    this.notes,
  });

  /// Pre-fills a draft from an existing lead, for the edit screen.
  factory LeadDraft.from(Lead lead) => LeadDraft(
    name: lead.name,
    mobile: lead.mobile,
    email: lead.email,
    status: lead.status,
    source: lead.source,
    quotation: lead.quotation,
    requiredItems: lead.requiredItems,
    nextFollowUpAt: lead.nextFollowUpAt,
    assignedToId: lead.assignedToId,
    notes: lead.notes,
  );

  final String name;
  final String mobile;
  final String? email;
  final LeadStatus status;
  final String? source;

  /// Sent only when the capture screen's quotation toggle was on and at
  /// least one quotation field was filled in.
  final LeadQuotation? quotation;

  final String? requiredItems;
  final DateTime? nextFollowUpAt;
  final String? assignedToId;
  final String? notes;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name.trim(),
    'mobile': mobile.trim(),
    'status': status.wireValue,
    if (email != null && email!.trim().isNotEmpty) 'email': email!.trim(),
    if (source != null) 'source': source,
    if (quotation != null && quotation!.hasContent)
      'quotation': quotation!.toJson(),
    if (requiredItems != null) 'required_items': requiredItems,
    if (nextFollowUpAt != null)
      'next_follow_up_at': nextFollowUpAt!.toUtc().toIso8601String(),
    if (assignedToId != null) 'assigned_to_id': assignedToId,
    if (notes != null) 'notes': notes,
  };

  @override
  List<Object?> get props => <Object?>[
    name,
    mobile,
    email,
    status,
    source,
    quotation,
    requiredItems,
    nextFollowUpAt,
    assignedToId,
    notes,
  ];
}
