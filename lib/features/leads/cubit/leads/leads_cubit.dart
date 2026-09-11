import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:nimmys_crm/core/reset_cubit_state.dart';
import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/ui_state/ui_state.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/features/leads/model/call_history_list_model.dart';
import 'package:nimmys_crm/features/leads/model/call_log_model.dart';
import 'package:nimmys_crm/features/leads/model/closed_lead_response.dart';
import 'package:nimmys_crm/features/leads/model/lead_assignee_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_details_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_list_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_source_model.dart';
import 'package:nimmys_crm/features/leads/model/not_interested_reason_model.dart';
import 'package:nimmys_crm/features/leads/model/quotation_pdf_model.dart';
import 'package:nimmys_crm/features/leads/repository/lead_repository.dart';

part 'leads_state.dart';

class LeadsCubit extends BaseCubit<LeadsState> {
  final LeadRepository _repository;

  LeadsCubit(this._repository) : super(const LeadsState());

  static const int _pageSize = 10;

  // ---------------------------------------------------------------------------
  // Leads List
  // ---------------------------------------------------------------------------

  Future<void> getLeads({
    bool refresh = false,
    String? search,
    String? status,
    required int isUniversalLeadList,
  }) async {
    emit(
      state.copyWith(
        currentLeadStatus: status,
        isUniversalLeadList: isUniversalLeadList,
      ),
    );
    await _fetchLeadsPage(
      page: 1,
      search: search,
      skipIfCached: !refresh,
      status: status,
    );
  }

  Future<void> refreshLeads() async {
    final status = state.currentLeadStatus ?? '';
    await _fetchLeadsPage(page: 1, skipIfCached: false, status: status);
  }

  Future<void> goToLeadsPage(int page) async {
    if (page < 1 || page == state.leadPagination?.currentPage) {
      return;
    }
    final status = state.currentLeadStatus ?? '';
    await _fetchLeadsPage(page: page, skipIfCached: false, status: status);
  }

  Future<void> _fetchLeadsPage({
    required int page,
    String? search,
    bool skipIfCached = false,
    String? status,
  }) async {
    if (state.leadListUIState?.status == Status.LOADING) {
      return;
    }

    final String query = (search ?? state.leadSearchQuery).trim();

    final bool searchChanged = query != state.leadSearchQuery;
    final bool statusChanged = status != state.lastFetchedStatus;

    // Only skip if status hasn't changed, search hasn't changed, and we're allowed to cache.
    if (!searchChanged &&
        !statusChanged &&
        skipIfCached &&
        state.leadList.isNotEmpty &&
        page == (state.leadPagination?.currentPage ?? 1)) {
      return;
    }

    // Always clear the list + pagination when starting a fresh page-1 fetch
    // so the user never sees stale data while the new request is in flight.
    final bool shouldClear = page == 1 || searchChanged || statusChanged;

    emit(
      state.copyWith(
        leadListUIState: UIState.loading(),
        leadSearchQuery: query,
        leadList: shouldClear ? <LeadItemData>[] : state.leadList,
        leadPagination: shouldClear ? null : state.leadPagination,
      ),
    );

    // Use the stored isUniversalLeadList from state
    final Result<LeadListResponse> result = await _repository.getLeads(
      page: page,
      perPage: _pageSize,
      search: query,
      status: status,
      isUniversalLeadList: state.isUniversalLeadList,
    );

    if (result is Success<LeadListResponse>) {
      final bool shouldReplace = page == 1 || searchChanged || statusChanged;
      final List<LeadItemData> newItems = result.value.data;
      final List<LeadItemData> updatedLeads = shouldReplace
          ? newItems
          : [...state.leadList, ...newItems];

      emit(
        state.copyWith(
          leadListUIState: UIState.success(result.value),
          leadList: updatedLeads,
          leadPagination: result.value.pagination,
          lastFetchedStatus: status,
        ),
      );
    } else if (result is Error<LeadListResponse>) {
      emit(state.copyWith(leadListUIState: UIState.error(result.type)));
    }
  }
  // ---------------------------------------------------------------------------
  // Lead Assignees
  // ---------------------------------------------------------------------------

  void _setLeadAssigneesUIState(UIState<LeadAssigneeSuccess>? uiState) {
    emit(state.copyWith(leadAssigneesUIState: uiState));
  }

  Future<void> getLeadAssignees({bool force = false}) async {
    if (!force && state.leadAssigneesUIState?.data != null) {
      return;
    }

    _setLeadAssigneesUIState(UIState.loading());

    final Result<LeadAssigneeSuccess> result = await _repository
        .getLeadAssignees();

    if (result is Success<LeadAssigneeSuccess>) {
      _setLeadAssigneesUIState(UIState.success(result.value));
    } else if (result is Error<LeadAssigneeSuccess>) {
      _setLeadAssigneesUIState(UIState.error(result.type));
    }
  }

  // ---------------------------------------------------------------------------
  // Lead Sources
  // ---------------------------------------------------------------------------

  void _setLeadSourcesUIState(UIState<LeadSourceModel>? uiState) {
    emit(state.copyWith(leadSourcesUIState: uiState));
  }

  Future<void> getLeadSources({bool force = false}) async {
    if (!force && state.leadSourcesUIState?.data != null) {
      return;
    }

    _setLeadSourcesUIState(UIState.loading());

    final Result<LeadSourceModel> result = await _repository.getLeadSources();

    if (result is Success<LeadSourceModel>) {
      _setLeadSourcesUIState(UIState.success(result.value));
    } else if (result is Error<LeadSourceModel>) {
      _setLeadSourcesUIState(UIState.error(result.type));
    }
  }

  void resetLeadSourcesState() {
    _setLeadSourcesUIState(
      resetUIState<LeadSourceModel>(state.leadSourcesUIState),
    );
  }

  // ---------------------------------------------------------------------------
  // Create Lead
  // ---------------------------------------------------------------------------

  void _setCreateLeadUIState(UIState<dynamic>? uiState) {
    emit(state.copyWith(createLeadUIState: uiState));
  }

  Future<void> createLead(Map<String, dynamic> payload) async {
    if (state.createLeadUIState?.status == Status.LOADING) {
      return;
    }

    _setCreateLeadUIState(UIState.loading());

    final Result<dynamic> result = await _repository.createLead(payload);

    if (result is Success<dynamic>) {
      _setCreateLeadUIState(UIState.success(result.value));

      // Refresh with the current status and the stored universal flag
      final status = state.currentLeadStatus ?? '';
      final isUniversalLeadList = state.isUniversalLeadList;
      unawaited(
        getLeads(
          refresh: true,
          status: status,
          isUniversalLeadList: isUniversalLeadList,
        ),
      );
    } else if (result is Error<dynamic>) {
      _setCreateLeadUIState(UIState.error(result.type));
    }
  }

  void resetCreateLeadState() {
    _setCreateLeadUIState(resetUIState<dynamic>(state.createLeadUIState));
  }

  // ---------------------------------------------------------------------------
  // Lead Details
  // ---------------------------------------------------------------------------

  void _setLeadDetailsUIState(UIState<LeadDetailsSuccess>? uiState) {
    emit(state.copyWith(leadDetailsUIState: uiState));
  }

  Future<void> getLeadDetails(int id) async {
    _setLeadDetailsUIState(UIState.loading());

    final Result<LeadDetailsSuccess> result = await _repository.getLeadDetails(
      id,
    );

    if (result is Success<LeadDetailsSuccess>) {
      _setLeadDetailsUIState(UIState.success(result.value));
    } else if (result is Error<LeadDetailsSuccess>) {
      _setLeadDetailsUIState(UIState.error(result.type));
    }
  }

  void resetLeadDetailsState() {
    _setLeadDetailsUIState(
      resetUIState<LeadDetailsSuccess>(state.leadDetailsUIState),
    );
  }

  // ---------------------------------------------------------------------------
  // Update Lead
  // ---------------------------------------------------------------------------

  void _setUpdateLeadUIState(UIState<LeadDetailsSuccess>? uiState) {
    emit(state.copyWith(updateLeadUIState: uiState));
  }

  Future<void> updateLead(int id, Map<String, dynamic> payload) async {
    if (state.updateLeadUIState?.status == Status.LOADING) {
      return;
    }

    _setUpdateLeadUIState(UIState.loading());

    final Result<LeadDetailsSuccess> result = await _repository.updateLead(
      id,
      payload,
    );

    if (result is Success<LeadDetailsSuccess>) {
      _setUpdateLeadUIState(UIState.success(result.value));

      if (result.value.data != null) {
        _setLeadDetailsUIState(UIState.success(result.value));
      }

      final status = state.currentLeadStatus ?? '';
      unawaited(
        getLeads(
          refresh: true,
          status: status,
          isUniversalLeadList: state.isUniversalLeadList,
        ),
      );
    } else if (result is Error<LeadDetailsSuccess>) {
      _setUpdateLeadUIState(UIState.error(result.type));
    }
  }

  void resetUpdateLeadState() {
    _setUpdateLeadUIState(
      resetUIState<LeadDetailsSuccess>(state.updateLeadUIState),
    );
  }

  // ---------------------------------------------------------------------------
  // Quotation PDF
  // ---------------------------------------------------------------------------

  void _setQuotationPdfUIState(UIState<QuotationPdfResponse>? uiState) {
    emit(state.copyWith(quotationPdfUIState: uiState));
  }

  Future<void> getQuotationPdf(int leadId) async {
    _setQuotationPdfUIState(UIState.loading());

    final Result<QuotationPdfResponse> result = await _repository
        .getQuotationPdf(leadId);

    if (result is Success<QuotationPdfResponse>) {
      _setQuotationPdfUIState(UIState.success(result.value));
    } else if (result is Error<QuotationPdfResponse>) {
      _setQuotationPdfUIState(UIState.error(result.type));
    }
  }

  void resetQuotationPdfState() {
    _setQuotationPdfUIState(
      resetUIState<QuotationPdfResponse>(state.quotationPdfUIState),
    );
  }

  // ---------------------------------------------------------------------------
  // Add Call Log
  // ---------------------------------------------------------------------------

  void _setAddCallLogUIState(UIState<TeleCallDetailResponseModel>? uiState) {
    emit(state.copyWith(addCallLogUIState: uiState));
  }

  /// Creates a call log for the given lead.
  ///
  /// All fields except [leadId] are optional.
  /// Empty/null values are not sent to the API.
  Future<void> addCallLog({
    required int leadId,
    String? callStatus,
    String? calledDate,
    String? calledTime,
    String? duration,
    bool? interest,
    String? reason,
    bool? isItemSold,
    String? invoiceNumber,
    String? remarks,
    String? nextFollowupDate,
    File? invoiceFile,
  }) async {
    if (state.addCallLogUIState?.status == Status.LOADING) {
      return;
    }

    _setAddCallLogUIState(UIState.loading());

    final Result<TeleCallDetailResponseModel> result = await _repository
        .addCallLog(
          leadId: leadId,
          callStatus: callStatus,
          calledDate: calledDate,
          calledTime: calledTime,
          duration: duration,
          interest: interest,
          reason: reason,
          isItemSold: isItemSold,
          invoiceNumber: invoiceNumber,
          remarks: remarks,
          nextFollowupDate: nextFollowupDate,
          invoiceFile: invoiceFile,
        );

    if (result is Success<TeleCallDetailResponseModel>) {
      _setAddCallLogUIState(UIState.success(result.value));

      // Refresh the lead details after successfully adding the call log
      unawaited(getLeadDetails(leadId));
    } else if (result is Error<TeleCallDetailResponseModel>) {
      _setAddCallLogUIState(UIState.error(result.type));
    }
  }

  void resetAddCallLogState() {
    _setAddCallLogUIState(
      resetUIState<TeleCallDetailResponseModel>(state.addCallLogUIState),
    );
  }

  // ---------------------------------------------------------------------------
  // Get Call History
  // ---------------------------------------------------------------------------

  void _setCallHistoryUIState(UIState<CallHistoryResponseListModel>? uiState) {
    emit(state.copyWith(callHistoryUIState: uiState));
  }

  Future<void> getCallHistory(
    int leadId, {
    int page = 1,
    int perPage = 10,
  }) async {
    _setCallHistoryUIState(UIState.loading());

    final Result<CallHistoryResponseListModel> result = await _repository
        .getCallHistory(leadId, page: page, perPage: perPage);

    if (result is Success<CallHistoryResponseListModel>) {
      _setCallHistoryUIState(UIState.success(result.value));
    } else if (result is Error<CallHistoryResponseListModel>) {
      _setCallHistoryUIState(UIState.error(result.type));
    }
  }

  void resetCallHistoryState() {
    _setCallHistoryUIState(
      resetUIState<CallHistoryResponseListModel>(state.callHistoryUIState),
    );
  }

  // ---------------------------------------------------------------------------
  // Close Lead
  // ---------------------------------------------------------------------------

  void _setCloseLeadUIState(UIState<CloseLeadResponse>? uiState) {
    emit(state.copyWith(closeLeadUIState: uiState));
  }

  /// Closes a lead with the given status and optional lost reason.
  Future<void> closeLead({
    required int leadId,
    required String status,
    String? lostReason,
  }) async {
    if (state.closeLeadUIState?.status == Status.LOADING) {
      return;
    }

    _setCloseLeadUIState(UIState.loading());

    final result = await _repository.closeLead(
      leadId: leadId,
      status: status,
      lostReason: lostReason,
    );

    if (result is Success<CloseLeadResponse>) {
      _setCloseLeadUIState(UIState.success(result.value));
      // Refresh the lead details and the list after closing
      unawaited(getLeadDetails(leadId));
      final currentStatus = state.currentLeadStatus ?? '';
      unawaited(
        getLeads(
          refresh: true,
          status: currentStatus,
          isUniversalLeadList: state.isUniversalLeadList,
        ),
      );
    } else if (result is Error<CloseLeadResponse>) {
      _setCloseLeadUIState(UIState.error(result.type));
    }
  }

  void resetCloseLeadState() {
    _setCloseLeadUIState(
      resetUIState<CloseLeadResponse>(state.closeLeadUIState),
    );
  }

  // ---------------------------------------------------------------------------
  // Not Interested Reasons
  // ---------------------------------------------------------------------------

  void _setNotInterestedReasonsUIState(
    UIState<NotInterestedReasonModel>? uiState,
  ) {
    emit(state.copyWith(notInterestedReasonsUIState: uiState));
  }

  Future<void> getNotInterestedReasons({bool force = false}) async {
    if (!force && state.notInterestedReasonsUIState?.data != null) {
      return;
    }

    _setNotInterestedReasonsUIState(UIState.loading());

    final Result<NotInterestedReasonModel> result = await _repository
        .getNotInterestedReasons();

    if (result is Success<NotInterestedReasonModel>) {
      _setNotInterestedReasonsUIState(UIState.success(result.value));
    } else if (result is Error<NotInterestedReasonModel>) {
      _setNotInterestedReasonsUIState(UIState.error(result.type));
    }
  }

  void resetNotInterestedReasonsState() {
    _setNotInterestedReasonsUIState(
      resetUIState<NotInterestedReasonModel>(state.notInterestedReasonsUIState),
    );
  }

  // ---------------------------------------------------------------------------
  // Reset Entire State
  // ---------------------------------------------------------------------------

  void resetLeadsState() {
    emit(const LeadsState());
  }
}
