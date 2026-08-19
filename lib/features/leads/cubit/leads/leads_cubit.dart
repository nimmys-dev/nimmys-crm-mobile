import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:nimmys_crm/core/reset_cubit_state.dart';
import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/ui_state/ui_state.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/features/leads/model/lead_assignee_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_details_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_list_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_source_model.dart'; // NEW
import 'package:nimmys_crm/features/leads/model/quotation_pdf_model.dart';
import 'package:nimmys_crm/features/leads/repository/lead_repository.dart';

part 'leads_state.dart';

class LeadsCubit extends BaseCubit<LeadsState> {
  final LeadRepository _repository;
  LeadsCubit(this._repository) : super(const LeadsState());

  static const int _pageSize = 10;

  // -------------------------------------------------------------------------
  // Leads List (getLeads, refresh, goToPage, etc.)
  // -------------------------------------------------------------------------

  Future<void> getLeads({bool refresh = false, String? search}) async {
    await _fetchLeadsPage(page: 1, search: search, skipIfCached: !refresh);
  }

  Future<void> refreshLeads() async {
    await _fetchLeadsPage(
      page: state.leadPagination?.currentPage ?? 1,
      skipIfCached: false,
    );
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
      emit(
        state.copyWith(
          leadListUIState: UIState.success(result.value),
          leadList: result.value.data,
          leadPagination: result.value.pagination,
        ),
      );
    } else if (result is Error<LeadListResponse>) {
      emit(state.copyWith(leadListUIState: UIState.error(result.type)));
    }
  }

  // -------------------------------------------------------------------------
  // Lead Assignees
  // -------------------------------------------------------------------------

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

  // -------------------------------------------------------------------------
  // Lead Sources (NEW)
  // -------------------------------------------------------------------------

  void _setLeadSourcesUIState(UIState<LeadSourceModel>? uiState) {
    emit(state.copyWith(leadSourcesUIState: uiState));
  }

  /// Fetches lead sources from the repository.
  /// If [force] is false and data already exists, it returns without a network call.
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

  /// Resets lead sources state to initial (null). Useful when logging out.
  void resetLeadSourcesState() {
    _setLeadSourcesUIState(
      resetUIState<LeadSourceModel>(state.leadSourcesUIState),
    );
  }

  // -------------------------------------------------------------------------
  // Create Lead
  // -------------------------------------------------------------------------

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

  // -------------------------------------------------------------------------
  // Lead Details
  // -------------------------------------------------------------------------

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

  // -------------------------------------------------------------------------
  // Update Lead
  // -------------------------------------------------------------------------

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

  // -------------------------------------------------------------------------
  // Quotation PDF (NEW)
  // -------------------------------------------------------------------------

  void _setQuotationPdfUIState(UIState<QuotationPdfResponse>? uiState) {
    emit(state.copyWith(quotationPdfUIState: uiState));
  }

  /// Fetches the quotation PDF for a specific lead.
  /// Always makes a network call (no caching) because each call is for a different lead.
  Future<void> getQuotationPdf(int leadId) async {
    // Optionally, you could prevent duplicate requests if the same leadId is already loading.
    // For simplicity, we just call every time.
    _setQuotationPdfUIState(UIState.loading());
    final Result<QuotationPdfResponse> result = await _repository
        .getQuotationPdf(leadId);
    if (result is Success<QuotationPdfResponse>) {
      _setQuotationPdfUIState(UIState.success(result.value));
    } else if (result is Error<QuotationPdfResponse>) {
      _setQuotationPdfUIState(UIState.error(result.type));
    }
  }

  /// Resets the quotation PDF state (e.g., on navigation away or logout).
  void resetQuotationPdfState() {
    _setQuotationPdfUIState(
      resetUIState<QuotationPdfResponse>(state.quotationPdfUIState),
    );
  }

  // -------------------------------------------------------------------------
  // Reset entire state (used on sign-out)
  // -------------------------------------------------------------------------

  void resetLeadsState() {
    emit(const LeadsState());
  }
}
