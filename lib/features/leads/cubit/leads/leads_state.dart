part of 'leads_cubit.dart';

class LeadsState extends Equatable {
  // ---------------------------------------------------------------------------
  // Leads List
  // ---------------------------------------------------------------------------

  /// Status of the current leads page request.
  final UIState<LeadListResponse>? leadListUIState;

  /// Current page rows.
  final List<LeadItemData> leadList;

  /// Pagination information.
  final LeadPagination? leadPagination;

  /// Current search query.
  final String leadSearchQuery;

  // ---------------------------------------------------------------------------
  // Lead Assignees
  // ---------------------------------------------------------------------------

  /// Staff who can be assigned a lead.
  final UIState<LeadAssigneeSuccess>? leadAssigneesUIState;

  // ---------------------------------------------------------------------------
  // Lead Sources
  // ---------------------------------------------------------------------------

  /// Available lead sources.
  final UIState<LeadSourceModel>? leadSourcesUIState;

  // ---------------------------------------------------------------------------
  // Create Lead
  // ---------------------------------------------------------------------------

  /// POST /api/create-leads state.
  final UIState<dynamic>? createLeadUIState;

  // ---------------------------------------------------------------------------
  // Lead Details
  // ---------------------------------------------------------------------------

  /// GET /api/view-lead/{id} state.
  final UIState<LeadDetailsSuccess>? leadDetailsUIState;

  // ---------------------------------------------------------------------------
  // Update Lead
  // ---------------------------------------------------------------------------

  /// POST /api/update-lead/{id} state.
  final UIState<LeadDetailsSuccess>? updateLeadUIState;

  // ---------------------------------------------------------------------------
  // Quotation PDF
  // ---------------------------------------------------------------------------

  /// GET /api/quotation-pdf/{leadId} state.
  final UIState<QuotationPdfResponse>? quotationPdfUIState;

  // ---------------------------------------------------------------------------
  // Add Call Log
  // ---------------------------------------------------------------------------

  /// POST /api/leads/{leadId}/calls state.
  final UIState<TeleCallDetailResponseModel>? addCallLogUIState;

  final UIState<CallHistoryResponseListModel>? callHistoryUIState;

  // ---------------------------------------------------------------------------
  // Close Lead
  // ---------------------------------------------------------------------------

  /// PUT /api/leads/{id}/close state.
  final UIState<CloseLeadResponse>? closeLeadUIState;

  final UIState<NotInterestedReasonModel>? notInterestedReasonsUIState;

  const LeadsState({
    this.leadListUIState,
    this.leadList = const <LeadItemData>[],
    this.leadPagination,
    this.leadSearchQuery = '',
    this.leadAssigneesUIState,
    this.leadSourcesUIState,
    this.createLeadUIState,
    this.leadDetailsUIState,
    this.updateLeadUIState,
    this.quotationPdfUIState,
    this.addCallLogUIState,
    this.callHistoryUIState,
    this.closeLeadUIState,
    this.notInterestedReasonsUIState,
  });

  LeadsState copyWith({
    UIState<LeadListResponse>? leadListUIState,
    List<LeadItemData>? leadList,
    LeadPagination? leadPagination,
    String? leadSearchQuery,
    UIState<LeadAssigneeSuccess>? leadAssigneesUIState,
    UIState<LeadSourceModel>? leadSourcesUIState,
    UIState<dynamic>? createLeadUIState,
    UIState<LeadDetailsSuccess>? leadDetailsUIState,
    UIState<LeadDetailsSuccess>? updateLeadUIState,
    UIState<QuotationPdfResponse>? quotationPdfUIState,
    UIState<TeleCallDetailResponseModel>? addCallLogUIState,
    UIState<CallHistoryResponseListModel>? callHistoryUIState,
    UIState<CloseLeadResponse>? closeLeadUIState,
    UIState<NotInterestedReasonModel>? notInterestedReasonsUIState,
  }) {
    return LeadsState(
      leadListUIState: leadListUIState ?? this.leadListUIState,
      leadList: leadList ?? this.leadList,
      leadPagination: leadPagination ?? this.leadPagination,
      leadSearchQuery: leadSearchQuery ?? this.leadSearchQuery,
      leadAssigneesUIState: leadAssigneesUIState ?? this.leadAssigneesUIState,
      leadSourcesUIState: leadSourcesUIState ?? this.leadSourcesUIState,
      createLeadUIState: createLeadUIState ?? this.createLeadUIState,
      leadDetailsUIState: leadDetailsUIState ?? this.leadDetailsUIState,
      updateLeadUIState: updateLeadUIState ?? this.updateLeadUIState,
      quotationPdfUIState: quotationPdfUIState ?? this.quotationPdfUIState,
      addCallLogUIState: addCallLogUIState ?? this.addCallLogUIState,
      callHistoryUIState: callHistoryUIState ?? this.callHistoryUIState,
      closeLeadUIState: closeLeadUIState ?? this.closeLeadUIState,
      notInterestedReasonsUIState:
          notInterestedReasonsUIState ?? this.notInterestedReasonsUIState,
    );
  }

  @override
  List<Object?> get props => [
    // Leads list
    leadListUIState,
    leadListUIState?.status,
    leadListUIState?.data,
    leadListUIState?.errorType,
    leadList,
    leadPagination,
    leadSearchQuery,

    // Assignees
    leadAssigneesUIState,
    leadAssigneesUIState?.status,
    leadAssigneesUIState?.data,
    leadAssigneesUIState?.errorType,

    // Sources
    leadSourcesUIState,
    leadSourcesUIState?.status,
    leadSourcesUIState?.data,
    leadSourcesUIState?.errorType,

    // Create lead
    createLeadUIState,
    createLeadUIState?.status,
    createLeadUIState?.data,
    createLeadUIState?.errorType,

    // Lead details
    leadDetailsUIState,
    leadDetailsUIState?.status,
    leadDetailsUIState?.data,
    leadDetailsUIState?.errorType,

    // Update lead
    updateLeadUIState,
    updateLeadUIState?.status,
    updateLeadUIState?.data,
    updateLeadUIState?.errorType,

    // Quotation PDF
    quotationPdfUIState,
    quotationPdfUIState?.status,
    quotationPdfUIState?.data,
    quotationPdfUIState?.errorType,

    // Add call log
    addCallLogUIState,
    addCallLogUIState?.status,
    addCallLogUIState?.data,
    addCallLogUIState?.errorType,

    // Call history
    callHistoryUIState,
    callHistoryUIState?.status,
    callHistoryUIState?.data,
    callHistoryUIState?.errorType,

    // Close Lead
    closeLeadUIState,
    closeLeadUIState?.status,
    closeLeadUIState?.data,
    closeLeadUIState?.errorType,

    // Not Interested Reasons
    notInterestedReasonsUIState,
    notInterestedReasonsUIState?.status,
    notInterestedReasonsUIState?.data,
    notInterestedReasonsUIState?.errorType,
  ];
}
