part of 'leads_cubit.dart';

class LeadsState extends Equatable {
  /// Status of the *current page request*. The rows themselves live in
  /// [leadList] because the response only ever carries one page.
  final UIState<LeadListResponse>? leadListUIState;

  /// The page currently on screen.
  final List<LeadItemData> leadList;
  final LeadPagination? leadPagination;
  final String leadSearchQuery;

  /// Staff who can be assigned a lead, from `GET /api/lead-assignees`.
  final UIState<LeadAssigneeSuccess>? leadAssigneesUIState;

  /// Available lead sources, from `GET /api/lead-sources`.
  final UIState<LeadSourceModel>? leadSourcesUIState; // NEW

  /// `POST /api/create-leads`'s own terminal state, kept separate from
  /// [updateLeadUIState] so a create in flight cannot be mistaken for an update.
  final UIState<dynamic>? createLeadUIState;

  /// The record behind `GET /api/view-lead/{id}` — Lead Details reads this.
  final UIState<LeadDetailsSuccess>? leadDetailsUIState;

  /// `POST /api/update-lead/{id}`'s own terminal state, kept separate from
  /// the details fetch so a save in flight cannot be mistaken for a reload.
  final UIState<LeadDetailsSuccess>? updateLeadUIState;

  const LeadsState({
    this.leadListUIState,
    this.leadList = const <LeadItemData>[],
    this.leadPagination,
    this.leadSearchQuery = '',
    this.leadAssigneesUIState,
    this.leadSourcesUIState, // NEW
    this.createLeadUIState,
    this.leadDetailsUIState,
    this.updateLeadUIState,
  });

  LeadsState copyWith({
    UIState<LeadListResponse>? leadListUIState,
    List<LeadItemData>? leadList,
    LeadPagination? leadPagination,
    String? leadSearchQuery,
    UIState<LeadAssigneeSuccess>? leadAssigneesUIState,
    UIState<LeadSourceModel>? leadSourcesUIState, // NEW
    UIState<dynamic>? createLeadUIState,
    UIState<LeadDetailsSuccess>? leadDetailsUIState,
    UIState<LeadDetailsSuccess>? updateLeadUIState,
  }) {
    return LeadsState(
      leadListUIState: leadListUIState ?? this.leadListUIState,
      leadList: leadList ?? this.leadList,
      leadPagination: leadPagination ?? this.leadPagination,
      leadSearchQuery: leadSearchQuery ?? this.leadSearchQuery,
      leadAssigneesUIState: leadAssigneesUIState ?? this.leadAssigneesUIState,
      leadSourcesUIState: leadSourcesUIState ?? this.leadSourcesUIState, // NEW
      createLeadUIState: createLeadUIState ?? this.createLeadUIState,
      leadDetailsUIState: leadDetailsUIState ?? this.leadDetailsUIState,
      updateLeadUIState: updateLeadUIState ?? this.updateLeadUIState,
    );
  }

  @override
  List<Object?> get props => [
        leadListUIState,
        leadListUIState?.status,
        leadListUIState?.data,
        leadListUIState?.errorType,
        leadList,
        leadPagination,
        leadSearchQuery,
        leadAssigneesUIState,
        leadAssigneesUIState?.status,
        leadAssigneesUIState?.data,
        leadAssigneesUIState?.errorType,
        leadSourcesUIState, // NEW
        leadSourcesUIState?.status,
        leadSourcesUIState?.data,
        leadSourcesUIState?.errorType,
        createLeadUIState,
        createLeadUIState?.status,
        createLeadUIState?.data,
        createLeadUIState?.errorType,
        leadDetailsUIState,
        leadDetailsUIState?.status,
        leadDetailsUIState?.data,
        leadDetailsUIState?.errorType,
        updateLeadUIState,
        updateLeadUIState?.status,
        updateLeadUIState?.data,
        updateLeadUIState?.errorType,
      ];
}