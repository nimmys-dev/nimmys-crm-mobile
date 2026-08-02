import '../../../../core/utils/json.dart';
import '../../domain/entities/lead.dart';

/// [Lead] plus the knowledge of how the API spells it.
///
/// Extends the entity rather than holding one and mapping across. A
/// `LeadModel` *is* a `Lead`, so a repository can hand its list straight to
/// the domain with no per-item conversion, while the entity itself stays free
/// of any serialization concern.
///
/// Split this into a standalone class with an explicit `toEntity()` when the
/// API shape and the domain shape genuinely diverge — a response spread
/// across three nested objects, say. Until then the extra layer is
/// indirection without a payoff.
class LeadModel extends Lead {
  const LeadModel({
    required super.id,
    required super.name,
    required super.mobile,
    required super.status,
    required super.createdAt,
    super.email,
    super.source,
    super.quotation,
    super.requiredItems,
    super.nextFollowUpAt,
    super.assignedToId,
    super.assignedToName,
    super.createdByName,
    super.notes,
  });

  /// Reads one lead from an API object.
  ///
  /// Written against the defensive readers in `core/utils/json.dart`, so an
  /// id that arrives as a number, a missing timestamp or an unrecognised
  /// status degrade into sensible values instead of throwing. Only genuinely
  /// unusable input reaches the `ParseException` path.
  factory LeadModel.fromJson(Map<String, dynamic> json) {
    // Assignee and creator arrive either as a nested object or as flat
    // `*_name` fields depending on whether the endpoint expands relations.
    final Map<String, dynamic>? assignee =
        json.mapOrNull('assigned_to') ?? json.mapOrNull('assignee');
    final Map<String, dynamic>? creator = json.mapOrNull('created_by');

    // An absent quotation and one that came back empty mean the same thing to
    // the details screen: no quotation section.
    final Map<String, dynamic>? quotation = json.mapOrNull('quotation');
    final LeadQuotation? parsedQuotation = quotation == null
        ? null
        : LeadQuotation.fromJson(quotation);

    return LeadModel(
      id: json.stringOr('id'),
      name: json.stringOr('name'),
      mobile: json.stringOr('mobile', json.stringOr('phone')),
      status: LeadStatus.fromWire(json.stringOrNull('status')),
      createdAt: json.dateOrNull('created_at') ?? DateTime.now(),
      email: json.stringOrNull('email'),
      source: LeadSource.fromWire(
        json.stringOrNull('source') ?? json.stringOrNull('lead_source'),
      ),
      quotation: (parsedQuotation?.hasContent ?? false) ? parsedQuotation : null,
      requiredItems:
          json.stringOrNull('required_items') ?? json.stringOrNull('requirement'),
      nextFollowUpAt:
          json.dateOrNull('next_follow_up_at') ??
          json.dateOrNull('next_follow_up'),
      assignedToId:
          assignee?.stringOrNull('id') ?? json.stringOrNull('assigned_to_id'),
      assignedToName:
          assignee?.stringOrNull('name') ?? json.stringOrNull('assigned_to_name'),
      createdByName:
          creator?.stringOrNull('name') ?? json.stringOrNull('created_by_name'),
      notes: json.stringOrNull('notes'),
    );
  }
}
