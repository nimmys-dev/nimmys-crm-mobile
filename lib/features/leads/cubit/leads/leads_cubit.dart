import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:nimmys_crm/core/reset_cubit_state.dart';
import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/ui_state/ui_state.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/features/leads/model/lead_assignee_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_details_model.dart';
import 'package:nimmys_crm/features/leads/model/lead_list_model.dart';
import 'package:nimmys_crm/features/leads/repository/lead_repository.dart';
part 'leads_state.dart';

class LeadsCubit extends BaseCubit<LeadsState> {
  final LeadRepository _repository;
  LeadsCubit(this._repository) : super(const LeadsState());

  static const int _pageSize = 10;

  // Leads List Api Call
  //
  // Each request replaces the visible page rather than appending. Prev/Next
  // on the list screen asks for a specific page; the rows live in state
  // because the response only ever carries that one page.
  Future<void> getLeads({bool refresh = false, String? search}) async {
    await _fetchLeadsPage(
      page: 1,
      search: search,
      skipIfCached: !refresh,
    );
  }

  /// Reloads whichever page is currently on screen.
  Future<void> refreshLeads() async {
    await _fetchLeadsPage(
      page: state.leadPagination?.currentPage ?? 1,
      skipIfCached: false,
    );
  }

  /// Fetches [page] and replaces the list. Same loading/error handling as
  /// page 1 — the cubit is what keeps Prev/Next working, not the screen.
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
        // Results for a previous search must never remain visible while the
        // new server-side search is in flight.
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
    }
    if (result is Error<LeadListResponse>) {
      emit(state.copyWith(leadListUIState: UIState.error(result.type)));
    }
  }

  // Lead Assignees Api Call
  void _setLeadAssigneesUIState(UIState<LeadAssigneeSuccess>? uiState) {
    emit(state.copyWith(leadAssigneesUIState: uiState));
  }

  /// [force] re-fetches even when assignees are already loaded. New Lead calls
  /// this on every mount, so without the guard the picker would blank out and
  /// refill each time the screen is opened.
  Future<void> getLeadAssignees({bool force = false}) async {
    if (!force && state.leadAssigneesUIState?.data != null) {
      return;
    }
    _setLeadAssigneesUIState(UIState.loading());
    Result result = await _repository.getLeadAssignees();
    if (result is Success<LeadAssigneeSuccess>) {
      _setLeadAssigneesUIState(UIState.success(result.value));
    }
    if (result is Error) {
      _setLeadAssigneesUIState(UIState.error(result.type));
    }
  }

  // Create Lead Api Call
  void _setCreateLeadUIState(UIState<dynamic>? uiState) {
    emit(state.copyWith(createLeadUIState: uiState));
  }

  Future<void> createLead(Map<String, dynamic> payload) async {
    if (state.createLeadUIState?.status == Status.LOADING) {
      return;
    }
    _setCreateLeadUIState(UIState.loading());
    Result result = await _repository.createLead(payload);
    if (result is Success<dynamic>) {
      _setCreateLeadUIState(UIState.success(result.value));
      unawaited(getLeads(refresh: true));
    }
    if (result is Error) {
      _setCreateLeadUIState(UIState.error(result.type));
    }
  }

  void resetCreateLeadState() {
    _setCreateLeadUIState(resetUIState<dynamic>(state.createLeadUIState));
  }

  // View Lead Api Call
  void _setLeadDetailsUIState(UIState<LeadDetailsSuccess>? uiState) {
    emit(state.copyWith(leadDetailsUIState: uiState));
  }

  /// Always fetches fresh — no "already loaded" guard. This is a per-record
  /// view: the id changes between visits, and a guard keyed only on "is
  /// something loaded" would show a previously viewed lead while a different
  /// one's request is in flight.
  Future<void> getLeadDetails(int id) async {
    _setLeadDetailsUIState(UIState.loading());
    Result result = await _repository.getLeadDetails(id);
    if (result is Success<LeadDetailsSuccess>) {
      _setLeadDetailsUIState(UIState.success(result.value));
    }
    if (result is Error) {
      _setLeadDetailsUIState(UIState.error(result.type));
    }
  }

  void resetLeadDetailsState() {
    _setLeadDetailsUIState(
      resetUIState<LeadDetailsSuccess>(state.leadDetailsUIState),
    );
  }

  // Update Lead Api Call
  void _setUpdateLeadUIState(UIState<LeadDetailsSuccess>? uiState) {
    emit(state.copyWith(updateLeadUIState: uiState));
  }

  Future<void> updateLead(int id, Map<String, dynamic> payload) async {
    if (state.updateLeadUIState?.status == Status.LOADING) {
      return;
    }
    _setUpdateLeadUIState(UIState.loading());
    Result result = await _repository.updateLead(id, payload);
    if (result is Success<LeadDetailsSuccess>) {
      _setUpdateLeadUIState(UIState.success(result.value));
      if (result.value.data != null) {
        _setLeadDetailsUIState(UIState.success(result.value));
      }
      unawaited(getLeads(refresh: true));
    }
    if (result is Error) {
      _setUpdateLeadUIState(UIState.error(result.type));
    }
  }

  void resetUpdateLeadState() {
    _setUpdateLeadUIState(
      resetUIState<LeadDetailsSuccess>(state.updateLeadUIState),
    );
  }

  /// Called on sign-out. The cubit is a singleton, so without this the next
  /// account to sign in would see the previous user's leads.
  void resetLeadsState() {
    emit(const LeadsState());
  }
}
