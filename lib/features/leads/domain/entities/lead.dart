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
    return !due.isAfter(DateTime(today.year, today.month, today.day, 23, 59, 59));
  }

  Lead copyWith({
    String? name,
    String? mobile,
    LeadStatus? status,
    String? email,
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
    requiredItems: lead.requiredItems,
    nextFollowUpAt: lead.nextFollowUpAt,
    assignedToId: lead.assignedToId,
    notes: lead.notes,
  );

  final String name;
  final String mobile;
  final String? email;
  final LeadStatus status;
  final String? requiredItems;
  final DateTime? nextFollowUpAt;
  final String? assignedToId;
  final String? notes;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name.trim(),
    'mobile': mobile.trim(),
    'status': status.wireValue,
    if (email != null && email!.trim().isNotEmpty) 'email': email!.trim(),
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
    requiredItems,
    nextFollowUpAt,
    assignedToId,
    notes,
  ];
}
