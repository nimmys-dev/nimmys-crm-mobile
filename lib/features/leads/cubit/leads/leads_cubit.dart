import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nimmys_crm/core/reset_cubit_state.dart';
import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/ui_state/ui_state.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/features/leads/model/call_history_list_model.dart';
import 'package:nimmys_crm/features/leads/model/call_log_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_assignee_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_details_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_list_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_source_model.dart';
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

  Future<void> getLeads({bool refresh = false, String? search}) async {
    await _fetchLeadsPage(page: 1, search: search, skipIfCached: !refresh);
  }

  Future<void> refreshLeads() async {
    await _fetchLeadsPage(page: 1, skipIfCached: false);
  }

  Future<void> goToLeadsPage(int page) async {
    if (page < 1 || page == state.leadPagination?.currentPage) {
      return;
    }

    await _fetchLeadsPage(page: page, skipIfCached: false);
  }

  Future<void> _fetchLeadsPage({
    required int page,
    String? search,
    bool skipIfCached = false,
  }) async {
    if (state.leadListUIState?.status == Status.LOADING) {
      return;
    }

    final String query = (search ?? state.leadSearchQuery).trim();

    final bool searchChanged = query != state.leadSearchQuery;

    if (!searchChanged &&
        skipIfCached &&
        state.leadList.isNotEmpty &&
        page == (state.leadPagination?.currentPage ?? 1)) {
      return;
    }

    emit(
      state.copyWith(
        leadListUIState: UIState.loading(),
        leadSearchQuery: query,
        leadList: searchChanged ? <LeadItemData>[] : state.leadList,
      ),
    );

    final Result<LeadListResponse> result = await _repository.getLeads(
      page: page,
      perPage: _pageSize,
      search: query,
    );

    if (result is Success<LeadListResponse>) {
      final bool searchChanged =
          query !=
          state
              .leadSearchQuery; // but query already computed before loading; need keep? Actually query computed local before await. We can use query variable. But searchChanged also computed before await; could use final bool searchChanged from earlier. But state.leadSearchQuery may have changed? We computed before. Use `final bool isFirstPage = page == 1; final bool shouldReplace = isFirstPage || searchChanged;`
      final List<LeadItemData> newItems = result.value.data;
      final bool shouldReplace = page == 1 || searchChanged;
      final bool isFirstPage = page == 1;

      final List<LeadItemData> updatedLeads = shouldReplace
          ? newItems
          : [...state.leadList, ...newItems];

      emit(
        state.copyWith(
          leadListUIState: UIState.success(result.value),
          leadList: updatedLeads,
          leadPagination: result.value.pagination,
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

      unawaited(getLeads(refresh: true));
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

      unawaited(getLeads(refresh: true));
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

      // Refresh the lead details after successfully
      // adding the call log so the newly-created call
      // is available when the details are displayed.
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
  // Reset Entire State
  // ---------------------------------------------------------------------------

  void resetLeadsState() {
    emit(const LeadsState());
  }
}
